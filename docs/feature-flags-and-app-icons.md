# Feature flags & the Glitch app icon

RADAR ships with the **Glitch** alternate app icon built in, but hidden. A remote flag
decides when Settings offers it. Once it is on, anyone can pick it in
**Settings → App icon**, keep it as long as they like, and switch back to the standard
icon whenever they want.

## How it works

| Piece | File |
|---|---|
| Flag definitions, remote fetch, cache, local override | `RADAR/Services/FeatureFlags.swift` |
| Reading / changing the Home Screen icon | `RADAR/Services/AppIconService.swift` |
| Picker UI and design-review controls | `RADAR/Features/Settings/AppIconPickerSection.swift` |
| Icon art (both icons + in-app previews) | `RADAR/Resources/Assets.xcassets` (`AppIcon`, `AppIconGlitch`, `IconPreview*`) |
| Glitch look (shared by the animated logo and the icon) | `GlitchSpec.swift` ↔ `tools/glitch.js` |

Resolution order for a flag: **local override → last server value → default (off)**.
Every flag fails closed. A failed or offline refresh keeps the last known value; it never
flips a flag.

### Rules the picker follows
- Hidden while the flag is off and the standard icon is active.
- Appears when the flag is on.
- **Stays visible while Glitch is the active icon, even if the flag is later turned off**,
  so nobody is stuck on an icon with no way back. Only *new* choosers stop seeing it.
- Hidden on devices where `supportsAlternateIcons` is false.

## What a flag can and can't do

- ✅ Show or hide the icon picker remotely, instantly, without an app update.
- ❌ Deliver a new icon after release. **iOS requires alternate icons to be compiled into the
  app.** A new icon always needs a new build; only its *visibility* is remote.
- iOS shows its own "You have changed the icon for RADAR" alert. Apps can't suppress it.
- The gate is client-side and cosmetic. Someone who modifies the app could unlock the icon
  early; nothing sensitive sits behind it, so that's acceptable.
- Mention the remote switch in App Review notes (a hidden-until-enabled cosmetic option is
  normal, but say what it is).

## Backend (Supabase) — not created yet

No backend exists. Until `RADARFlagsURL` and `RADARFlagsAnonKey` are set, every flag is off
and Settings → Design review controls lets you override them locally.

```sql
create table public.feature_flags (
  key        text primary key,
  enabled    boolean not null default false,
  note       text,
  updated_at timestamptz not null default now()
);

alter table public.feature_flags enable row level security;

-- Anyone may read flags. Nobody can write them from the app.
create policy "flags are readable by everyone"
  on public.feature_flags for select
  to anon, authenticated
  using (true);

insert into public.feature_flags (key, enabled, note)
values ('glitch_app_icon', false, 'Shows the Glitch app icon choice in Settings');
```

Turn the icon **on** (or **off**) whenever you want:

```sql
update public.feature_flags set enabled = true,  updated_at = now() where key = 'glitch_app_icon';
update public.feature_flags set enabled = false, updated_at = now() where key = 'glitch_app_icon';
```

Or flip the row in the Supabase Table Editor. The app picks the change up on the next
launch or foreground (at most every five minutes).

The project URL and the publishable (anon) key are public by design. Never put a
`service_role` key in the app. Set them in Info.plist as `RADARFlagsURL`
(`https://<project-ref>.supabase.co`) and `RADARFlagsAnonKey`.

## Xcode project settings (applied when the project is created)

- `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`
- `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = AppIconGlitch`
- `UIAppFonts` = the ten files listed in `RadarFont.bundledFiles`
- `UILaunchScreen` background color = `LaunchBackground` (charcoal, same as the splash)
- `RADARFlagsURL` / `RADARFlagsAnonKey` from an `.xcconfig` (not committed with real values)

## Regenerating the art

The glitch icon and the logo SVGs are generated, never hand-drawn:

```sh
node tools/brand.js RADAR/DesignSystem/Brand docs/brand      # symbol, wordmark, logo, app icon, Swift paths
node tools/glitch-icon.js 7 docs/brand/radar-app-icon-glitch.svg   # glitched icon (seed 7)
```

When the Illustrator redraw of the logo arrives, update the paths in `tools/brand.js` and
rerun both commands: the standard icon, the glitched icon and the animated logo all follow.
