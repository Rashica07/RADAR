# BUILD_STATUS

> **First build, 2026-11-23 (Phase 3 Step 1) — `[VERIFIED]` on this Mac:** Xcode 27.2, XcodeGen, iPhone 18 Pro simulator (iOS 27.0). `xcodegen generate` → `xcodebuild build` succeeded after **2 compile fixes** (R15-type isolation: `AppIconService.init` default argument evaluated off the main actor; `LocalLibrary.init` closure captured `self` before initialisation). **All 50 tests pass** (incl. `testBandsMatchTheJavaScriptReference`: Swift glitch == JS fixture). Observed in the simulator: splash fades out, fonts and `Theme/` colours resolve (R4 not an issue), logo renders, flag override reveals the icon picker, switching to the Glitch icon shows iOS's confirmation alert and the picker updates. **Not yet checked:** iPhone Duo/iPad layouts, iOS 17 device/simulator, release configuration, performance, accessibility. Risks R1 (`didSet` on `@Observable`) and R2 did not break the build; R1's persistence behaviour is untested.

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
