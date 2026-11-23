# RADAR on Neon

Project `ancient-tree-46657823`, branch `production`. Services: Postgres, Auth, Functions, Realtime.

```
iOS app ──Bearer JWT──▶ Function `radar` (server/api.ts) ──pg pool──▶ Postgres
iOS app ──cookie──────▶ Neon Auth (/sign-in/email, /token)
iOS app ◀─ sealed live query ─ Function `radar` ─ NEON_REALTIME_SECRET (never leaves the Function)
```

The app never gets `DATABASE_URL` or the Realtime secret. It gets only public endpoints (`Config/Local.xcconfig`).

## Backend files
| File | Purpose |
|---|---|
| `neon.ts` | Services, the `hello` and `radar` functions, Realtime env passthrough |
| `server/api.ts` | Hono API: `/health`, `/v1/me`, `/v1/library/tracks[/:id]`, `/v1/library/live`, `/v1/library/live/selftest` |
| `server/migrations/001_saved_tracks.sql` | `radar_saved_tracks` |
| `scripts/migrate.mjs` | `npm run migrate` (HTTPS, unpooled URL) |
| `scripts/verify.mjs` | `npm run verify` — end-to-end proof against the deployed branch, cleans up after itself |

Commands: `npm run build` (typecheck), `npm run deploy`, `npm run migrate`, `npm run verify`.

## Things that will bite you
- **Auth needs a trusted `Origin`.** A native app has no browser origin, so requests without one get
  `403 MISSING_OR_NULL_ORIGIN`. Pick an origin for the app and register it:
  `neon neon-auth domain add <origin>`, then set `RADAR_AUTH_ORIGIN` to the same value. This is **not done yet**.
  `http://localhost:3000` is pre-approved but is a dev placeholder, not something to ship.
- `GET /token` needs the **session cookie**; a bearer session token gets 401. `NeonAuthClient` keeps a private cookie jar for this.
- Realtime env vars are not auto-injected into Functions: `neon.ts` forwards them as `RADAR_REALTIME_*`, so deploy with `neon deploy --env .env.local` (`npm run deploy`).
- `ws` must be statically imported in `server/api.ts`; the Realtime SDK's own dynamic import is invisible to the bundler.
- `server/api.ts` has a public URL. Every route except `/health` verifies the JWT first.

## Not done
- No Swift Realtime client. The protocol JSON schemas ship in `@neon/realtime`, but a native client is a separate piece of work. Until then the app can poll `/v1/library/tracks`.
- The Swift files (`RADAR/Services/Backend/*`, `RADARTests/BackendConfigTests.swift`) were never compiled or run: no Swift toolchain here. They follow the HTTP behaviour `scripts/verify.mjs` checked, but treat them as UNVERIFIED until Xcode builds them.
- Nothing is wired into the SwiftUI views yet (no sign-in screen, `LibraryStore` still uses `LocalLibrary`).
