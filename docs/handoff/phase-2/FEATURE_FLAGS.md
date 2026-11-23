# FEATURE_FLAGS

Everything about the remote gate for the Glitch app icon. Tags: `[VERIFIED]` executed · `[UNVERIFIED]` written, never compiled/run · `[NOT DONE]` · `[ASSUMPTION]`.

## 1. Summary

- One flag exists: **`glitch_app_icon`** (`FeatureFlag.glitchAppIcon`), default **off**.
- It controls only whether **Settings → App icon** offers the Glitch icon. It does not deliver the icon: the icon is compiled into the app.
- Flags **fail closed** and are cached; an offline or failing refresh never flips one.
- **No backend exists.** No Supabase project or table was created or touched; the client is written against an *assumed* Supabase REST table. `[ASSUMPTION]` You said "the database"; you did not name Supabase.
- **`FeatureFlags.refresh()` is never called by any code** and neither Settings view is mounted anywhere (`KNOWN_ISSUES.md` #3, #4).

## 2. Code map

| Symbol | File | Role |
|---|---|---|
| `FeatureFlag` | `RADAR/Services/FeatureFlags.swift` | enum of flags; `rawValue` = database key; `defaultValue` (false); `title` |
| `FlagProvider` | same | `protocol FlagProvider: Sendable { func fetch() async throws -> [String: Bool] }` |
| `SupabaseFlagProvider` | same | REST implementation; `fromBundle(_:)` builds it from Info.plist or returns nil |
| `FeatureFlags` | same | `@MainActor @Observable` store: `isEnabled`, `remoteValue`, `override`, `setOverride`, `refresh(force:)`, `isRemoteConfigured`, `lastRefresh`, `lastError` |
| `AppIconChoice.requiredFlag` | `RADAR/Services/AppIconService.swift` | ties `.glitch` to `.glitchAppIcon` |
| `AppIconService.availableChoices(flags:)`, `isPickerVisible(flags:)` | same | picker rules (§5) |
| `AppIconPickerSection`, `FeatureFlagControls` | `RADAR/Features/Settings/AppIconPickerSection.swift` | UI |

## 3. Precedence

```
isEnabled(flag) = localOverride[flag]  ??  remoteValue[flag]  ??  flag.defaultValue (false)
```

| Local override | Server value | Result |
|---|---|---|
| on | any / unset | **on** |
| off | on | **off** |
| none | on | on |
| none | off | off |
| none | *row missing* or never fetched | **off** (default) |

A failed refresh keeps the previous `remote` dictionary. A successful refresh **replaces** it wholesale: a flag absent from the new response becomes "unset" (→ default off).

## 4. Remote provider

### Configuration (Info.plist; **not present yet**, no Info.plist exists)
| Key | Value | Validation in `fromBundle` |
|---|---|---|
| `RADARFlagsURL` | `https://<project-ref>.supabase.co` | must parse, scheme `https`, have a host |
| `RADARFlagsAnonKey` | the project's **publishable / anon** key | non-empty |

If either is missing or invalid → provider is `nil` → `isRemoteConfigured == false` → `refresh()` returns immediately → everything stays at defaults/overrides. Do not hard-code values; feed them from an `.xcconfig` (note: `//` in an `.xcconfig` starts a comment — use the usual `$(SLASH)` workaround for the URL).

### Request `[UNVERIFIED]` against a live project
```
GET {RADARFlagsURL}/rest/v1/feature_flags?select=key,enabled
apikey: {anon key}
Authorization: Bearer {anon key}      ← only if the key starts with "eyJ" (a legacy JWT anon key)
cache policy: reloadIgnoringLocalCacheData · timeout 8 s
```
- Newer publishable keys are not JWTs and are sent **only** as `apikey` `[ASSUMPTION]` from Supabase's documented behaviour; this branch is untested.
- Success = HTTP 200 and a JSON array of `{ "key": String, "enabled": Bool }`. Extra columns are ignored. Duplicate keys: last wins.
- Any other status → `FlagError.badStatus`; transport/decoding errors propagate. `FeatureFlags` records `lastError` and keeps cached values.
- The table name is the stored property `SupabaseFlagProvider.table` (default `feature_flags`).

### Refresh policy
`refresh(force: false)` is a no-op if the last successful fetch was **< 300 s** ago (`minimumRefreshInterval`); `force: true` bypasses it. `[NOT DONE]` Required call sites: app launch and every return to foreground (`scenePhase == .active`); the docs in the repo claim this happens — it does not yet.

### Persistence
`radar.v1.flags.json` (Application Support/RADAR): `{ remote: [String: Bool], overrides: [String: Bool], fetchedAt: Date? }`. Loaded in `init`; saved after `setOverride` and each successful refresh (coalesced 0.35 s).

## 5. Picker rules (`AppIconService`)

| Flag on? | Current icon | Glitch listed? | Picker shown? |
|---|---|---|---|
| no | standard | no | **no** |
| yes | standard | yes | yes |
| yes | glitch | yes | yes |
| **no** | **glitch** | **yes (so the user can switch back)** | **yes** |
| any | any, but `supportsAlternateIcons == false` | — | **no** |

The picker needs ≥ 2 choices. Turning the flag off later does **not** revert anyone's icon (the OS keeps the choice); it only stops *new* people seeing Glitch. `[ASSUMPTION]` this is what you want ("enable that forever or go back"). There is deliberately no forced revert; implementing one would mean calling `setAlternateIconName(nil)` at launch and would trigger iOS's confirmation alert.

## 6. Local design-review controls (`FeatureFlagControls`)

- One `Toggle` per `FeatureFlag.allCases`; toggling calls `setOverride(flag, newValue)` (a persistent override). The caption shows `Server: on/off/not set · Default: off` or `Local override: on/off · Server: …`.
- "Clear override" appears while an override exists. "Refresh from server" appears only when `isRemoteConfigured` and calls `refresh(force: true)`.
- When remote isn't configured it says so ("every flag is off unless overridden here").
- **Not mounted** in any screen (there is no Settings screen). When it is, it must live in the artifact's "Design review controls" group; `[ASSUMPTION]` it should be **excluded from release builds** (`#if DEBUG` or a build flag) — otherwise any user can unlock the icon locally. Not implemented.

## 7. Supabase expectations (SQL you must run — nothing has been run)

```sql
create table public.feature_flags (
  key        text primary key,
  enabled    boolean not null default false,
  note       text,
  updated_at timestamptz not null default now()
);

alter table public.feature_flags enable row level security;

-- Anyone may read flags; the app has no write path.
create policy "flags are readable by everyone"
  on public.feature_flags for select
  to anon, authenticated
  using (true);

insert into public.feature_flags (key, enabled, note)
values ('glitch_app_icon', false, 'Shows the Glitch app icon choice in Settings');
```

Turn the feature on / off:

```sql
update public.feature_flags set enabled = true,  updated_at = now() where key = 'glitch_app_icon';
update public.feature_flags set enabled = false, updated_at = now() where key = 'glitch_app_icon';
```

Requirements and cautions:
- The row key must equal `FeatureFlag.rawValue` exactly (`glitch_app_icon`).
- Only the **publishable/anon** key belongs in the app; **never a `service_role` key**.
- RLS must allow `select` for `anon` and must not allow `insert/update/delete` for it (the policy above grants select only).
- Changes take effect on the next successful refresh (≤ 5 min after a foreground, once wired).
- An empty table, a missing table (HTTP 404) or RLS misconfiguration (empty array or 401/403) all leave the flag **off** (`[UNVERIFIED]` for each case).

## 8. Constraints worth knowing
- **Icons ship in the binary.** `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = AppIconGlitch` must be set at build time (`[NOT DONE]`, no project). A remote flag can unlock only icons already shipped; any *new* icon needs an app update.
- iOS shows its own "You have changed the icon for “RADAR”" alert; it cannot be suppressed.
- The gate is **client-side and cosmetic**: someone modifying the app could unlock the icon early. Nothing sensitive is behind it.
- App Review: mention that a cosmetic option is enabled remotely (`[ASSUMPTION]` good practice, not verified against current guidelines).

## 9. Tests that cover this (written, **not run**)
`FeatureFlagsTests` (8) — defaults off; remote enables; missing key stays off; override beats remote and can be cleared; failed refresh keeps last values; persists across instances; throttle; provider nil without config.
`AppIconServiceTests` (10) — picker hidden/visible rules; stays listed while active; switching back; asset names; no-op on same icon; failure leaves `current`; unsupported device.
Not covered: `SupabaseFlagProvider.fetch()` (needs a `URLProtocol` stub), `fromBundle` positive case, the SwiftUI views.

## 10. Needs your input
1. Confirm Supabase as "the database" (or name another).
2. Project URL + publishable key — **or** tell me to create the project/table myself (I have a Supabase connector attached in this session but did not use it; creating a project is outward-facing and may cost money).
3. When to flip the flag on, and whether release builds should hide the override controls.
