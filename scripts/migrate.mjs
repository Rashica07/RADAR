// Applies server/migrations/*.sql in order, idempotently, over Neon's SQL-over-HTTPS endpoint.
//
// Why HTTPS and not a `pg` connection: this runs wherever the Postgres TCP port may be
// unreachable (locked-down CI, sandboxes). The deployed Function itself uses node-postgres.
// Uses the DIRECT (unpooled) URL, as the Neon Postgres skill advises for migrations.
//
//   NODE_USE_ENV_PROXY=1 node scripts/migrate.mjs      (the flag only matters behind an HTTPS proxy)
import { neon } from "@neondatabase/serverless";
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join } from "node:path";

function loadEnv() {
  for (const f of [".env", ".env.local"]) {
    if (!existsSync(f)) continue;
    for (const line of readFileSync(f, "utf8").split("\n")) {
      const m = line.match(/^([A-Z0-9_]+)=(.*)$/);
      if (m && process.env[m[1]] === undefined) process.env[m[1]] = m[2].replace(/^["']|["']$/g, "");
    }
  }
}
loadEnv();

const url = process.env.DATABASE_URL_UNPOOLED;
if (!url) throw new Error("DATABASE_URL_UNPOOLED is not set. Run `neon deploy` (or `neon env pull`) first.");

const sql = neon(url);
const dir = "server/migrations";
const files = readdirSync(dir).filter((f) => f.endsWith(".sql")).sort();
for (const file of files) {
  // One statement per call over HTTP: split on semicolons that end a statement.
  const statements = readFileSync(join(dir, file), "utf8")
    .replace(/--.*$/gm, "")
    .split(/;\s*(?:\n|$)/)
    .map((s) => s.trim())
    .filter(Boolean);
  for (const statement of statements) await sql.query(statement);
  console.log(`applied ${file} (${statements.length} statements)`);
}
const [{ count }] = await sql.query("SELECT count(*)::int AS count FROM radar_saved_tracks");
console.log(`radar_saved_tracks exists; rows: ${count}`);
