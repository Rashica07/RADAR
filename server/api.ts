// RADAR API — runs as the Neon Function with slug `radar` (see neon.ts).
//
// Architecture (from the Neon agent skills): a mobile client never talks to Postgres.
//   iOS app ──Bearer JWT──▶ this Function ──pooled node-postgres──▶ Lakebase Postgres
//   iOS app ◀── sealed live query ── this Function ── NEON_REALTIME_SECRET (never leaves here)
//
// - Driver: node-postgres (`pg`) with ONE module-scope pool (Functions are long-running
//   and reuse the isolate), on the injected pooled DATABASE_URL.
// - Auth: Neon Auth (Managed Better Auth) JWTs, EdDSA, verified against NEON_AUTH_JWKS_URL.
//   The user id is ALWAYS the verified `sub`; a request can never name another user.
// - This Function has a public URL: every route except /health authenticates first.

import { attachDatabasePool } from "@neon/functions";
import { createRealtime, rawSql } from "@neon/realtime/server";
import { Hono } from "hono";
import { HTTPException } from "hono/http-exception";
import { createRemoteJWKSet, jwtVerify } from "jose";
import { Pool } from "pg";
// The Realtime SDK loads `ws` with a dynamic import() from inside node_modules, which the
// Function bundler cannot see. A static import here makes sure it ships with the bundle.
import "ws";

// ---------- configuration (injected by Neon at runtime) ----------
const databaseUrl = process.env.DATABASE_URL;
const authBaseUrl = process.env.NEON_AUTH_BASE_URL;
const jwksUrl = process.env.NEON_AUTH_JWKS_URL;
// Passed through the function `env` in neon.ts (NEON_* is reserved, and Realtime vars are not auto-injected).
const realtimeUrl = process.env.RADAR_REALTIME_URL;
const realtimeSecret = process.env.RADAR_REALTIME_SECRET;

const databaseName = databaseUrl ? new URL(databaseUrl).pathname.replace(/^\//, "") || "neondb" : "neondb";
const issuer = authBaseUrl ? new URL(authBaseUrl).origin : undefined;

// ---------- Postgres: one pool per isolate ----------
const pool = databaseUrl ? new Pool({ connectionString: databaseUrl, max: 5 }) : undefined;
if (pool) attachDatabasePool(pool);

function db(): Pool {
  if (!pool) throw new HTTPException(503, { message: "database is not configured" });
  return pool;
}

// ---------- auth ----------
const jwks = jwksUrl ? createRemoteJWKSet(new URL(jwksUrl)) : undefined;

interface AuthedUser {
  id: string;
  email?: string;
}

async function requireUser(authorization: string | undefined): Promise<AuthedUser> {
  if (!jwks || !issuer) throw new HTTPException(503, { message: "auth is not configured" });
  if (!authorization || !/^bearer /i.test(authorization)) {
    throw new HTTPException(401, { message: "missing bearer token" });
  }
  try {
    const { payload } = await jwtVerify(authorization.slice(7).trim(), jwks, {
      issuer,
      audience: issuer,
      algorithms: ["EdDSA"],
    });
    if (!payload.sub) throw new Error("token has no subject");
    return { id: payload.sub, email: typeof payload.email === "string" ? payload.email : undefined };
  } catch {
    // Deliberately uniform: don't tell a caller whether it was expiry, signature or issuer.
    throw new HTTPException(401, { message: "invalid or expired token" });
  }
}

// ---------- realtime ----------
const realtime = realtimeSecret ? createRealtime({ secret: realtimeSecret, db: databaseName }) : undefined;
const directRealtime =
  realtimeSecret && realtimeUrl ? createRealtime({ secret: realtimeSecret, db: databaseName, url: realtimeUrl }) : undefined;

interface SavedRow {
  user_id: string;
  track_id: string;
  saved_at: string;
}

/** Live query for ONE user's saved tracks. `userId` comes only from the verified JWT. */
function savedTracksQuery(userId: string) {
  return rawSql<SavedRow>(
    `SELECT user_id, track_id, saved_at FROM radar_saved_tracks WHERE user_id = $1 ORDER BY saved_at DESC LIMIT 500`,
    [userId],
  );
}

// ---------- validation ----------
const TRACK_ID = /^[a-z0-9][a-z0-9-]{0,79}$/;
function trackIdParam(raw: string | undefined): string {
  if (!raw || !TRACK_ID.test(raw)) throw new HTTPException(400, { message: "invalid track id" });
  return raw;
}

// ---------- app ----------
const app = new Hono();

app.onError((err, c) => {
  if (err instanceof HTTPException) return c.json({ error: err.message }, err.status);
  console.error("unhandled", err instanceof Error ? err.message : err);
  return c.json({ error: "internal error" }, 500);
});

/** Public. Proves the Function runs and reaches Postgres. Reveals only booleans, never values. */
app.get("/health", async (c) => {
  let database = false;
  try {
    const { rows } = await db().query<{ ok: number }>("SELECT 1 AS ok");
    database = rows[0]?.ok === 1;
  } catch {
    database = false;
  }
  return c.json(
    {
      ok: database,
      service: "radar-api",
      database,
      auth: Boolean(jwks && issuer),
      realtime: Boolean(realtime),
      realtimeDirect: Boolean(directRealtime),
    },
    database ? 200 : 503,
  );
});

app.get("/v1/me", async (c) => {
  const user = await requireUser(c.req.header("authorization"));
  return c.json({ id: user.id, email: user.email ?? null });
});

app.get("/v1/library/tracks", async (c) => {
  const user = await requireUser(c.req.header("authorization"));
  const { rows } = await db().query<{ track_id: string; saved_at: Date }>(
    "SELECT track_id, saved_at FROM radar_saved_tracks WHERE user_id = $1 ORDER BY saved_at DESC LIMIT 500",
    [user.id],
  );
  return c.json({ tracks: rows.map((r) => ({ trackId: r.track_id, savedAt: r.saved_at.toISOString() })) });
});

app.put("/v1/library/tracks/:trackId", async (c) => {
  const user = await requireUser(c.req.header("authorization"));
  const trackId = trackIdParam(c.req.param("trackId"));
  const { rows } = await db().query<{ track_id: string; saved_at: Date; txid: string }>(
    `INSERT INTO radar_saved_tracks (user_id, track_id) VALUES ($1, $2)
     ON CONFLICT (user_id, track_id) DO UPDATE SET saved_at = radar_saved_tracks.saved_at
     RETURNING track_id, saved_at, pg_current_xact_id()::text AS txid`,
    [user.id, trackId],
  );
  const row = rows[0]!;
  return c.json({ trackId: row.track_id, savedAt: row.saved_at.toISOString(), txid: row.txid });
});

app.delete("/v1/library/tracks/:trackId", async (c) => {
  const user = await requireUser(c.req.header("authorization"));
  const trackId = trackIdParam(c.req.param("trackId"));
  const { rows } = await db().query<{ deleted: number; txid: string }>(
    `WITH d AS (DELETE FROM radar_saved_tracks WHERE user_id = $1 AND track_id = $2 RETURNING 1)
     SELECT (SELECT count(*) FROM d)::int AS deleted, pg_current_xact_id()::text AS txid`,
    [user.id, trackId],
  );
  return c.json({ deleted: rows[0]!.deleted > 0, txid: rows[0]!.txid });
});

/** A sealed live query for the caller's library. The SQL and parameters are opaque to the client. */
app.post("/v1/library/live", async (c) => {
  const user = await requireUser(c.req.header("authorization"));
  if (!realtime) throw new HTTPException(503, { message: "realtime is not configured" });
  return c.json(await realtime.seal({ query: savedTracksQuery(user.id) }));
});

/**
 * Authenticated self-test of Realtime, run entirely server-side (Function → Realtime WebSocket).
 * Scoped to the caller's own library: it saves a marker track, waits for the live query to
 * deliver it, deletes it and reports timings. Safe to keep; it never touches other users' rows.
 */
app.post("/v1/library/live/selftest", async (c) => {
  const user = await requireUser(c.req.header("authorization"));
  if (!directRealtime) throw new HTTPException(503, { message: "realtime direct subscriptions are not configured" });
  const marker = `selftest-${Date.now().toString(36)}`;
  const started = Date.now();
  let unsubscribe: (() => void) | undefined;
  try {
    const subscription = await directRealtime.subscribe(savedTracksQuery(user.id));
    unsubscribe = () => subscription.unsubscribe();
    await subscription.awaitRows(() => true, 15_000);
    const initialRows = subscription.getSnapshot().data?.length ?? 0;
    const initialMs = Date.now() - started;

    const insertedAt = Date.now();
    await db().query("INSERT INTO radar_saved_tracks (user_id, track_id) VALUES ($1, $2)", [user.id, marker]);
    await subscription.awaitRows((rows) => rows.some((r) => r.track_id === marker), 15_000);
    const insertMs = Date.now() - insertedAt;

    const deletedAt = Date.now();
    await db().query("DELETE FROM radar_saved_tracks WHERE user_id = $1 AND track_id = $2", [user.id, marker]);
    await subscription.awaitRows((rows) => !rows.some((r) => r.track_id === marker), 15_000);
    const deleteMs = Date.now() - deletedAt;

    return c.json({ ok: true, status: subscription.getSnapshot().status, initialRows, initialMs, insertMs, deleteMs });
  } catch (err) {
    await db().query("DELETE FROM radar_saved_tracks WHERE user_id = $1 AND track_id = $2", [user.id, marker]).catch(() => {});
    console.error("realtime selftest failed", err instanceof Error ? err.message : err);
    return c.json({ ok: false, error: err instanceof Error ? err.message : "selftest failed" }, 500);
  } finally {
    unsubscribe?.();
  }
});

export default app;
