# BUILD_STATUS

> **Native UI rebuild (2026-11-24) — supersedes Steps 3.2–3.6, 4-UI and 5 below:** on request, every custom UI layer was deleted (`DesignSystem/{Cards,Components,FX,Overlays,Player,Icons}`, `Layout/`, `Features/{Lab,Shell,Player}` and their tests) and rebuilt from system components. Kept: brand (fonts, mint/coral/charcoal palette, logo + splash, generative `ArtworkView`), all stores/services incl. `PlayerStore`/`PlayQueue`/`NowPlayingBridge`. New: `App/MainTabs` (system `TabView` + a `NavigationStack` per tab; on iOS 26.1+ the player is the tab bar's `tabViewBottomAccessory`, before that an overlay above the bar), `Features/Discover` (Discover, Trending, album/playlist/genre/artist pages), `Features/Search` (`.searchable`, recents, `ContentUnavailableView.search`), `Features/Library` (segmented Saved/Playlists/Recent/Offline/Files, `fileImporter`, swipe delete also purges the queue), `Features/Settings` (a `Form`; app icon rows; DEBUG flag toggles), `Features/Player` (system sheet, `Slider` seek and volume, SF Symbol transport, queue `List`), `Features/Common` (`TrackRowView` with native swipe actions, context menu, share link; `CoverTile`). `ToastCenter` now takes SF Symbol names. **90 tests pass** (the 64 tests of deleted UI went with it; stores, player logic, artwork, brand, flags remain). Driven on the iPhone 18 Pro simulator (iOS 27): Discover, play, mini player accessory, player sheet, Library. **Not verified:** Trending/Search/detail/Settings screens on screen, iPad/wide layouts, iOS 17 to 26.0 fallback path (mini player overlay position is a guess), Dynamic Type, VoiceOver, real-device audio.

> **Step 5 (2026-11-24) — `[VERIFIED]` on the iPhone 18 Pro simulator, compact layout only:** 154 tests pass (+17: `RouterTests`, `SwipeTests`, `DismissTests`). App shell: `RadarApp` now creates `AppRouter` and `PlayerStore` (resolves demo + imported tracks, local file URLs from `LocalLibrary`, `LibraryStore.addRecent` as `onPlayed`, `AVPlayerBackend`) plus `NowPlayingBridge`; `RootView` shows `TabShell` (the Layout Lab moved behind the Settings button, DEBUG). `TabShell`: four tabs in a `TabView` with its bar hidden (keeps each tab's scroll and stack alive) and our own `BottomNav` (mint bar glides between tabs, re-tap pops to root), `SideNav` (rail/sidebar), a `NavigationStack` per tab with its path held in `AppRouter`, `MiniPlayer` (tap or swipe up to expand, swipe sideways to skip, VoiceOver action), `TransportBar` + queue dock for wide windows, `ExpandedPlayer` (Now playing / Queue tabs, art swipe to skip, pull down to close, waveform scrubber, heart, 'Demo playback' label), `.toastHost`. Driven on the simulator: row tap starts demo playback, mini player appears, expands with the art, queue tab lists 10 tracks, pull-down closes, tab switch slides the bar. **The four tab pages are placeholders** (a playable chart list) until Step 6. **Not verified:** rail/sidebar/transport bar/dock (no iPad or wide simulator driven), mini-player and artwork swipe gestures, shared-element art transition mid-flight, scroll restoration after a layout change, Dynamic Type, VoiceOver, iOS 17; dock does not open by default at 1680 pt yet; `LocalLibrary.delete` does not call `PlayerStore.purge` yet (Step 6).

> **Step 4 (2026-11-23) — `[VERIFIED]` for logic, `[UNVERIFIED]` on a real device:** 137 tests pass (+26: `PlayQueueTests`, `PlayerStoreTests` with a fake audio backend, `AVPlayerBackendTests` playing a real generated WAV through `AVPlayer` on the simulator). `RADAR/Services/Player/`: `PlayQueue` (pure: play/playNext/enqueue/remove/clearUpcoming/jump, shuffle picks another track, repeat off/all/one, previous restarts after 3 s), `PlayerStore` (`@MainActor @Observable`: transport, seek, volume/mute, history once per track via `onPlayed`, errors for missing files, interruption and route-loss handling), `AudioBackend` seam + `AVPlayerBackend` (`.playback` session, 0.25 s progress, end-of-track, interruption, headphones unplugged), `NowPlayingBridge` (lock screen info, artwork, play/pause/next/prev/seek commands). `UIBackgroundModes: [audio]` added in `project.yml`. **Demo tracks have no audio**: a 250 ms clock advances progress and `isDemoPlayback` is true so the UI can say "Demo playback"; the lock screen is deliberately not claimed for silent demo tracks. Seen on the simulator in the DEBUG gallery: demo clock advances (0:05 after 5 s), scrubber follows. **Not verified:** background playback with the screen locked, lock-screen controls, interruption and headphone behaviour on a real iPhone; the store is not yet created at the app root or fed by `LocalLibrary` (Step 5); skipping unresolvable tracks in the middle of a queue just stops with an error.
> **Steps 3.2 + 3.3 rewritten natively (2026-11-23) — `[VERIFIED]`:** 111 tests pass (the removed ones tested CSS timing curves). Replaced the CSS-derived code, same public names so callers are unchanged. **FX** (`FX/FX.swift`, `FX/Film.metal`): cover film is one Metal `colorEffect` shader (grain + scanlines) instead of a CPU noise tile; glitch, channel-split burst, ping, equaliser and skeleton are `keyframeAnimator`s (repeating where they loop) instead of `TimelineView` + hand-written step functions; one `MotionGate` decides whether motion may run (FX switch, app Reduce Motion, system Reduce Motion). `CubicBezier`, `EQTiming`, `PingTiming`, `SkeletonTiming`, `GrainTile` are gone. **Components:** Dynamic-Type sizes (`RadarScale.Title`, `radarTitle`) replace the `vw` clamps and the `radarScreenWidth` environment; `RadarTabs` uses `.snappy`, scrolls the selection into view and ticks; buttons use a spring to 0.97 with a light tap and `@ScaledMetric` heights; `Sparkline` is a Swift Charts line; the blinking caret is a `phaseAnimator`. Checked on the iPhone 18 Pro simulator in the DEBUG gallery (film grain, EQ bars, tabs, flags, sparkline, buttons). **Not checked:** glitch/burst mid-animation, light theme film, Dynamic Type at accessibility sizes, VoiceOver, iOS 17, GPU cost of the shader on long lists. Grain strength lowered to 0.35 by eye; the artifact's value was 0.5.
> **Step 3.6 (2026-11-23) — `[VERIFIED]`:** 114 tests pass (+6 `ScrubTests`). `RADAR/DesignSystem/Player/`: `WaveformScrubber` (Canvas bars from seeded demo peaks `DemoCatalog.rawWaveform` or real `WaveformAnalyzer` peaks; touch tracks 1:1 from the first point, bars under the finger swell like a lens, time bubble above it, haptic tick per bar crossed, seek commits on release; skeleton while peaks load; VoiceOver adjustable with ±5 s steps and a spoken "1:23 of 3:45" value; Reduce Motion drops the lens), `ScrubTimes` (elapsed / remaining), and the pure, tested `ScrubMath`. Driven on the iPhone 18 Pro simulator in the DEBUG gallery: a drag moved progress to 2:44 of 3:34 and the played bars followed. **Not checked:** the bubble and lens mid-drag (no mid-gesture screenshot), real file peaks, VoiceOver, Dynamic Type, a mini-player strip variant (Step 4). Step 3 (design system) is complete apart from the Lead/Story cards, which move to the Home screen.
> **Step 3.5 (2026-11-23) — `[VERIFIED]`:** 108 tests pass (+4 `OverlaysTests`). `RADAR/DesignSystem/Overlays/`: `ToastHost` (`.toastHost(center)`; renders `ToastCenter.current`, enters at 0.97 scale + fade + short rise, swipe-down dismiss that follows the finger and springs back with release velocity, VoiceOver announcement, Reduce Motion = fade), native `.sheet` house style `radarSheet()` (system detents/drag physics), `SheetHeader`, `AboutDemoDataSheet` (own honest copy: sample data, simulated downloads, real imported files, nothing leaves the phone), `AddToPlaylistSheet` (plain data in, closures out), `NoSignalCard`. `ToastCenter` gained `dismiss()` and an injectable duration (tested: replace, dismiss, auto-dismiss, stale timer). Seen on the iPhone 18 Pro simulator: toast and demo-data sheet render; the playlist sheet and toast swipe gesture were not driven. The track context menu is `TrackRow`'s menu (3.4). Not yet wired into an app root (Step 5).
> **Step 3.4 (2026-11-23) — `[VERIFIED]`:** 104 tests pass (+7 `CardsTests`). Designed natively, not ported from the artifact's CSS (own decision, see memory `radar-native-not-css`). `RADAR/DesignSystem/Cards/`: `TrackRow` for `List` rows (native `swipeActions`: leading Play next, trailing Save with full swipe; `contextMenu` with a cover preview; VoiceOver custom actions; `@ScaledMetric` cover; EQ overlay + accent bar for the current track; heart `keyframeAnimator` + `sensoryFeedback`; download progress line), `TrackRowModel` (tested wording incl. VoiceOver label) and `TrackRowActions` closures (no store dependency until Step 4), `TrackRowSkeleton`, `Rail` (`scrollTargetBehavior(.viewAligned)`, `containerRelativeFrame`), `Tile`, `Poster` (rank numeral from CoreText glyph outlines via `GlyphOutline`), `Band`, `Mix` + `Collage` (custom `Layout`, pure `CollageFrames`). Checked on the iPhone 18 Pro simulator in the DEBUG gallery (rows, rail, poster, band, mix render). **Not done / unverified:** Lead and Story cards (deferred to the Home screen step), swipe/long-press gestures not driven on the simulator, Dynamic Type at accessibility sizes, VoiceOver traversal, scroll performance with many covers, iOS 17. Steps 3.2 and 3.3 are still CSS-derived.
> **Step 3.3 (2026-11-23) — `[VERIFIED]`:** 97 tests pass (+5 `ComponentsTests`). Type and layout components in `RADAR/DesignSystem/Components/`: fluid type scale (`RadarScale`: hero/display-l/-m clamps), `Readout`, `SectionHeader` (index, rule, readout/ping, action link, display title, sub, "Acquiring signal" caret), `RadarTabs` (sliding 3 pt ink via `matchedGeometryEffect`, counts, edge fade), button styles (`radar(.primary/.outline/.ghost, size:, block:)`, `radarCTA`, `radarTag`, `radarSlash`), `NewFlag`, `ExplicitFlag`, `DemoBadge`, `SourceTag`, `StatusLabel`, `MoveIndicator`/`ChartMove`, `Sparkline`, `.radarPage()`. Checked on the iPhone 18 Pro simulator (iOS 27.0) in the new DEBUG `DesignGalleryView` inside the Layout Lab: tabs switch and the ink slides, everything renders in dark and (via ImageRenderer) Paper. **Not checked:** Dynamic Type at accessibility sizes, VoiceOver traversal, iOS 17. `ImageRenderer` cannot draw ScrollViews, so scrolling widgets are verified on the simulator only. The app shell must supply `\.radarScreenWidth` (defaults to 393) for fluid titles.

> **Step 3.2 (2026-11-23) — `[VERIFIED]`:** 92 tests pass (+11 `FXTests`). FX layer ported from the artifact CSS (`RADAR/DesignSystem/FX/`): scanlines (5 %, 3 pt) + grain (`ArtFXOverlay`/`.artFX()`), RGB-split `GlitchText` (slice-a/b keyframes in hard steps), channel-split burst (`.fxBurst(key:)`, fx-3→1→2→1 with banded tear; `.fxSplit(_:)` static 2 pt), `PingBlip`, `EQBars` (6-step), `SkeletonBlock` (16-step scan), `CubicBezier` for the artifact's easings. All timing curves are pure functions tested against the CSS keyframes; rendering tests check pixels (channel split is the identity at dx 0, fringes land on the right side of an edge). **Approximations:** grain is a seeded noise tile (same size/recipe as the SVG `feTurbulence`, not pixel-identical); the tear is 14 deterministic bands, not `feDisplacementMap`. The channel split is exact for flat colours but shifts tones on gradients (observed; artwork is flat-filled so unaffected). Reduce Motion / Settings `fx` off are honoured through `\.radarFX` (the app shell must set it from `SettingsStore`). Not yet checked: performance of the burst on large art, light-theme global grain (`.app:before`).

> **Step 3.1 (2026-11-23) — `[VERIFIED]`:** 81 tests pass (+6 `ArtworkTests`). The artwork renderer (`RADAR/DesignSystem/Artwork/`: `ArtworkPrimitives`, `ArtworkView`) reproduces all 8 cover styles of the ORIGINAL artifact: 48 cases (8 styles × 6 seeds, varied palettes) generated by running the original generators in V8 (`tools/gen-art-vectors.js` → `RADARTests/Fixtures/ArtVectors.json`) match the Swift primitives to 1e-9. **`V8RandomSort` was wrong and is fixed:** real V8 sorts a 4-element array with plain binary insertion from index 1 (no run-detection pass); proven by 9 recorded V8 runs and by the `blocks` style now matching. Rendering checked by eye (all 8 styles, slice crop). Not yet checked: scrolling performance of many covers, Dynamic Type/VoiceOver on covers (covers are decorative unless given a label).

> **Step 2 (2026-11-23) — `[VERIFIED]`:** 75 tests pass (50 + 25 new: `ParityTests` 10, `StoresTests` 15; the store tests found and fixed a real bug: two playlists created in the same millisecond shared an id). The Swift port now matches the ORIGINAL artifact JS for FNV hash, PRNG, charts ×4 (ids, ranks, previous, delta), movers, emerging, rising, new releases, search ×6, related, sparkline, waveform and art specs (palette/style/seed). `DemoCatalog.shared` decodes (46 tracks / 23 artists / 10 albums / 8 playlists / 12 genres). Persistence (round-trip, coalescing, corrupt file, remove) and `LibraryStore`/`SettingsStore` rules are tested, **which also settles risk R1: `didSet` on `@Observable` properties fires and persists**. Still untested: `Format`, `V8RandomSort`, `DownloadCenter`, `LocalLibrary`/`WaveformAnalyzer`, `SupabaseFlagProvider.fetch`.

> **First build, 2026-11-23 (Phase 3 Step 1) — `[VERIFIED]` on this Mac:** Xcode 27.2, XcodeGen, iPhone 18 Pro simulator (iOS 27.0). `xcodegen generate` → `xcodebuild build` succeeded after **2 compile fixes** (R15-type isolation: `AppIconService.init` default argument evaluated off the main actor; `LocalLibrary.init` closure captured `self` before initialisation). **All 50 tests pass** (incl. `testBandsMatchTheJavaScriptReference`: Swift glitch == JS fixture). Observed in the simulator: splash fades out, fonts and `Theme/` colours resolve (R4 not an issue), logo renders, flag override reveals the icon picker, switching to the Glitch icon shows iOS's confirmation alert and the picker updates. **Also verified (Layout Lab, simulators, iOS 27.x):** Release build compiles (`#if DEBUG` gating OK); iPad Pro 13" shows 1032×1324 pt → rail, two-column, two-pane player, 4 grid columns; iPhone Duo **closed** shows a 382×644 pt window with a right safe-area inset of 84 pt (measured, not derived) → bottom bar. **Not yet checked:** Duo unfolded/half-open, iPad resize/multitasking, rotation, an iOS 17 runtime (none installed — only 26.5/27.0/27.1), performance, accessibility. Risks R1 (`didSet` on `@Observable`) and R2 did not break the build; R1's persistence behaviour is untested.

> **Update after PR #3 (merged `8372f91`, doc refresh in Phase 3 Step 0):** the repo now has a `@main` app (`RADAR/App`), a temporary Layout Lab, `project.yml` + `Config/*.xcconfig`, and Neon backend code. **Still true: nothing has been compiled or run.** Where this file says otherwise, the update notes below win; the original text is kept as the Phase 2 record.
> Preferred path now: **XcodeGen** — `cp Config/Local.xcconfig.example Config/Local.xcconfig`, set bundle id + team, `xcodegen generate`. Steps 2–6 of Path A below are replaced by this. Note `Local.xcconfig` is now included **last** in `Shared.xcconfig` so its values win.


## 1. Current state — one line
**Nothing has ever been built.** *(Updated after PR #3: the repo now has a `@main` app and an XcodeGen spec `project.yml` + `Config/*.xcconfig`, but no generated `.xcodeproj` and no CI; no compiler has ever been pointed at this code.)* Phase 2 originally had no project, `@main` or Info.plist. Build result: **not attempted**. Test result: **not attempted**.

`find` for `*.xcodeproj`, `*.pbxproj`, `Info.plist`, `Package.swift`, `*.xcconfig`, `*.yml`, `README*` returned nothing `[VERIFIED]`. There are no GitHub Actions workflows and PR #1 had 0 check runs `[VERIFIED]`.

## 2. Why it could not be built here `[VERIFIED]`
| Limitation | Evidence |
|---|---|
| Linux container (Ubuntu 24.04.5, kernel 6.18.44, x86_64) — Xcode/iOS SDKs are macOS-only | `uname -srm`, `/etc/os-release` |
| No `swift`, `swiftc`, `xcodebuild`, `xcrun` | `which` printed nothing |
| Swift.org toolchain download blocked by the sandbox network policy | `curl` → `HTTP/1.1 403 Forbidden (agent proxy: no rule or network setting allows this host)` |
| Ubuntu apt has no Swift package | `apt-get install swiftlang` → "Unable to locate package swiftlang" |
| No user Mac attached to the session | `list_computer_folders` returned no folders |

Even a Linux Swift toolchain would not have helped much: the code imports SwiftUI, UIKit, AVFoundation (iOS APIs), which Linux Swift does not provide.

## 3. What a first build needs (all `[NOT DONE]`)
1. An iOS app target named **`RADAR`** (tests use `@testable import RADAR`), deployment target **iOS 17.0** (confirmed requirement), built with **Xcode 27.1 or later** (see `docs/PLATFORM_REQUIREMENTS.md`; `project.yml` + `Config/` now exist), **Swift language mode 5**.
2. A `@main` `App` type (none exists; an app target with no entry point fails to link).
3. Info.plist keys: `UIAppFonts` (the 10 files in `RadarFont.bundledFiles`), `UILaunchScreen` → colour `LaunchBackground`, `RADARFlagsURL`, `RADARFlagsAnonKey` (from an `.xcconfig`), and — for the player later — `UIBackgroundModes: audio`.
4. Build settings: `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`, `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = AppIconGlitch`.
5. Resources in the app target: `Assets.xcassets`, `Fonts/*.ttf`, `DemoCatalog.json`.
6. A unit-test target `RADARTests` with `Fixtures/*.json` as resources.
7. A bundle identifier, team and signing config (**needs you**).

## 4. Known compilation risks (from re-reading the code; none confirmed)

Ordered by how likely I think they are to bite.

| ID | Where | Risk | Fix if it fails |
|---|---|---|---|
| R1 | `@Observable` classes with `didSet`: `DownloadCenter.swift:24` (`done`), `LibraryStore.swift:19–22` (4 props), `LocalLibrary.swift:20` (`tracks`), `SettingsStore.swift:52` (`settings`) | I am **not sure** property observers are supported/behave on `@Observable`-tracked stored properties. If unsupported: compile error or persistence silently never fires | drop the `didSet`s; call a `persist()` at the end of each mutating method (or mark the stored properties `@ObservationIgnored` and mirror them) |
| R2 | `DemoCatalog.chart(…)`: `.map(\.0)` on an array of tuples | tuple-element key paths may not compile in your Swift version | `.map { $0.0 }` |
| R3 | Swift 6 strict concurrency (if the project defaults to it): `RadarIconCutKey.defaultValue` (static `Color`), `Shapes` statics (`Path`), `LaunchSplash.finish()` capturing `onDone` in a `Task`, `RadarLogoReveal` capturing `onFinished`, `AppIconServiceTests.FakeApplier` | many Sendable/isolation diagnostics | set `SWIFT_VERSION = 5` first; fix properly later |
| R4 | `Color("Theme/bg")` etc. | if the `Theme` folder's "Provides Namespace" isn't honoured, colours silently render as clear/default (no compile error) | verify visually; rename sets to flat names or use generated asset symbols |
| R5 | `DemoCatalog.shared` | `fatalError` if `DemoCatalog.json` is missing or doesn't decode — any model/JSON mismatch crashes at first access | write the decode test first (TESTING §3) |
| R6 | `RadarIconPaths.swift` (693 lines, big `switch` of array literals of closures) | slow type-checking / "expression too complex" | split per icon into small functions |
| R7 | `RadarMarks.swift` Canvas code: `GraphicsContext.clip(to:)`, `.opacity`, `.translateBy`, `Shading.foreground`, `FillStyle(eoFill:)`; closures taking `inout GraphicsContext` | API-shape mistakes I couldn't compile-check | adjust to compiler messages |
| R8 | `RadarLogoReveal`: `TimelineView(.animation(minimumInterval: nil, paused: …))`; `.task(id:)` calling an `@MainActor` method | signature/isolation | adjust |
| R9 | `LocalLibrary` / `WaveformAnalyzer`: `CMBlockBufferGetDataPointer(…)` argument types, `withMemoryRebound`, `Task.detached` closure, `asset.load(.duration, .commonMetadata)` tuple destructuring | AVFoundation/CoreMedia API detail | adjust |
| R10 | `AppIconPickerSection`: `.accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)` | ternary type inference | split into `if/else` |
| R11 | Name collisions: `Settings`, `Format`, `Track`, `Provider`, `Genre`, `Country`, `Haptic`, `Shapes` (private) | clash with an imported framework type | rename (e.g., `AppSettings`) |
| R12 | `Format.longDate` | ICU may format `Monday, 23 November` vs the artifact's `Monday 23 November` | tweak format style |
| R13 | `#Preview` blocks in `RadarMarks.swift`, `RadarLogoReveal.swift` | need Xcode 15+ | — |
| R14 | Tests: `Fixture` resource lookup; `@testable import RADAR` module name; `testProviderIsNilWithoutConfiguration` | configuration, not code | see TESTING §2 |
| R15 | `Persistence`/stores: default arguments `= .shared` evaluated in `@MainActor` initialisers | isolation | pass explicitly |

**Behavioural (not compile) risks:** `V8RandomSort` correctness; `WaveformAnalyzer` blocks its actor during a long read; fonts may not resolve by PostScript name; the Supabase request has never reached a server; alternate-icon switching has never run.

## 5. Exact next steps

### Path A — on your Mac (fastest feedback)
1. `git fetch origin && git checkout <branch>` (or `main`; they contain the same code).
2. Xcode → **File ▸ New ▸ Project ▸ iOS App**: Product Name `RADAR`, Interface SwiftUI, Language Swift, **uncheck** tests, save at the repo root (creates `RADAR.xcodeproj`). Delete the template's `ContentView.swift`/`RADARApp.swift`/assets.
3. Add the existing `RADAR/` folder to the target (folder reference or synchronized group); confirm `Resources/DemoCatalog.json`, `Resources/Fonts/*.ttf` and `Resources/Assets.xcassets` are in **Copy Bundle Resources**.
4. Target ▸ Build Settings: deployment iOS 17.0; Swift Language Version **5**; set the two `ASSETCATALOG_*` keys from §3.
5. Target ▸ Info: add `UIAppFonts` (10 files), `UILaunchScreen` → `UIColorName = LaunchBackground`; add `RADARFlagsURL`/`RADARFlagsAnonKey` (empty is fine — provider is then nil).
6. Add a minimal `@main` app (temporary): a `WindowGroup { VStack { RadarLogoReveal(height: 60) } .background(Color.radarCharcoal) }` so the logo system can be seen.
7. **File ▸ New ▸ Target ▸ Unit Testing Bundle** `RADARTests`; add `RADARTests/*.swift`, `Support/`, and `Fixtures/*.json` (with *Copy Bundle Resources*).
8. ⌘B. Work through §4 top to bottom. Commit the project when green.
9. ⌘U. Expect the 50 tests; investigate any failure (most informative: `testBandsMatchTheJavaScriptReference`).
10. Run in the simulator: confirm the reveal animation, fonts, and that `AppIconPickerSection` (add it to a temporary view with injected stores) switches to the Glitch icon.

### Path B — CI on GitHub Actions (no Mac needed, costs minutes)
1. Write `project.yml` (XcodeGen) so the project is generated from text and reviewable on Linux. Proposal — **untested, not in the repo**:
```yaml
name: RADAR
options: { deploymentTarget: { iOS: "17.0" }, createIntermediateGroups: true }
settings:
  base:
    SWIFT_VERSION: "5.0"
    ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
    ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES: AppIconGlitch
targets:
  RADAR:
    type: application
    platform: iOS
    sources: [RADAR]
    info:
      path: RADAR/Info.plist          # generated; exclude from sources
      properties:
        UILaunchScreen: { UIColorName: LaunchBackground }
        UIAppFonts: [BigShouldersDisplay-Black.ttf, …]   # all 10, see RadarFont.bundledFiles
        RADARFlagsURL: ""
        RADARFlagsAnonKey: ""
    settings: { base: { PRODUCT_BUNDLE_IDENTIFIER: <YOUR.BUNDLE.ID> } }   # needs you
  RADARTests:
    type: bundle.unit-test
    platform: iOS
    sources: [RADARTests]
    dependencies: [{ target: RADAR }]
```
2. Add a minimal `@main` file (the app currently cannot link without one).
3. `.github/workflows/ios.yml` on `macos-latest`: `brew install xcodegen && xcodegen && xcodebuild test -scheme RADAR -destination 'platform=iOS Simulator,name=<an installed iPhone>' CODE_SIGNING_ALLOWED=NO | xcpretty`. Pick the Xcode version explicitly.
4. Push; read the log; fix compile errors; repeat. Each loop costs macOS minutes — **this repo is private, and I understand GitHub bills macOS minutes at a multiple of Linux (verify current pricing) — needs your approval.**
5. Upload `.xcresult` as an artifact so failures can be read.

### Either path — exit criteria for "build is working"
- `xcodebuild build` exits 0 with the Swift 5 mode and zero errors.
- All 29 existing tests pass **or** each failure is explained (a test bug vs. a code bug).
- The logo reveal and the alternate-icon switch have been seen on a simulator or device.
