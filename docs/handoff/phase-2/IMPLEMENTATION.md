# IMPLEMENTATION

What was built in Phase 2, in the order it was built. Tags: `[VERIFIED]` executed/observed · `[UNVERIFIED]` written, never compiled/run · `[NOT DONE]` · `[ASSUMPTION]`.

Totals (from `wc -l`): **3,257 lines of app Swift** in 24 files (3,563 lines in 27 files including tests), 238 lines of JS and 26 of Python in `tools/`. The largest Swift file, `RadarIconPaths.swift` (693 lines), is generated.

---

## 0. Source of truth: the Phase 01 artifact

- **Artifact:** "RADAR — Find what's moving (Art direction revision)", https://claude.ai/artifact/Js5gigTTofFCDwYCoWtWKW, version `1795423913-ab52`, 20 published files. `[VERIFIED]` read via the Artifact tool.
- It is a **minified Vite + React bundle with no source**: `assets/index-BFXzLKka.js` (386,872 B, sha256 `200cbd514a532c01703ba4474896592e66dd969bbed4f24e00786859c6db6a26`) and `assets/index-BqwRgFdI.css` (63,242 B, sha256 `672b3bf806315e7b817b88866add33d552163251fef6e029751d317cfd69b2ba`).
- **Reverse engineering** `[VERIFIED]`: prettier 3.8.1 → `app.pretty.js` (24,752 lines; app code ≈ lines 16,300–24,750); CSS flattened to one rule per line (705 rules). Read in full: data module, helpers, artwork engine (8 generators), icon set, state providers (settings, library, toasts, downloads, player, context menu), every screen, and the design-token object `di` ("single source of truth", incl. haptics already mapped to iOS generators).
- **Routes found:** `/`, `/trending`, `/search`, `/library`, `/track/:id`, `/artist/:id`, `/playlist/:id`, `/album/:id`, `/settings`, `/art`, `*`. Router is a `MemoryRouter` (so a URL can't open a route; a local copy was patched to read `location.hash` for screenshots).
- **Reference screenshots** `[VERIFIED]`: Playwright + Chromium at 393×852 DPR 1 of all routes, plus expanded player and search results. 26 files; not committed (see zip `reference/`). Note `queue.png` duplicates `player.png` (the click failed) and `nope*.png` is Discover (unknown route falls back to Discover).

## 1. Fonts

`tools/fonts.py` (fontTools 4.68.0) → `RADAR/Resources/Fonts/*.ttf`. iOS cannot load woff2 or variable web fonts as named weights, so static instances were produced:

| Family | Weights | Source file in artifact | Method |
|---|---|---|---|
| Big Shoulders Display | 700, 800, 900 | `big-shoulders-display-latin-{700,800,900}-normal-*.woff2` (already static) | decompress + rename |
| Space Grotesk | 500, 600, 700 | `space-grotesk-latin-wght-normal-*.woff2` (variable) | `instancer.instantiateVariableFont(wght=…)` |
| Inter | 400, 500, 600, 700 | `inter-latin-wght-normal-*.woff2` (variable) | same |

- `[VERIFIED]` Internal names set and read back: PostScript names `BigShouldersDisplay-{Bold,ExtraBold,Black}`, `SpaceGrotesk-{Medium,SemiBold,Bold}`, `Inter-{Regular,Medium,SemiBold,Bold}`; weight classes 700/800/900, 500/600/700, 400/500/600/700.
- `[VERIFIED]` Glyph coverage for `è á ’ “ · — …` in Inter-SemiBold; `’ è #` in Big Shoulders Black.
- **Only the Latin subsets were converted.** The Latin-extended, Cyrillic, Greek, Vietnamese files in the artifact were not (`[ASSUMPTION]`: demo copy is Latin-1).
- `[UNVERIFIED]` that iOS registers and resolves these names (`UIAppFonts` is not set — no Info.plist exists).
- Swift: `RadarFont` (`Typography.swift`) → `display(_:_:relativeTo:)`, `ui(_:_:relativeTo:)`, `body(_:_:relativeTo:)`, `bundledFiles` (the 10 file names for `UIAppFonts`), `View.radarReadout(_:)` (11 pt, tracking 0.13 em, uppercase).

## 2. Icons

44 icons live in the bundle's `qr` object (24×24 grid, stroke 1.75, round caps/joins). `tools/extract.js` evaluates that slice in Node; `tools/icons.js` converts each SVG primitive with `svgpath` (`abs().unarc().unshort()`) into Swift `Path` calls and writes `RadarIconPaths.swift` (`RadarIconName` enum + `parts`). Circles/ellipses → `addEllipse`, rects → `addRoundedRect`; `currentColor` fills → `fill: true`; the filled Discover icon's `var(--icon-cut)` strokes → `cut: true`. Swift keyword `repeat` is backtick-escaped.

- `RadarIcon` (`DesignSystem/Icons/RadarIcon.swift`): a `Canvas` that scales the 24-grid, fills/strokes each `IconPart` with `.foreground`, and strokes `cut` parts in the `radarIconCut` environment colour (default `Color.radarNavBg`).
- `[VERIFIED]` 44 icons generated; the 4 cases referenced in code (`check`, `download`, `trash`, `x`) all exist. `[UNVERIFIED]` visual fidelity (never rendered natively).

## 3. Asset catalog (`RADAR/Resources/Assets.xcassets`)

- `Theme/` namespace (`provides-namespace: true`) with 19 colour sets, each with a light ("Paper") entry and a dark-appearance entry, values from the artifact tokens (table in `FILES_CHANGED.md` and `DESIGN_SPEC.md`). Read in Swift as `Color("Theme/bg")` etc. (`Colors.swift`).
- `AccentColor` (mint), `LaunchBackground` (#101413 fixed), `AppIcon`, `AppIconGlitch`, `IconPreviewDefault`, `IconPreviewGlitch`.
- `[VERIFIED]` All 27 asset-catalog `Contents.json` files parse as JSON (30 JSON files in total, including the catalog and 2 fixtures). `[UNVERIFIED]` that Xcode's asset compiler accepts them (the `AppIcon*` sets include an `appearances: luminosity/dark` entry that reuses the same PNG).

## 4. Demo catalog

`tools/extract.js` evaluates the bundle's data module (`Wn, Gn, Kn, qn, Jn, Yn, Xn, $n, er, nr, rr, wr, Tr, Er, Dr, Or, kr, Ar, jr, Mr, Nr, Pr, Fr, Ir, Lr, …`) with `new Function`, so data and algorithms are taken from the original rather than retyped. Output filtered into `RADAR/Resources/DemoCatalog.json`.

- **Content** `[VERIFIED]`: 2 providers (Demo Catalog, Demo Indie Feed), 10 countries, **23 artists**, **46 tracks**, 10 albums, 8 playlists (6 editorial, 2 personal seeds), 12 genres, 7 trending searches, 3 default recent searches, 8 default saved, 6 default recent plays, 5 stories. All fictional; the file carries a `_notice`.
- **Deliberate deviation** `[ASSUMPTION]`: the artifact had 51 tracks / 24 artists / 3 providers. The 5 fictional "local files", the `local` artist and the "Demo Local Files" provider were **dropped** — native local files are real imports.
- The same run produced `RADARTests/Fixtures/ParityVectors.json` (hash, prng, charts for GLOBAL/7d, IT/7d, NG/24h, JP/30d, movers, emerging, rising, newReleases, 6 search queries, related, spark, art specs, a 72-bar waveform). **No Swift test consumes it yet.**

## 5. Core layer (`RADAR/Core`)

| Type | Behaviour | Status |
|---|---|---|
| `SeededHash.fnv1a(_:)` | 32-bit FNV-1a over **UTF-16 code units**, offset 2166136261, prime 16777619, wrapping arithmetic (= JS `charCodeAt` + `Math.imul`) | `[UNVERIFIED]`; vectors exist (`hash`: 5 strings) |
| `SeededRandom` | `init(seed:)`, `init(_ key:)`, `next() -> Double`; `state &+= 1831565813`, mulberry32 mixing, `/ 4294967296` | `[UNVERIFIED]`; vectors exist (`prng`) |
| `V8RandomSort.sort(_:comparator:)` | Emulates V8 TimSort's run detection + binary insertion for arrays < 64 when the comparator ignores its arguments (`sort(() => rng() - 0.5)`, used by the artifact's "blocks" cover) | `[UNVERIFIED]`, **no vectors, not yet used** |
| `Haptics` | `@MainActor`; `.tick` → selection generator, `.select/.light` → light impact, `.medium` → medium impact, `.success/.warning` → notification generator; global `isEnabled` | `[UNVERIFIED]` |
| `Format` | `time`, `compact`, `runtime`, `daysAgo`, `playedAgo`, `greeting`, `longDate`, `megabytes`, `plural` | `[UNVERIFIED]`; `longDate` uses `.dateTime…locale(en_GB)` and may punctuate differently from JS `toLocaleDateString` |
| `PersistenceController` | Files `Application Support/RADAR/radar.v1.<key>.json`; `load`, `save` (encodes immediately, writes after 0.35 s, coalesced), `remove`, `flush()` (synchronous) | `[UNVERIFIED]`; used by tests |

## 6. Models (`RADAR/Models`)

`CatalogModels.swift`: `TrackSource` (catalog/indie/local), `DownloadStatus` (available/downloaded/streaming-only/unavailable/local), `Provider`, `Country`, `Artist`, `Track` (+ `LocalFile` for imports; `isLocal`, `isNew` = ≤14 days), `Album`, `EditorialPlaylist`, `Genre`, `TrendingSearch`, `DefaultRecent`, `CatalogFile` (JSON root), `ChartWindow` (24h/7d/30d), `ChartEntry` (rank, previous, delta), `UserPlaylist`, `RecentPlay`.
`ArtSpec.swift`: `ArtPalette` (10, hex arrays), `ArtStyle` (8), `ArtSpec(key:palette:style:)` — palette = `seed % 10`, style = `(seed >> 4) % 8` unless overridden. **`ArtPalette`/`ArtStyle` raw-value order matches the JS arrays `qn`/`Kn`** (checked by reading both).

## 7. Services (`RADAR/Services`)

- **`DemoCatalog`** (`final class … Sendable`): loads the JSON (`fatalError` if missing/unreadable — `[UNVERIFIED]`). Lookups; `palette(forArtist:)` (palette index = artist's position in the roster, preserving the artifact's mapping); `art(for:)` overloads for track/album/artist/playlist/genre; **`chart(country:window:limit:)`** (score = `log10(plays+1)/7.2*0.5 + noise*0.38 + 0.42 home-country + 0.12 if <14 days`, noise from `SeededRandom("<id>|<key>")`, "prev" ordering from the `…|prev` key, new-entry rule identical to the artifact); `movers`, `emergingArtists` (<900K listeners), `risingArtists`, `newReleases`, `discoveries`, `stories`, `related`, `search` (prefix matches first), `spark`, and `waveform/rawWaveform/bucket`. `stableSorted` replaces JS's stable sort.
- **`SettingsStore`** (`@Observable`): `Settings` {theme dark/light/system, density, reduceMotion, country "IT", genres [Afrobeats, Alt R&B, House], hideExplicit, fx, haptics}; persisted under key `settings`; mirrors `haptics` into `Haptics.isEnabled`; `toggleGenre`, `reset`.
- **`LibraryStore`** (`@Observable`): `saved`, `recent` (cap 30), `playlists`, `searches` (cap 8) with the artifact's exact defaults; `toggleSave`, `addRecent`, `createPlaylist` ("New playlist N"), `add(_:to:)`, `remove(at:from:)`, `rename`, `deletePlaylist`, `purge(trackId:)`, `addSearch/removeSearch/clearSearches`, `resetAll`. Key `library`.
- **`ToastCenter`**: single toast, 2.4 s auto-dismiss. **No view renders it.**
- **`DownloadCenter`**: **simulated** downloads. A 110 ms ticker advances `pct += (0.9 + rand*2.4) * (1 - pct/140)`, rate 2–5.2 MB/s; completes at 100; completed ids persisted (key `downloads`). Nothing is fetched or written; toasts say "Simulated …". Size estimate `((duration/60)*1.4).rounded(1) + 2` MB.
- **`LocalLibrary`** (`@Observable`) — *real* local audio: `importFiles(_:)` copies picked files into `Application Support/RADAR/Imported/<uuid>.<ext>` (excluded from backup) on a detached task, reads metadata with `AVURLAsset.load(.duration, .commonMetadata)`, rejects files with no playable duration, creates a `Track` (`id: "local-<uuid>"`, `source: .local`, `download: .local`, `local: LocalFile`). `delete`, `fileURL(for:)`, `totalBytes`. Key `local-files`; entries whose file vanished are dropped at launch. `[UNVERIFIED]`, **no UI calls it, and there is no player to play the result.**
- **`WaveformAnalyzer`** (actor): streams 16-bit PCM via `AVAssetReader`, one peak per 2,048 samples, √-normalised, bucketed to 256, cached per URL. `[UNVERIFIED]`; it reads synchronously on the actor, so a long file occupies the actor for its duration.

## 8. Theme (`DesignSystem/Theme`)

`RadarRGB` (hex init, `mixed(with:_:)`, palette constants mint/coral/charcoal/warm/graphite) and `Color.radar*` accessors: brand constants are fixed colours; the 19 theme colours are asset-catalog lookups (`Color("Theme/<name>")`).

## 9. Brand: v1 → v2

1. **v1** — from the first brand sheet (1536×1024) a pixel row-scan produced coordinates for the four symbol pieces and five letters; vector paths were hand-fitted and overlaid on the sheet for comparison. A first app icon and `RadarBrand.swift` were generated from it (commit 1).
2. You then reported the A's and D's were slightly wrong and sent a higher-resolution sheet.
3. **v2** — re-measured from the new sheet's primary logo: symbol bbox 362×208 at (137,127), wordmark bbox 848×119 at (568,179), cap-height ratio 118:207. New path data in `tools/brand.js`: the middle arc is now two-tone (a warm-white head cut from the coral arc by a straight diagonal), the leg's top edge is rounded, R's use a rounded bowl with a straight-cut leg, A's lose the crossbar and have a flat top, D's are a stem + semicircle.
4. **Fit** `[VERIFIED]` (ad-hoc script, 1:1 scale, luminance > 100, best integer shift in ±8 px): symbol IoU **0.957** at shift (0,0); wordmark IoU **0.884** at shift (+8, +1). The wordmark is the weaker match: the sheet's two R's are not identical (first ≈150 units wide, last ≈128) while the code uses one R shape twice; letter origins differ from the sheet by up to ≈11 units (e.g. D stem at 358 in code vs 369 on the sheet).
5. Output: `docs/brand/*.svg`, `RadarBrandPaths.swift`, `AppIcon-1024.png`. Full numbers in `DESIGN_SPEC.md`.

These are **placeholders**; the Illustrator redraw replaces them.

## 10. The glitch system

You pointed to the big glitched logo on the third sheet. What it shows (observed by zooming and row-scanning): a **single-colour mint** logo (coral and white head gone), with **horizontal speed-smear streaks trailing off the left edges** — long at the top bar (≈11% of symbol width) and at the leg (≈22%), almost none in the middle — plus tiny ticks on the right and a few ticks/streaks at the ends of the wordmark. The clean logo restores coral, the white head and the warm-white wordmark.

Implementation (all `[UNVERIFIED]` in Swift; the JS twin `[VERIFIED]`):

- **`GlitchSpec.bands(seed:height:amount:maxLength:)`** (`GlitchSpec.swift`) — walks down the artwork in thin bands (1.5–7 units high), each active with a probability that rises near the top bar (y/H ≈ 0.20) and the leg (≈ 0.93); active bands get a smear length `amount × maxLength × weight × (0.25 + 0.75·r)`.
- **`RadarLogoCanvas`** (`RadarMarks.swift`) — draws trails first (8 translated copies per band, opacity `(1−k/8)^0.8 × 0.95`, clipped to the band so the band stays put while the artwork slides), then the clean artwork on top. `glitch` ∈ [0,1] scales streak length; `tint` ∈ [0,1] interpolates mint → brand colours.
- **`RadarReveal` / `RadarLogoReveal`** (`RadarLogoReveal.swift`) — the transition (§8 of `DESIGN_SPEC.md`): hold fully glitched, 8 hard-cut re-rolled steps shrinking the streaks, colour resolves, light haptic.
- **Tuning history** `[VERIFIED]` by looking at renders: the first parameters (bands 3–12 units high, weight floor 0.18, activity `0.30 + 0.55·weight`, 7 copies, alpha `(1−k/7)^1.5 × 0.9`) looked soft and blurry; the sheet's streaks are thin and crisp with dark gaps. Final: bands 1.5–7 units, weight floor 0.10, activity `0.10 + 0.75·weight`, 8 copies, alpha `(1−k/8)^0.8 × 0.95`.
- **Seed selection** `[ASSUMPTION]`: six candidate seeds (3, 7, 11, 19, 23, 42) were rendered side by side; **7** was picked by eye (long top streak, bottom streaks, little mess inside the gaps).

## 11. Alternate app icon + feature flag + picker

- **Art:** `tools/glitch-icon.js 7` → `docs/brand/radar-app-icon-glitch.svg` (the symbol, all mint, placed +34 px right of centre so the streaks sit inside the icon) → rendered to `AppIconGlitch-1024.png` (and 512 px preview). The standard icon uses the same layout without the +34 px shift.
- **`AppIconChoice`** — `.standard` (`alternateName == nil`) and `.glitch` (`"AppIconGlitch"`), `previewAsset`, `requiredFlag` (`.glitchAppIcon` for glitch).
- **`AppIconApplying` / `SystemIconApplier`** — thin wrapper over `UIApplication.supportsAlternateIcons`, `.alternateIconName`, `setAlternateIconName(_:) async throws`; exists so the service is testable.
- **`AppIconService`** (`@Observable`) — `current`, `refresh()`, `availableChoices(flags:)` (a flagged icon stays listed while it is the *active* icon, so nobody is stranded), `isPickerVisible(flags:)` (supported device **and** more than one choice), `select(_:)` (no-op if unchanged; leaves `current` untouched on failure).
- **`FeatureFlags`** — see `FEATURE_FLAGS.md`.
- **`AppIconPickerSection`** — tiles (92 pt, corner radius 22.37%, 3 pt accent stroke + check badge when selected), footnote variants, toasts + haptics on success/failure. **`FeatureFlagControls`** — per-flag toggle that writes a local override, plus "Clear override", server value readout and "Refresh from server".
- **Not wired:** neither view is mounted anywhere, nothing injects `AppIconService`/`FeatureFlags`/`ToastCenter` into the environment, and nothing calls `FeatureFlags.refresh()`.

## 12. Tests

29 XCTest methods across `GlitchTests` (5), `RadarRevealTests` (6), `FeatureFlagsTests` (8), `AppIconServiceTests` (10) + `Fixture` helper. **None has been run.** See `TESTING.md`.

## 13. Tooling in `tools/`

`extract.js`, `icons.js`, `fonts.py`, `brand.js`, `glitch.js`, `glitch-icon.js` (usage in `DEPENDENCIES.md`). There is **no `package.json`**, `icons.js` hard-codes `./npm/node_modules/svgpath`, and the Playwright SVG→PNG renderer that made the icon PNGs is **not in the repo** (`KNOWN_ISSUES.md` #9).

## 14. Decisions and assumptions (consolidated)

| # | Decision | Tag |
|---|---|---|
| 1 | Minimum iOS 17 (Observation, `#Preview`, `@Environment(Type.self)`); Swift 5 language mode | `[ASSUMPTION]` |
| 2 | "The database" = Supabase REST (`feature_flags` table, anon key) | `[ASSUMPTION]` — you never named Supabase |
| 3 | Flags fail closed; local override beats remote | design choice |
| 4 | Glitch icon stays selectable while active even if its flag is later turned off | design choice |
| 5 | Dropped the 5 fictional local files; local audio is real import | `[ASSUMPTION]` |
| 6 | Icon background `#101413` (brand charcoal), not the pure black drawn on the sheet | `[ASSUMPTION]` |
| 7 | Symbol = 64% of icon width; glitch icon shifted +34 px right | `[ASSUMPTION]` |
| 8 | Glitch seed 7 | `[ASSUMPTION]` |
| 9 | Haptic mapping follows the artifact's `$haptic` token table | from source |
| 10 | Only Latin font subsets converted | `[ASSUMPTION]` |
| 11 | Persisted state lives in JSON files (not SwiftData/UserDefaults) | design choice |
| 12 | The artifact's *RGB-split* glitch (text, artwork bursts) is a different effect from the brand's *speed-smear* glitch; only the latter is implemented | observation |
