# TESTING

> **Step 3.6 (2026-11-23) — `[VERIFIED]`:** 114 tests pass (+6 `ScrubTests`). `RADAR/DesignSystem/Player/`: `WaveformScrubber` (Canvas bars from seeded demo peaks `DemoCatalog.rawWaveform` or real `WaveformAnalyzer` peaks; touch tracks 1:1 from the first point, bars under the finger swell like a lens, time bubble above it, haptic tick per bar crossed, seek commits on release; skeleton while peaks load; VoiceOver adjustable with ±5 s steps and a spoken "1:23 of 3:45" value; Reduce Motion drops the lens), `ScrubTimes` (elapsed / remaining), and the pure, tested `ScrubMath`. Driven on the iPhone 18 Pro simulator in the DEBUG gallery: a drag moved progress to 2:44 of 3:34 and the played bars followed. **Not checked:** the bubble and lens mid-drag (no mid-gesture screenshot), real file peaks, VoiceOver, Dynamic Type, a mini-player strip variant (Step 4). Step 3 (design system) is complete apart from the Lead/Story cards, which move to the Home screen.
> **Step 3.5 (2026-11-23) — `[VERIFIED]`:** 108 tests pass (+4 `OverlaysTests`). `RADAR/DesignSystem/Overlays/`: `ToastHost` (`.toastHost(center)`; renders `ToastCenter.current`, enters at 0.97 scale + fade + short rise, swipe-down dismiss that follows the finger and springs back with release velocity, VoiceOver announcement, Reduce Motion = fade), native `.sheet` house style `radarSheet()` (system detents/drag physics), `SheetHeader`, `AboutDemoDataSheet` (own honest copy: sample data, simulated downloads, real imported files, nothing leaves the phone), `AddToPlaylistSheet` (plain data in, closures out), `NoSignalCard`. `ToastCenter` gained `dismiss()` and an injectable duration (tested: replace, dismiss, auto-dismiss, stale timer). Seen on the iPhone 18 Pro simulator: toast and demo-data sheet render; the playlist sheet and toast swipe gesture were not driven. The track context menu is `TrackRow`'s menu (3.4). Not yet wired into an app root (Step 5).
> **Step 3.4 (2026-11-23) — `[VERIFIED]`:** 104 tests pass (+7 `CardsTests`). Designed natively, not ported from the artifact's CSS (own decision, see memory `radar-native-not-css`). `RADAR/DesignSystem/Cards/`: `TrackRow` for `List` rows (native `swipeActions`: leading Play next, trailing Save with full swipe; `contextMenu` with a cover preview; VoiceOver custom actions; `@ScaledMetric` cover; EQ overlay + accent bar for the current track; heart `keyframeAnimator` + `sensoryFeedback`; download progress line), `TrackRowModel` (tested wording incl. VoiceOver label) and `TrackRowActions` closures (no store dependency until Step 4), `TrackRowSkeleton`, `Rail` (`scrollTargetBehavior(.viewAligned)`, `containerRelativeFrame`), `Tile`, `Poster` (rank numeral from CoreText glyph outlines via `GlyphOutline`), `Band`, `Mix` + `Collage` (custom `Layout`, pure `CollageFrames`). Checked on the iPhone 18 Pro simulator in the DEBUG gallery (rows, rail, poster, band, mix render). **Not done / unverified:** Lead and Story cards (deferred to the Home screen step), swipe/long-press gestures not driven on the simulator, Dynamic Type at accessibility sizes, VoiceOver traversal, scroll performance with many covers, iOS 17. Steps 3.2 and 3.3 are still CSS-derived.
> **Step 3.3 (2026-11-23) — `[VERIFIED]`:** 97 tests pass (+5 `ComponentsTests`). Type and layout components in `RADAR/DesignSystem/Components/`: fluid type scale (`RadarScale`: hero/display-l/-m clamps), `Readout`, `SectionHeader` (index, rule, readout/ping, action link, display title, sub, "Acquiring signal" caret), `RadarTabs` (sliding 3 pt ink via `matchedGeometryEffect`, counts, edge fade), button styles (`radar(.primary/.outline/.ghost, size:, block:)`, `radarCTA`, `radarTag`, `radarSlash`), `NewFlag`, `ExplicitFlag`, `DemoBadge`, `SourceTag`, `StatusLabel`, `MoveIndicator`/`ChartMove`, `Sparkline`, `.radarPage()`. Checked on the iPhone 18 Pro simulator (iOS 27.0) in the new DEBUG `DesignGalleryView` inside the Layout Lab: tabs switch and the ink slides, everything renders in dark and (via ImageRenderer) Paper. **Not checked:** Dynamic Type at accessibility sizes, VoiceOver traversal, iOS 17. `ImageRenderer` cannot draw ScrollViews, so scrolling widgets are verified on the simulator only. The app shell must supply `\.radarScreenWidth` (defaults to 393) for fluid titles.

> **Step 3.2 (2026-11-23) — `[VERIFIED]`:** 92 tests pass (+11 `FXTests`). FX layer ported from the artifact CSS (`RADAR/DesignSystem/FX/`): scanlines (5 %, 3 pt) + grain (`ArtFXOverlay`/`.artFX()`), RGB-split `GlitchText` (slice-a/b keyframes in hard steps), channel-split burst (`.fxBurst(key:)`, fx-3→1→2→1 with banded tear; `.fxSplit(_:)` static 2 pt), `PingBlip`, `EQBars` (6-step), `SkeletonBlock` (16-step scan), `CubicBezier` for the artifact's easings. All timing curves are pure functions tested against the CSS keyframes; rendering tests check pixels (channel split is the identity at dx 0, fringes land on the right side of an edge). **Approximations:** grain is a seeded noise tile (same size/recipe as the SVG `feTurbulence`, not pixel-identical); the tear is 14 deterministic bands, not `feDisplacementMap`. The channel split is exact for flat colours but shifts tones on gradients (observed; artwork is flat-filled so unaffected). Reduce Motion / Settings `fx` off are honoured through `\.radarFX` (the app shell must set it from `SettingsStore`). Not yet checked: performance of the burst on large art, light-theme global grain (`.app:before`).

> **Step 3.1 (2026-11-23) — `[VERIFIED]`:** 81 tests pass (+6 `ArtworkTests`). The artwork renderer (`RADAR/DesignSystem/Artwork/`: `ArtworkPrimitives`, `ArtworkView`) reproduces all 8 cover styles of the ORIGINAL artifact: 48 cases (8 styles × 6 seeds, varied palettes) generated by running the original generators in V8 (`tools/gen-art-vectors.js` → `RADARTests/Fixtures/ArtVectors.json`) match the Swift primitives to 1e-9. **`V8RandomSort` was wrong and is fixed:** real V8 sorts a 4-element array with plain binary insertion from index 1 (no run-detection pass); proven by 9 recorded V8 runs and by the `blocks` style now matching. Rendering checked by eye (all 8 styles, slice crop). Not yet checked: scrolling performance of many covers, Dynamic Type/VoiceOver on covers (covers are decorative unless given a label).

> **Step 2 (2026-11-23) — `[VERIFIED]`:** 75 tests pass (50 + 25 new: `ParityTests` 10, `StoresTests` 15; the store tests found and fixed a real bug: two playlists created in the same millisecond shared an id). The Swift port now matches the ORIGINAL artifact JS for FNV hash, PRNG, charts ×4 (ids, ranks, previous, delta), movers, emerging, rising, new releases, search ×6, related, sparkline, waveform and art specs (palette/style/seed). `DemoCatalog.shared` decodes (46 tracks / 23 artists / 10 albums / 8 playlists / 12 genres). Persistence (round-trip, coalescing, corrupt file, remove) and `LibraryStore`/`SettingsStore` rules are tested, **which also settles risk R1: `didSet` on `@Observable` properties fires and persists**. Still untested: `Format`, `V8RandomSort`, `DownloadCenter`, `LocalLibrary`/`WaveformAnalyzer`, `SupabaseFlagProvider.fetch`.

> **First build, 2026-11-23 (Phase 3 Step 1) — `[VERIFIED]` on this Mac:** Xcode 27.2, XcodeGen, iPhone 18 Pro simulator (iOS 27.0). `xcodegen generate` → `xcodebuild build` succeeded after **2 compile fixes** (R15-type isolation: `AppIconService.init` default argument evaluated off the main actor; `LocalLibrary.init` closure captured `self` before initialisation). **All 50 tests pass** (incl. `testBandsMatchTheJavaScriptReference`: Swift glitch == JS fixture). Observed in the simulator: splash fades out, fonts and `Theme/` colours resolve (R4 not an issue), logo renders, flag override reveals the icon picker, switching to the Glitch icon shows iOS's confirmation alert and the picker updates. **Not yet checked:** iPhone Duo/iPad layouts, iOS 17 device/simulator, release configuration, performance, accessibility. Risks R1 (`didSet` on `@Observable`) and R2 did not break the build; R1's persistence behaviour is untested.

> **Update after PR #3 (merged `8372f91`, doc refresh in Phase 3 Step 0):** the repo now has a `@main` app (`RADAR/App`), a temporary Layout Lab, `project.yml` + `Config/*.xcconfig`, and Neon backend code. **Still true: nothing has been compiled or run.** Where this file says otherwise, the update notes below win; the original text is kept as the Phase 2 record.


**Bottom line: 0 of 50 XCTest methods have ever run (29 Phase 2 + `RadarLayoutTests` 17 + `BackendConfigTests` 4 from PR #3). No Swift code has been compiled.** The only things actually executed in Phase 2 were Node/Python/shell/browser checks, listed in §1. Everything in §2 is *written, not run*.

Tags: `[VERIFIED]` = an executed command produced the cited result · `[UNVERIFIED]` = not executed · `[NOT DONE]`.

## 1. Checks that were actually executed

| ID | What | How | Result |
|---|---|---|---|
| V1 | Artifact retrieved | Artifact tool `read` of the page + 9 published files | `[VERIFIED]` 20 files listed; JS/CSS/fonts/index.html/favicon saved. sha256 of JS/CSS recorded |
| V2 | Bundle prettified; routes enumerated | prettier 3.8.1; grep of `path:` | `[VERIFIED]` 24,752 lines; 11 routes (`/`, `/trending`, `/search`, `/library`, `/track/:id`, `/artist/:id`, `/playlist/:id`, `/album/:id`, `/settings`, `/art`, `*`) |
| V3 | Reference screenshots | Playwright + Chromium, 393×852, DPR 1, patched local copy (hash-based MemoryRouter) | `[VERIFIED]` 26 PNGs written; Discover, Trending, Track, Library, Search results, Settings, Artist, Player viewed. `queue.png` = duplicate of `player.png` (click failed); `context.png` not inspected |
| V4 | Data + test-vector extraction | `node tools/extract.js` | `[VERIFIED]` "tracks 51 artists 24 icons 44"; filtered catalog = 23 artists / 46 tracks / 10 albums / 8 playlists / 12 genres |
| V5 | Fonts | `python3 tools/fonts.py` | `[VERIFIED]` 10 TTFs; PostScript names + weight classes read back; glyphs `è á ’ “ · — …` present in Inter-SemiBold, `’ è #` in Big Shoulders Black |
| V6 | Icons | `node tools/icons.js` | `[VERIFIED]` "ok 44"; 4 icon names used in Swift exist in the generated enum |
| V7 | Logo fit | overlay renders + ad-hoc IoU script (numpy/Pillow, 1:1, luminance > 100, shifts ±8 px) | `[VERIFIED]` symbol IoU **0.957** @ (0,0); wordmark IoU **0.884** @ (+8,+1) |
| V8 | Glitch look | rendered seeds 3, 7, 11, 19, 23, 42 via Chromium; inspected | `[VERIFIED]` visually: crisp streaks off top bar and leg. Seed 7 chosen. Icon PNGs generated and viewed |
| V9 | JS twin properties | `node` one-liners over `tools/glitch.js` | `[VERIFIED]` seed 7 and 99: bands tile the height exactly (sum 207.000); seed 7, `maxLength 80`: peaks top 74.7 / mid 0.0 / leg 51.4; `maxLength 79.42`: 74.1 / 0.0 / 51.1; 48 bands, 20 active |
| V10 | JSON validity | `python3 json.load` over 30 files | `[VERIFIED]` 30 valid, 0 invalid |
| V11 | Swift structural sanity | script: balanced `() [] {}` ignoring strings/comments, 27 Swift files | `[VERIFIED]` 0 unbalanced. **This is a weak check** — it proves nothing about types or semantics |
| V12 | Git / PR state | git commands; GitHub MCP | `[VERIFIED]` see `GIT_STATE.md`; PR #1 merged; 0 check runs |
| V13 | Toolchain availability | `which swift swiftc xcodebuild`; `apt-cache`; `curl` to swift.org | `[VERIFIED]` none installed; swift.org blocked by the sandbox proxy (HTTP 403); apt has no `swiftlang` package |

## 2. Tests written (never run)

Module imported as `@testable import RADAR`; run with Xcode ⌘U or `xcodebuild test`.

### `GlitchTests` — `RADARTests/GlitchTests.swift` (5)
| Test | Asserts | Backed by |
|---|---|---|
| `testBandsMatchTheJavaScriptReference` | `GlitchSpec.bands` == `GlitchVectors.json` for 4 cases within 1e-9 (count, `y`, `h`, `length`) | fixture from `tools/glitch.js` (V9 ran the JS, not this test) |
| `testNoGlitchAmountProducesNoTrails` | `amount: 0` → all lengths 0 | by inspection |
| `testBandsTileTheWholeHeightWithoutOverlap` | contiguous, sums to 207 | JS equivalent verified (V9) |
| `testLongestTrailsSitAtTheTopBarAndTheLeg` | seed 7: peak(0.05–0.35) > peak(0.45–0.65) and peak(0.8–1.0) > mid | JS equivalent verified (V9) |
| `testTrailOpacityFadesOut` | alphas non-increasing, within 0…1 | values computed in Node (DESIGN_SPEC §7) |

### `RadarRevealTests` — same file (6)
`testOpensFullyGlitchedAndColorless` (t=0 → glitch 1, tint 0) · `testEndsOnTheCleanLogo` (t ≥ 0.95 → `.clean`) · `testStreaksAreGoneBeforeTheColorFinishesResolving` (t=0.78 → glitch 0) · `testColorResolvesMonotonically` (101 samples, tint non-decreasing in 0…1) · `testEveryStepRerollsTheStreakLayout` (10 distinct seeds) · `testNegativeTimeBehavesLikeTheStart`. Expected values were cross-checked by re-implementing the timeline in Node (DESIGN_SPEC §8), not by running Swift.

### `FeatureFlagsTests` — `RADARTests/FeatureFlagsTests.swift` (8)
Defaults off · remote enables · missing key stays off · override beats remote and can be cleared · **failed refresh keeps last values** (writes via one `PersistenceController`, flushes it, then loads through another on the same temp directory — this was a bug in the first draft, fixed during review) · persistence across instances · throttle · provider nil without Info.plist keys (**assumes the *test* bundle has no `RADARFlagsURL`/`RADARFlagsAnonKey`**).

### `AppIconServiceTests` — same file (10)
Picker hidden while flag off · revealed when on · glitch stays listed while active even if flag off · switching back hides it again · selecting passes `"AppIconGlitch"` · standard passes `nil` · same icon is a no-op · failure leaves `current` · hidden when device can't switch · name mapping (unknown name → standard).

### Support
`Fixture.data(_:)` — finds JSON in the test bundle root or `Fixtures/` (works only if the fixtures are added to the test target's resources).

### Fragilities to expect
- Fixtures must be in the test target's *Copy Bundle Resources*.
- Tests create temp directories under `NSTemporaryDirectory()` and never delete them.
- `FakeApplier` is a non-isolated class conforming to a `@MainActor` protocol; fine in Swift 5 mode, may warn in Swift 6.
- `PersistenceController.flush()` blocks on its own queue; tests that forget to flush will race.

## 3. Tests that do not exist yet (`[NOT DONE]`)

| Area | Why it matters | Fixture available? |
|---|---|---|
| **`DemoCatalog` parity** (hash, PRNG, charts ×4, movers, emerging, rising, newReleases, search ×6, related, spark, art, wave) | proves the port is faithful to the original JS | **yes — `ParityVectors.json`, unused** |
| `SeededRandom` / `SeededHash` unit tests | foundation of everything seeded | yes (`hash`, `prng` keys) |
| `V8RandomSort` | emulation of V8 TimSort is unproven; needs JS-generated permutations | **no** |
| `Format` helpers | copy parity (esp. `longDate`) | no |
| `PersistenceController` round-trip / coalescing / corrupt file | data-loss risk | no |
| `LibraryStore`, `SettingsStore`, `DownloadCenter` | state rules (caps, defaults, reset) | no |
| `LocalLibrary.importFiles` + `AudioMetadata` + `WaveformAnalyzer` | real AVFoundation path; needs small audio fixtures | no |
| `SupabaseFlagProvider.fetch` via `URLProtocol` stub | request shape, headers, error mapping | no |
| `DemoCatalog.shared` decodes `DemoCatalog.json` | a mismatch crashes the app at first access | file exists |
| View/snapshot tests for `RadarLogoCanvas` at glitch 0/0.5/1 | verify Canvas output vs the SVG | SVGs exist |
| UI tests (navigation, player, gestures) | Phase 02 brief §7 | n/a — no UI |
| Accessibility audit, Dynamic Type, Reduce Motion, VoiceOver | brief §6 | n/a |
| Performance (scroll, artwork cache, memory) | brief §6 | n/a |
| Device-size matrix (SE, standard, Max) | brief §7 | n/a |
| Screenshot comparison vs artifact | brief §7 | reference shots exist (zip) |

## 4. Verified behaviour vs. assumptions

| Claim | Status |
|---|---|
| Demo data extracted correctly (counts, content) | `[VERIFIED]` counts; `[UNVERIFIED]` Swift decodes it |
| Fonts have the intended names and weights | `[VERIFIED]` file metadata; `[UNVERIFIED]` iOS loads them |
| Icons paths convert faithfully | `[UNVERIFIED]` (never rendered natively) |
| Symbol/wordmark match the sheet | `[VERIFIED]` 0.957 / 0.884 IoU |
| JS and Swift glitch generators agree | `[UNVERIFIED]` — the test that would show it has not run; algorithm text compared by eye |
| Glitch looks like the sheet | `[VERIFIED]` for the *JS-rendered icon*; `[UNVERIFIED]` for the Swift `Canvas` output |
| Reveal timeline correct | `[VERIFIED]` arithmetic in Node; `[UNVERIFIED]` Swift |
| Alternate icon switching works | `[UNVERIFIED]` (needs simulator/device + build settings) |
| Flags fetch from Supabase | `[UNVERIFIED]`; no backend exists |
| Local import + waveform work | `[UNVERIFIED]` |
| Persistence survives relaunch | `[UNVERIFIED]` |

## 5. How to run once a project exists
```
xcodebuild test -project RADAR.xcodeproj -scheme RADAR \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```
(`[UNVERIFIED]` command; simulator name depends on the installed runtimes.) First expectation: compile errors, not test failures — see `BUILD_STATUS.md`.
