// End-to-end verification of every Neon service wired into RADAR, against the LIVE project.
//
//   npm run verify          (sets NODE_USE_ENV_PROXY=1 so Node's fetch honours an HTTPS proxy)
//
// What it proves, in order:
//   FUNCTIONS  the starter function and the RADAR API respond
//   AUTH       sign-up, sign-in (session cookie), JWT issue, independent JWT verification via JWKS
//   API+AUTH   the Function accepts a valid token and rejects missing / garbage / tampered ones
//   POSTGRES   writes through the API land in Postgres under the verified user id; reads return
//              them; a second user cannot see or delete them
//   REALTIME   the sealed live query is opaque; a server-side subscription inside the Function
//              observes an insert and a delete
//
// It creates two throwaway users (`radar-verify-*@example.invalid`) and ALWAYS deletes them and
// their rows afterwards. Raw WebSockets and raw-TCP Postgres cannot cross some sandbox proxies,
// so Realtime is exercised from inside the Function and Postgres is read back over SQL-over-HTTPS.
import { neon } from "@neondatabase/serverless";
import { createRemoteJWKSet, decodeProtectedHeader, jwtVerify } from "jose";
import { existsSync, readFileSync } from "node:fs";

// ---------- env ----------
for (const f of [".env", ".env.local"]) {
  if (!existsSync(f)) continue;
  for (const line of readFileSync(f, "utf8").split("\n")) {
    const m = line.match(/^([A-Z0-9_]+)=(.*)$/);
    if (m && process.env[m[1]] === undefined) process.env[m[1]] = m[2].replace(/^["']|["']$/g, "");
  }
}
const need = (k) => {
  const v = process.env[k];
  if (!v) throw new Error(`${k} is not set. Run \`npm run deploy\` first.`);
  return v;
};
const AUTH = need("NEON_AUTH_BASE_URL");
const JWKS_URL = need("NEON_AUTH_JWKS_URL");
const API = `https://${need("NEON_BRANCH_ID")}-radar${need("NEON_FUNCTION_HOST_SUFFIX")}`;
const HELLO = `https://${need("NEON_BRANCH_ID")}-hello${need("NEON_FUNCTION_HOST_SUFFIX")}/`;
const issuer = new URL(AUTH).origin;
const ORIGIN = "http://localhost:3000"; // pre-approved by Neon Auth; native clients must send a trusted Origin
const sql = neon(need("DATABASE_URL_UNPOOLED"));

// ---------- tiny harness ----------
let failures = 0;
const results = [];
function check(service, name, ok, detail = "") {
  if (!ok) failures++;
  results.push({ service, name, ok });
  console.log(`${ok ? "PASS" : "FAIL"}  [${service}] ${name}${detail ? `  — ${detail}` : ""}`);
}
const json = async (res) => {
  try {
    return await res.json();
  } catch {
    return null;
  }
};

// ---------- auth helpers ----------
const stamp = Date.now();
const rand = () => Math.random().toString(36).slice(2, 10);
async function signUp(label) {
  const email = `radar-verify-${stamp}-${label}@example.invalid`;
  const password = `Pw-${rand()}-${rand()}-9!`;
  const res = await fetch(`${AUTH}/sign-up/email`, {
    method: "POST",
    headers: { "content-type": "application/json", origin: ORIGIN },
    body: JSON.stringify({ email, password, name: `Radar Verify ${label}` }),
  });
  const body = await json(res);
  return { email, password, status: res.status, id: body?.user?.id };
}
async function signIn(user) {
  const res = await fetch(`${AUTH}/sign-in/email`, {
    method: "POST",
    headers: { "content-type": "application/json", origin: ORIGIN },
    body: JSON.stringify({ email: user.email, password: user.password }),
  });
  const cookies = res.headers.getSetCookie().map((c) => c.split(";")[0]).join("; ");
  return { status: res.status, cookies, body: await json(res) };
}
async function jwtFor(cookies) {
  const res = await fetch(`${AUTH}/token`, { headers: { cookie: cookies, origin: ORIGIN } });
  const body = await json(res);
  return { status: res.status, token: body?.token };
}
const api = (path, token, init = {}) =>
  fetch(`${API}${path}`, { ...init, headers: { ...(token ? { authorization: `Bearer ${token}` } : {}), "content-type": "application/json", ...(init.headers ?? {}) } });

const userIds = [];
try {
  // =================== FUNCTIONS ===================
  const hello = await fetch(HELLO);
  check("functions", "starter function `hello` responds 200", hello.status === 200, `body=${JSON.stringify((await hello.text()).slice(0, 40))}`);
  const health = await json(await fetch(`${API}/health`));
  check("functions", "RADAR API /health ok", health?.ok === true && health?.service === "radar-api");
  check("postgres", "Function reaches Postgres (SELECT 1 through the pooled pg pool)", health?.database === true);
  check("auth", "Function has Neon Auth configured", health?.auth === true);
  check("realtime", "Function has Realtime configured (sealing + direct subscribe)", health?.realtime === true && health?.realtimeDirect === true);

  // =================== AUTH ===================
  const A = await signUp("a");
  const B = await signUp("b");
  check("auth", "sign-up user A", A.status === 200 && !!A.id, `HTTP ${A.status}`);
  check("auth", "sign-up user B", B.status === 200 && !!B.id, `HTTP ${B.status}`);
  userIds.push(A.id, B.id);
  const badLogin = await fetch(`${AUTH}/sign-in/email`, {
    method: "POST",
    headers: { "content-type": "application/json", origin: ORIGIN },
    body: JSON.stringify({ email: A.email, password: "definitely-wrong-password-1!" }),
  });
  check("auth", "wrong password is rejected", badLogin.status >= 400 && badLogin.status < 500, `HTTP ${badLogin.status}`);
  const noOrigin = await fetch(`${AUTH}/sign-in/email`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ email: A.email, password: A.password }),
  });
  const noOriginBody = await noOrigin.text();
  check(
    "auth",
    "request without an Origin is rejected (MISSING_ORIGIN)",
    noOrigin.status === 403 && /MISSING_OR_NULL_ORIGIN/.test(noOriginBody),
    `HTTP ${noOrigin.status} ${noOriginBody.slice(0, 80)}`,
  );

  const sa = await signIn(A);
  const sb = await signIn(B);
  check("auth", "sign-in A returns a session cookie", sa.status === 200 && sa.cookies.includes("session_token"));
  const ja = await jwtFor(sa.cookies);
  const jb = await jwtFor(sb.cookies);
  check("auth", "session exchanges for a JWT (GET /token)", ja.status === 200 && ja.token?.split(".").length === 3);
  const header = ja.token ? decodeProtectedHeader(ja.token) : {};
  check("auth", "JWT is EdDSA", header.alg === "EdDSA", `alg=${header.alg}`);
  const jwks = createRemoteJWKSet(new URL(JWKS_URL));
  let claims;
  try {
    claims = (await jwtVerify(ja.token, jwks, { issuer, audience: issuer, algorithms: ["EdDSA"] })).payload;
  } catch (e) {
    claims = undefined;
  }
  check("auth", "JWT verifies independently against the published JWKS", !!claims && claims.sub === A.id, `sub matches user id: ${claims?.sub === A.id}`);
  check("auth", "JWT lifetime is short", !!claims && claims.exp - claims.iat <= 900, `${claims ? claims.exp - claims.iat : "?"}s`);

  // =================== API + AUTH ===================
  const me = await api("/v1/me", ja.token);
  const meBody = await json(me);
  check("functions+auth", "valid token → /v1/me returns the caller's id", me.status === 200 && meBody?.id === A.id);
  check("functions+auth", "no token → 401", (await api("/v1/me")).status === 401);
  check("functions+auth", "garbage token → 401", (await api("/v1/me", "abc.def.ghi")).status === 401);
  const tampered = ja.token.slice(0, -4) + (ja.token.endsWith("AAAA") ? "BBBB" : "AAAA");
  check("functions+auth", "tampered signature → 401", (await api("/v1/me", tampered)).status === 401);
  const [h, p] = ja.token.split(".");
  const forged = `${h}.${Buffer.from(JSON.stringify({ ...JSON.parse(Buffer.from(p, "base64url")), sub: B.id })).toString("base64url")}.${ja.token.split(".")[2]}`;
  check("functions+auth", "payload swapped to another user's id (signature kept) → 401", (await api("/v1/me", forged)).status === 401);

  // =================== POSTGRES (through the API) ===================
  const put1 = await api("/v1/library/tracks/verify-slow-orbit", ja.token, { method: "PUT" });
  const put1b = await json(put1);
  check("postgres", "PUT saves a track", put1.status === 200 && put1b?.trackId === "verify-slow-orbit" && !!put1b?.txid, `HTTP ${put1.status}`);
  const putAgain = await api("/v1/library/tracks/verify-slow-orbit", ja.token, { method: "PUT" });
  check("postgres", "PUT is idempotent", putAgain.status === 200);
  await api("/v1/library/tracks/verify-gold-hour", ja.token, { method: "PUT" });
  const list = await json(await api("/v1/library/tracks", ja.token));
  const ids = (list?.tracks ?? []).map((t) => t.trackId).sort();
  check("postgres", "GET returns exactly what was saved", JSON.stringify(ids) === JSON.stringify(["verify-gold-hour", "verify-slow-orbit"]), JSON.stringify(ids));
  check("postgres", "invalid track id → 400", (await api("/v1/library/tracks/NOT%20VALID!", ja.token, { method: "PUT" })).status === 400);

  const rows = await sql.query("SELECT user_id, track_id FROM radar_saved_tracks WHERE track_id LIKE 'verify-%' ORDER BY track_id");
  check("postgres", "rows are physically in Postgres under the verified user id (read back over SQL)", rows.length === 2 && rows.every((r) => r.user_id === A.id), `${rows.length} rows`);

  const listB = await json(await api("/v1/library/tracks", jb.token));
  check("postgres", "user B cannot see user A's tracks", Array.isArray(listB?.tracks) && listB.tracks.length === 0);
  const delB = await json(await api("/v1/library/tracks/verify-slow-orbit", jb.token, { method: "DELETE" }));
  check("postgres", "user B cannot delete user A's track", delB?.deleted === false);
  const listA2 = await json(await api("/v1/library/tracks", ja.token));
  check("postgres", "…and it is still there for A", listA2?.tracks?.some((t) => t.trackId === "verify-slow-orbit"));
  const delA = await json(await api("/v1/library/tracks/verify-gold-hour", ja.token, { method: "DELETE" }));
  check("postgres", "DELETE removes the caller's own track", delA?.deleted === true);
  const afterDel = await sql.query("SELECT track_id FROM radar_saved_tracks WHERE user_id = $1", [A.id]);
  check("postgres", "deletion is visible in Postgres", afterDel.length === 1 && afterDel[0].track_id === "verify-slow-orbit");

  // =================== REALTIME ===================
  check("realtime", "unauthenticated sealed-query request → 401", (await api("/v1/library/live", undefined, { method: "POST" })).status === 401);
  const liveRes = await api("/v1/library/live", ja.token, { method: "POST" });
  const liveText = await liveRes.text();
  check("realtime", "authenticated request returns a sealed live query", liveRes.status === 200 && liveText.startsWith("{"), `HTTP ${liveRes.status}, ${liveText.length} bytes`);
  check("realtime", "sealed query is opaque: no table name, SQL, or user id visible", !/radar_saved_tracks|SELECT|user_id/i.test(liveText) && !liveText.includes(A.id));
  const liveB = await (await api("/v1/library/live", jb.token, { method: "POST" })).text();
  check("realtime", "different users get different sealed queries", liveB !== liveText);
  const selftest = await api("/v1/library/live/selftest", ja.token, { method: "POST" });
  const st = await json(selftest);
  check(
    "realtime",
    "server-side subscription sees an INSERT and a DELETE in real time",
    selftest.status === 200 && st?.ok === true && st?.status === "live",
    selftest.status === 200 ? `initial ${st.initialMs}ms (${st.initialRows} rows), insert→event ${st.insertMs}ms, delete→event ${st.deleteMs}ms` : `HTTP ${selftest.status} ${JSON.stringify(st)}`,
  );
  check("realtime", "self-test is authenticated", (await api("/v1/library/live/selftest", undefined, { method: "POST" })).status === 401);
  const leftover = await sql.query("SELECT count(*)::int AS n FROM radar_saved_tracks WHERE user_id = $1 AND track_id LIKE 'selftest-%'", [A.id]);
  check("realtime", "self-test cleaned up its marker row", leftover[0].n === 0);
} catch (err) {
  failures++;
  console.error("ABORTED:", err instanceof Error ? err.message : err);
} finally {
  // =================== CLEANUP (always) ===================
  try {
    // Pattern-based on purpose: removes THIS run's users and any stragglers from an aborted run.
    // `.invalid` is a reserved TLD, so this can never match a real person's account.
    // neon_auth.session / account / member / invitation cascade from the user row.
    await sql.query(`DELETE FROM radar_saved_tracks WHERE user_id IN (SELECT id::text FROM neon_auth."user" WHERE email LIKE 'radar-verify-%@example.invalid')`);
    await sql.query(`DELETE FROM neon_auth."user" WHERE email LIKE 'radar-verify-%@example.invalid'`);
    const left = await sql.query(`SELECT (SELECT count(*) FROM neon_auth."user" WHERE email LIKE 'radar-verify-%@example.invalid')::int AS users, (SELECT count(*) FROM radar_saved_tracks WHERE track_id LIKE 'verify-%')::int AS rows`);
    console.log(`cleanup: throwaway users left = ${left[0].users}, verify rows left = ${left[0].rows}`);
  } catch (e) {
    console.error("cleanup problem:", e instanceof Error ? e.message : e);
    failures++;
  }
}

const passed = results.filter((r) => r.ok).length;
console.log(`\n${passed}/${results.length} checks passed${failures ? `, ${failures} problem(s)` : ""}`);
process.exit(failures ? 1 : 0);
