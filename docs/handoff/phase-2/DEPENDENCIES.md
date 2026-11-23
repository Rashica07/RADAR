# DEPENDENCIES

Versions are those **observed in this session's environment** unless marked otherwise.

## 1. App (runtime) dependencies

**No third-party Swift packages, CocoaPods or Carthage dependencies.** The app uses Apple frameworks only:

| Framework | Used by |
|---|---|
| SwiftUI | all views, `Canvas`, `TimelineView`, Observation-based environment |
| Observation (`@Observable`) | all stores |
| Foundation / OSLog | persistence, flags networking (`URLSession`), logging |
| UIKit | `Haptics` (feedback generators), `AppIconService` (`UIApplication`) |
| AVFoundation / CoreMedia | `LocalLibrary`, `AudioMetadata`, `WaveformAnalyzer` |
| UniformTypeIdentifiers | `LocalLibrary.supportedTypes` |
| XCTest | tests |

Not yet used but planned: MediaPlayer (`MPNowPlayingInfoCenter`, `MPRemoteCommandCenter`), AVAudioSession.

| Item | Value | Tag |
|---|---|---|
| Minimum iOS | **17.0** (Observation, `#Preview`, `@Environment(Type.self)`) | `[ASSUMPTION]` |
| Swift language mode | **5** (code not written for strict Swift 6 concurrency) | `[ASSUMPTION]` |
| Xcode | 16 recommended; 15 should work for the features used | `[ASSUMPTION]`, unverified |
| Remote services | Supabase REST for feature flags (anon key only) — **not provisioned** | `[ASSUMPTION]` |
| Info.plist keys expected | `UIAppFonts`, `UILaunchScreen`, `RADARFlagsURL`, `RADARFlagsAnonKey`, (later) `UIBackgroundModes` | not created |
| Build settings expected | `ASSETCATALOG_COMPILER_APPICON_NAME=AppIcon`, `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES=AppIconGlitch` | not created |

## 2. Bundled assets and licences

| Asset | Origin | Licence |
|---|---|---|
| Big Shoulders Display 700/800/900 | artifact `assets/big-shoulders-display-latin-*` (Latin subset) | believed SIL OFL 1.1 — **licence text not in repo** |
| Inter 400–700 | artifact `assets/inter-latin-wght-normal-*` (variable → static instances) | believed SIL OFL 1.1 — **not in repo** |
| Space Grotesk 500–700 | artifact `assets/space-grotesk-latin-wght-normal-*` (variable → static) | believed SIL OFL 1.1 — **not in repo** |
| Icons | redrawn paths from the artifact's own icon set | from the Phase 01 design |
| Demo data | fictional, from the artifact | — |
| Logo | traced from brand sheets you supplied (AI-generated) | yours |

The OFL can reserve font names, which may affect modified or instanced files (these were converted/instanced and renamed at the PostScript-name level only). I did not read the licence texts, so whether renaming is required is `[UNVERIFIED]` — check each family's licence before shipping.

## 3. Development tools (used on Linux, not shipped)

| Tool | Version | Used for |
|---|---|---|
| Node.js | v22.23.5 | `tools/*.js` |
| npm package `svgpath` | 2.6.0 | path arithmetic in `icons.js`, `brand.js` (installed in scratch `tools/npm`; no `package.json` in repo) |
| Playwright | 1.63.0 (global), Chromium preinstalled at `/opt/pw-browsers` | screenshots, SVG→PNG |
| prettier | 3.8.1 (via `npx`) | de-minifying the artifact bundle |
| Python | 3.13.18 | `tools/fonts.py`, ad-hoc analysis |
| fonttools | 4.68.0 | woff2 → TTF, variable-font instancing |
| brotli | 1.2.1 | woff2 decompression |
| Pillow | 12.3.0 | image crops, pixel scans, icon colour conversion |
| numpy | present (version not recorded) | ad-hoc IoU measurement |

Tool invocations (from the repo root; paths in angle brackets are inputs you must supply):
```
python3 tools/fonts.py   <artifact-dir containing assets/>  RADAR/Resources/Fonts
node    tools/extract.js <prettified app.js> <catalog.json> <vectors.json> <icons.json>
node    tools/icons.js   <icons.json> RADAR/DesignSystem/Icons/RadarIconPaths.swift     # expects ./npm/node_modules/svgpath
node    tools/brand.js   RADAR/DesignSystem/Brand docs/brand                           # needs svgpath
node    tools/glitch-icon.js 7 docs/brand/radar-app-icon-glitch.svg
```
(`extract.js` writes the unfiltered catalog; the committed `DemoCatalog.json` was then filtered by an inline Python snippet that is **not saved**: it drops tracks with `source == "local"`, the `local` artist and provider, removes `fileName`/`sizeMb`, drops null `why`, and adds `_notice`.)

## 4. Environment of this session

| | |
|---|---|
| OS | Ubuntu 24.04.5 LTS, Linux 6.18.44, x86_64 |
| Swift / Xcode | **not available** |
| Network | outbound HTTPS via a policy proxy; `swift.org` blocked (403) |
| Git / GitHub | repo cloned fresh; GitHub access via MCP tools (plus one read-only `gh api` search call) scoped to `Rashica07/RADAR` |
| Mac attached | none |

## 5. External references
- Phase 01 artifact (source of truth for design/behaviour): https://claude.ai/artifact/Js5gigTTofFCDwYCoWtWKW (version `1795423913-ab52`)
- Repository: https://github.com/Rashica07/RADAR
- PR #1 (merged): https://github.com/Rashica07/RADAR/pull/1
