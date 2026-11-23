# PLATFORM_REQUIREMENTS

**The single source of truth for what RADAR must run on and how it adapts.** Written 2026-11-23.
Tags: `[VERIFIED]` an executed command or a fetched primary source backs it (cited) · `[DERIVED]` computed from verified numbers by an assumption stated beside it · `[UNVERIFIED]` not checked · `[ASSUMPTION]` my decision, may be wrong · `[NOT DONE]` · `[NEEDS YOU]`.

> **Honest status.** The requirements are now recorded, the project configuration reflects them, and the code that can be written without a compiler is written. **No layout has been built into a real screen, and nothing has been tested on any simulator or device** — this environment is Linux with no Xcode, no simulator, and no iOS 27 runtime. Per your rule, **device support is NOT complete** and nothing here may be read as saying otherwise. §9 is the test plan for you/CI to execute.

---

## 1. Requirements (as given)

| ID | Requirement |
|---|---|
| R1 | **Minimum deployment target: iOS 17.0.** Do not raise it because development/testing happens on iOS 27. |
| R2 | Your **only manual testing environment is iOS 27.** Design and optimise the experience for iOS 27. |
| R3 | Maintain **source compatibility with iOS 17**. Check API availability before using newer frameworks, modifiers or system features; provide iOS 17 fallbacks. |
| R4 | **Document every feature that cannot behave identically on iOS 17** (§11). |
| R5 | All project configuration, build settings and documentation must reflect R1–R4 (§8). |
| R6 | First-class native layouts for: standard iPhones (iOS 17 min) · **iPhone Duo closed** (5.4″ outer) · **iPhone Duo unfolded** (7.6″ inner) · **13″ iPad Air** · **13″ iPad Pro**. |
| R7 | Duo: closed and unfolded are **separate layout environments**; adapt live on open/close; **preserve navigation, playback state, queue and scroll position**; use the extra width intelligently; **don't just scale up the closed UI**. |
| R8 | iPad: full native support; portrait + landscape; adaptive sidebar/navigation; multi-column discovery + library; **persistent expanded player where appropriate**; no over-stretched content; **iPad multitasking and changing window sizes**. |
| R9 | Use SwiftUI adaptive layouts and size classes; **container-based decisions, no device identifiers**; respect safe areas, insets, Dynamic Type; **no fixed screen dimensions or absolute positioning**; keep the RADAR design language on every device. |
| R10 | Test every layout in: iPhone standard · Duo closed · Duo unfolded · 13″ iPad portrait · 13″ iPad landscape. |
| R11 | **Done means:** every layout inspected, and navigation, playback, resizing and transitions tested. |

---

## 2. Platform facts I verified (primary sources, retrieved 2026-11-23)

My own knowledge of Apple platforms predates iPhone Duo and iOS 27, so everything below comes from fetched pages, not memory.

| # | Fact | Source |
|---|---|---|
| F1 | **iPhone Duo exists** (announced Sept 2026): 7.6″ inner folding display, 5.4″ outer display; ships with **iOS 27**. | apple.com/newsroom/2026/09/apple-unveils-iphone-duo, apple.com/iphone-duo/specs |
| F2 | Inner display **1878 × 2670 px @ 430 ppi**; outer display **1398 × 2034 px @ 460 ppi**. Open: 164.6 × 117.8 mm; closed: 84.1 × 117.8 mm. | apple.com/iphone-duo/specs |
| F3 | **Apple does not publish iPhone Duo point sizes** (its HIG "Layout" page has no Duo/iPad/iPhone table; the Duo pages give pixels only). | developer.apple.com/design/human-interface-guidelines/layout (queried) |
| F4 | Apps built with the **iOS 26 SDK or earlier** are letterboxed on Duo; **iOS 27 SDK**: resize to fill most of the inner display but avoid the status-bar area on the right edge; **iOS 27.1 SDK or later**: edge-to-edge on both displays, with **toolbars/tab bars vertical** under the status bar. | developer.apple.com/iphone-duo/prepare |
| F5 | **Any combination of size classes** is possible on an iPhone (Duo, iPhone Mirroring). **"Regular width" no longer means iPad.** Don't choose layouts by idiom, device orientation, `UIScreen.main`, or known device sizes. HIG: *compact width for the outer display, regular width for the inner display.* | developer.apple.com/iphone-duo/prepare; HIG "Designing for iPhone Duo" |
| F6 | The app's size changes on every fold/unfold and doesn't always equal the screen size; re-read size on change (SwiftUI: `GeometryReader`/`onGeometryChange`). | developer.apple.com/iphone-duo/prepare |
| F7 | **`ArrangementView`, `GeometryProxy.reservedRegions(kind:options:layoutDirectionBehavior:)` and `EnvironmentValues.toolbarVerticalEdge` are all "iOS 27.1+".** `ArrangementView` must not sit inside a scroll view / `NavigationSplitView` / grid, nor contain a `NavigationSplitView` / `TabView`. `toolbarVerticalEdge` is `HorizontalEdge?` (nil = no vertical bar). | their API reference pages |
| F8 | System bars are presented **vertically** on the outer display (closed) and in the leading/trailing position on the inner display when open (landscape); the inner display in portrait keeps horizontal bars. **Custom bars don't adapt automatically**; Apple says use `toolbarVerticalEdge` to position custom bars. | developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo |
| F9 | Poses: closed, tent, open-wide, partially folded (a **division** reserved region at the fold), open-tall, laptop. Cameras are **occlusion** regions. HIG: keep state and controls consistent across poses; avoid extreme layout changes while folding; prefer **even column counts** in grids. | same + HIG |
| F10 | Test tools: **iPhone Duo simulator in Xcode 27.1** (Device Hub), the **resizable iOS simulator** in Device Hub, **iPhone Mirroring on macOS 27**. The Duo simulator is "the best way to test the full native experience". | developer.apple.com/iphone-duo/prepare |
| F11 | Xcode 27.2: Device Hub accepts input to **iOS 17** simulators; **VoiceOver and the Accessibility Inspector cannot convey screen content on iPhone Duo in Device Hub**; Duo screenshots/recordings may be black for minutes after boot; modifier keys can stop working when switching displays; Device Hub can't set text size for iOS ≤ 18 devices. Xcode 27.1: on-device debugging supports iOS 17+; StandBy and most app extensions are unavailable in the Duo simulator runtime. | Xcode 27.1 / 27.2 release notes |
| F12 | iPad Pro 13″ (M4 and M5): **2752 × 2064 px @ 264 ppi**. | support.apple.com/en-us/119891, /125407 |
| F13 | The approved artifact's CSS breakpoints (**executed**: `grep` over the flattened CSS): `720, 900, 1000, 1100, 1280` pt (CSS px). | the artifact bundle's CSS (flattened, then grepped) |
| F14 | Artifact behaviour measured in Chromium (**executed**, DOM geometry): 466×678 → bottom nav (58) + mini-player (82); 890×626, 1032×1376 → 76-pt rail + 88-pt **transport bar** (no bottom nav, no mini-player); 1376×1032 → 244-pt sidebar + transport bar; **queue dock absent** until toggled (open by default only at ≥ 1680). | `docs/reference/artifact-wide/` + `tools/reference/shoot_wide.js` |

**Not verified:** Duo *point* sizes (F3); the iPad Air 13″ resolution (the search returned only older Air generations); the *minimum deployment target Xcode 27.x accepts* (not stated in the release notes I read — confirm that 17.0 is accepted when you create the project); minimum OS versions of `toolbarVerticalBehavior`, `presentationPlacement`, `axisBehavior`, `visibilityPriority`, `ToolbarOverflowMenu`, `topBarPinnedTrailing`, `backgroundExtensionEffect`, `onGeometryChange` (named in Apple's text, availability not fetched).

---

## 3. Corrections to what I wrote earlier

| Earlier statement (Phase 2 handoff) | Now |
|---|---|
| "Minimum iOS 17.0 `[ASSUMPTION]`" | **Confirmed requirement (R1).** Handoff files patched. |
| "Xcode 16 recommended; 15 should work" | **Xcode 27.1 or later** — the Duo simulator is a 27.1 feature and the Duo layout APIs are iOS 27.1. |
| "`navigationTransition(.zoom)` on iOS 18 where available" (PHASE_3_PLAN) | Still gated; **must be fallback-designed** (§5). |
| Implicit assumption: regular width = iPad, compact = phone | **Wrong on iOS 27 (F5).** Layout uses container size only. |
| "Persistent queue dock at ≥ 1280" (my first profile) | **Wrong.** The artifact has a persistent **transport bar** at ≥ 720 and a *toggleable* dock at ≥ 1280 (open by default ≥ 1680) — profile fixed (F14). |
| "iOS 27" as one target | `[NEEDS YOU]` Duo layout APIs need **27.1+**. Which release do your devices/simulators run? (§12 Q1) |

The Phase 2 zip (`RADAR-PHASE-2-HANDOFF.zip`) is a **frozen snapshot** and still contains the old wording; the Markdown under `docs/handoff/phase-2/` was patched.

---

## 4. Compatibility policy

**Deployment target = 17.0. Base SDK = the one in Xcode 27.1 or later. Test OS = iOS 27.**

1. **Never raise the deployment target to avoid writing a fallback.** (R1)
2. **Every API introduced after iOS 17 needs** `if #available(iOS N, *)` / `@available`, **and an else-branch that is a real iOS 17 implementation**, not an empty view.
3. **Enforcement, in layers**
   | Layer | What it catches | Status |
   |---|---|---|
   | **Compiler** (`IPHONEOS_DEPLOYMENT_TARGET = 17.0`) | any unguarded newer API is a hard error | `[NOT RUN]` — set in `Config/Shared.xcconfig`; needs Xcode |
   | `tools/check-availability.py` | denylist of newer-than-17 names used without a guard; Apple's Duo anti-patterns (`UIScreen.main`, device orientation, idiom checks, device models) | `[VERIFIED]` runs; repo passes: 32 files, 0 errors; its self-test catches 4/4 planted violations |
   | iOS 17 simulator run | behavioural differences the compiler can't see | `[NOT DONE]` — Xcode 27.2 Device Hub supports iOS 17 sims (F11); **you test only iOS 27**, so this needs CI or you (§9.4) |
4. **Where fallbacks live:** a small `Layout/` + `Availability` layer wraps each newer API once, so screens never contain `#available` (`[NOT DONE]` until a compiler exists to check the wrappers).
5. **The lint is a lint, not proof.** Its newer-than-17 list for iOS 18/26 names is from my memory (`[UNVERIFIED]`); the iOS 27.1 names are verified (F7).

---

## 5. API availability register

| API | Min OS | Provenance | RADAR use | iOS 17 fallback | Same behaviour? |
|---|---|---|---|---|---|
| `GeometryReader`, size classes, `@Environment(\.displayScale)`, `ViewThatFits` | iOS 13–16 | known | **in use** (`RadarAdaptiveContainer`) | — | yes |
| Observation (`@Observable`), `@Environment(Type.self)`, `#Preview`, 2-param `onChange` | iOS 17 | known | in use | — | yes |
| `ArrangementView` (+ `arrangementViewStyle`) | **27.1** | `[VERIFIED]` F7 | planned for split/overlay on fold poses | `RadarAdaptiveContainer` + `HStack`/`VStack` split | **no** — no fold on iOS 17 hardware; fallback has no fold awareness |
| `GeometryProxy.reservedRegions` / `ReservedRegion` | **27.1** | `[VERIFIED]` F7 | keep controls out of the fold/camera | none needed: return `[]` | n/a (iOS 17 devices have none) |
| `EnvironmentValues.toolbarVerticalEdge` | **27.1** | `[VERIFIED]` F7 | dock RADAR's custom nav on the system's vertical-bar edge | `nil` → container rule (bottom bar / rail) | **no** (see Q2) |
| `toolbarVerticalBehavior`, `presentationPlacement`, `axisBehavior`, `visibilityPriority`, `ToolbarOverflowMenu`, `topBarPinnedTrailing` | 27.x? | `[UNVERIFIED]` named in Apple's guidance | only if RADAR adopts system toolbars | custom controls | no |
| `backgroundExtensionEffect` | 26? | `[UNVERIFIED]` | hero artwork under a vertical bar | draw artwork edge-to-edge manually | no |
| `onGeometryChange` | 16+? | `[UNVERIFIED]` recommended by Apple | not used (use `GeometryReader`) | — | — |
| `navigationTransition(.zoom)` | 18 | from memory | art → player transition | `matchedGeometryEffect` | no |
| `TabView(.sidebarAdaptable)`, `Tab` | 18 | from memory | **avoided** (custom RADAR nav) | — | — |
| Liquid Glass (`glassEffect`…) | 26 | from memory | **avoided** (flat RADAR design) | — | identical (not used) |

---

## 6. Devices and layout environments

### 6.1 The five required environments

| Env | Display facts | Container size (pt) | RADAR profile (`RadarLayoutProfile`) |
|---|---|---|---|
| **E1 Standard iPhone** | iOS 17+ iPhones | `[UNVERIFIED]` read in sim; < 720 wide in portrait, wide-shaped in landscape | portrait: bottom bar + mini-player, 1 column, 2-col grids · landscape (≥ 720 wide): rail + transport bar, and two-column pages/player if wide-shaped |
| **E2 Duo closed** | outer 1398×2034 px @460 ppi (F2) | **`[DERIVED]`** 466 × 678 *if the scale is 3×* — Apple doesn't publish points (F3) | compact: bottom bar + mini-player (or vertical bar via `toolbarVerticalEdge`, Q2) |
| **E3 Duo unfolded, wide pose** | inner 1878×2670 px @430 ppi; open 164.6×117.8 mm | **`[DERIVED]`** 890 × 626 *at 3×* | rail + transport bar; **two-column pages + two-pane player** (the design-gap rule, §6.3) |
| **E4 Duo unfolded, tall pose** | same display rotated | **`[DERIVED]`** 626 × 890 *at 3×* | < 720 → bottom bar + mini-player, single column — **likely too sparse for a regular-width inner display; judge on device (Q4)** |
| **E5/E6 iPad Air 13″** portrait / landscape | resolution `[UNVERIFIED]` (not fetched) | `[UNVERIFIED]` ≈ 1024×1366 / 1366×1024 | portrait ≈ rail + transport + two-column pages; landscape ≥ 1100 → sidebar + transport, dock available |
| **E7/E8 iPad Pro 13″** portrait / landscape | 2752×2064 px @264 ppi (F12) | **`[DERIVED]`** 1032×1376 / 1376×1032 *at 2×* | portrait: rail (< 1100) + transport + two-column pages · landscape: **sidebar** + transport + dock available (open by default only ≥ 1680) |

Treat every `[DERIVED]` number as a *prediction to be checked*. **Read the real values from the Layout Lab screen** (`RADAR/Features/Lab/LayoutLabView.swift`) on the first iOS 27 run; if they differ, only the constants in `RadarBreakpoint` change.

### 6.2 What the approved artifact specifies (F13, F14)

| Width (pt) | Navigation | Playback chrome | Content |
|---|---|---|---|
| < 720 | bottom nav (58) + top bar | mini-player (above the nav) | single column; 2-up grids |
| ≥ 720 | **76 pt rail** (icons + 9 pt labels) | **88 pt transport bar** (full width, bottom) | single column until 1000; 3-up grids (RADAR uses an even 4) |
| ≥ 900 | — | full-screen player becomes **two columns** (art \| queue) | — |
| ≥ 1000 | — | — | **multi-column pages** (Discover hero split 7/5, Trending 1.2/1, Search 1/1.5, Settings 1/1, list columns 2) |
| ≥ 1100 | **244 pt sidebar** (wordmark, numbered items, playlists, demo badge) | — | 4-up grids |
| ≥ 1280 | — | dock toggle appears | **348 pt queue dock** (toggle) |
| ≥ 1680 | — | — | dock **open by default** |
| `max-width` | — | — | page max width **1360 pt** (no over-stretching) |

Reference renders: `docs/reference/artifact-wide/` (466×678, 890×626, 1032×1376, 1376×1032 × Discover / Trending / Library).

### 6.3 Gaps and decisions (all `[ASSUMPTION]` unless noted; **need your approval** — Q4)

1. **Short, wide windows (open Duo wide pose).** The artifact has no design for 720–999 pt that is *short*: its single-column hero (104 pt+ type) fills the whole 626-pt-tall window (observed in the 890×626 render). That is "scaling up the closed interface" (R7). **Rule implemented:** a container is *wide-shaped* when `width > 1.15 × height`; wide-shaped ≥ 720 pt gets the two-column pages, and wide-shaped ≥ 640 pt gets the two-pane player.
2. **Even grid columns (2 or 4)**, not the artifact's 2/3/4, per Apple's advice for fold-friendly grids (F9).
3. **Tall inner display (E4)** — see table; undecided.
4. **iPad "persistent expanded player"** — interpreted as the artifact's persistent transport bar (≥ 720) + toggleable queue dock; the dock opens by default only ≥ 1680 (so **not** on a 13″ iPad in landscape at 1376 pt). If you meant a *permanent* now-playing pane, that is a **new design** (Q6).
5. **Orientation is never used** — a container's *shape* (`width` vs `height`) is, per Apple (F5).

---

## 7. Architecture for adaptivity

### 7.1 What exists (all `[UNVERIFIED]` — never compiled)

| Piece | File |
|---|---|
| `RadarBreakpoint` (artifact breakpoints + gap-rule constants) | `RADAR/Layout/RadarLayout.swift` |
| `RadarLayoutProfile.make(for: CGSize)` — **pure function of the container size** (navigation, player chrome, columns, player panes, dock, grid columns, max width) | same |
| `RadarAdaptiveContainer` — measures its own space with `GeometryReader`, publishes the profile via `\.radarLayout`, re-evaluates on every size change | same |
| `RadarApp` — creates all long-lived stores once, above every layout | `RADAR/App/RadarApp.swift` |
| `RootView` — container + splash + scene-phase handling (flush persistence, refresh flags/icon) | `RADAR/App/RootView.swift` |
| **Layout Lab** — live container size, safe area, size classes, derived profile, size-change log, **three state-preservation probes**, runtime OS checks, brand reveal, icon picker, flag controls. *Temporary; keep behind `#if DEBUG`.* | `RADAR/Features/Lab/LayoutLabView.swift` |
| `RadarLayoutTests` — 17 tests (boundaries at every breakpoint, order, container-not-orientation, resize sequence, even columns, gap rule) | `RADARTests/RadarLayoutTests.swift` |
| `tools/check-availability.py` | described in §4 |

### 7.2 Rules for every screen (R9)

- Ask `@Environment(\.radarLayout)`; **never** `UIScreen`, `UIDevice`, `userInterfaceIdiom`, device orientation, or a size class **as a proxy for "iPad"** (`check-availability.py` forbids the first four and warns on size-class equality).
- No absolute positioning or fixed dimensions except design tokens (44 pt targets, 76/244/348 pt chrome, 16 pt gutter, 1360 pt max width).
- Honour safe areas, `\.dynamicTypeSize`; fonts use `relativeTo:`.
- **Never put state in a view that a profile switch replaces.** `if layout.navigation == .rail { A() } else { B() }` gives `A` and `B` different identities: their `@State` is lost. The Lab's probe **C** demonstrates exactly this and **is expected to reset**.

### 7.3 Preserving state across fold / resize (R7)

| What | Owner | Mechanism | Test |
|---|---|---|---|
| Navigation | `NavigationState` store `[NOT DONE]` | selected destination + per-tab route stacks live in an `@Observable` store; compact (`NavigationStack(path:)`) and wide (sidebar selection + detail) are two *projections* of the same store | S2, S6 |
| Playback + queue | `PlayerStore` `[NOT DONE]` | single store; mini-player, transport bar, full player and dock are stateless views of it; the player's expanded/collapsed state is store-held | S3, S4, S6 |
| Scroll position | `ScrollAnchorStore` `[NOT DONE]` | persist **the id of the item at the top** (not a pixel offset — offsets are meaningless when column counts change), restore via `.scrollPosition(id:)` (iOS 17) | S5 |
| Text input / sheets | same stores | held outside the layout | S6 |
| Persistence across launches | `PersistenceController` (exists) | flushed on `.background` (wired in `RootView`) | — |

Probes **A** (store-held) and **B** (`@State` at a stable position) in the Layout Lab are the *minimal* proof of this design on a real fold.

### 7.4 System bars vs RADAR's custom bars — `[NEEDS YOU]` (Q2)

On iOS 27.1+ the **system** puts toolbars/tab bars vertically on the outer display and in some open poses (F8). RADAR's approved design uses **custom** navigation (bottom bar / rail / sidebar), which the system will *not* relocate. Options:
- **(Recommended) Keep RADAR's custom nav, adopt `toolbarVerticalEdge` (iOS 27.1+)** to place RADAR's rail on the system's vertical-bar edge when it is non-nil; below 27.1 or when nil, use the container rule. Preserves the design language; costs a gated wrapper + iOS 17 fallback.
- Use system bars on iPhone: system-correct on Duo, but replaces the artifact's nav (contradicts "preserve the design language").
- Ignore it: the closed Duo shows a bottom bar. Works, but Apple's HIG says not to override default bar placement in general.

### 7.5 iPad multitasking (R8) — configuration `[NOT DONE: needs Xcode to verify]`

`project.yml` / `Config/Shared.xcconfig` set: `UIRequiresFullScreen = false`; all four iPad orientations (required for Split View / Slide Over / Stage Manager); SwiftUI `WindowGroup` (scene lifecycle); `UIApplicationSupportsMultipleScenes = false` (one resizable window; multi-window is **out of scope** unless you want it — Q7). Because layout is container-measured, Split View widths, Slide Over, Stage Manager free-resize and the resizable simulator all go through the same code path.

---

## 8. Build configuration — where each requirement is encoded

| Requirement | Setting | File |
|---|---|---|
| R1 min iOS 17.0 | `IPHONEOS_DEPLOYMENT_TARGET = 17.0`; XcodeGen `options.deploymentTarget` and per-target `deploymentTarget` | `Config/Shared.xcconfig`, `project.yml` |
| R6 iPhone + iPad | `TARGETED_DEVICE_FAMILY = 1,2` (iPhone Duo is an iPhone-idiom device; no separate family) | same |
| R3 compiler enforcement | follows from R1 | — |
| Build with Xcode 27.1+ | **documented** (cannot be enforced in a config file) — `BUILD_STATUS.md`, README | docs |
| R7/R8 no orientation lock | `UISupportedInterfaceOrientations` (portrait, landscape L/R), `~ipad` (all four) | `project.yml` |
| R8 multitasking | `UIRequiresFullScreen: false` | `project.yml` |
| Swift 5 mode | `SWIFT_VERSION = 5.0`, `SWIFT_STRICT_CONCURRENCY = minimal` | `Config/Shared.xcconfig` |
| Alternate icon | `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = AppIconGlitch` | same |
| Identity | `PRODUCT_BUNDLE_IDENTIFIER = $(RADAR_BUNDLE_ID)` from git-ignored `Config/Local.xcconfig` | `Config/Local.xcconfig.example` |
| Remote flags | Info.plist `RADARFlagsURL` / `RADARFlagsAnonKey` from `RADAR_FLAGS_*` | `project.yml`, `Config/Shared.xcconfig` |

**Status:** `[VERIFIED]` `project.yml` parses as YAML; values cross-checked (17.0, `1,2`, 3 + 4 orientations, 10 font files exist). `[NOT DONE]` never run through XcodeGen or Xcode. Generate with `brew install xcodegen && xcodegen generate`.

---

## 9. Testing plan (nothing here has been run)

### 9.1 Environments to create (your iOS 27 setup)
Names are Xcode's; I could not inspect them. `[UNVERIFIED]` exact device names.

| ID | Environment | How |
|---|---|---|
| E1 | Standard iPhone, portrait **and** landscape | any current iPhone simulator, iOS 27 |
| E2 | Duo **closed** | **iPhone Duo simulator** (Xcode 27.1, Device Hub) → close control |
| E3 | Duo **open, wide pose** | same → open, rotate to wide |
| E4 | Duo **open, tall pose** | same → open, rotate to tall |
| E5/E6 | **iPad Air 13″** portrait / landscape | iPad simulator |
| E7/E8 | **iPad Pro 13″** portrait / landscape | iPad simulator |
| M1 | iPad Split View 1/3, 1/2, 2/3; Slide Over | iPad simulator, both orientations |
| M2 | iPad Stage Manager free-resize | iPad simulator |
| M3 | **Resizable iOS simulator** sweep, narrow → wide → narrow | Device Hub |
| M4 | iPhone Mirroring, extreme window sizes | macOS 27 |

### 9.2 Scenarios (every environment runs all of them)
| ID | Scenario | Pass criterion |
|---|---|---|
| S1 | Cold launch, splash | glitch→clean reveal plays; no flash from launch screen; Reduce Motion ⇒ clean logo |
| S2 | Navigate every destination and back | no dead ends; selection preserved on resize |
| S3 | Playback: play/pause/next/prev/seek/shuffle/repeat | state correct in whichever player chrome is showing |
| S4 | Queue: add, play next, remove, clear | queue identical after any resize/fold |
| S5 | Scroll deep, then resize/fold | same item remains visible (anchor preserved) |
| S6 | **Transitions**: fold/unfold/rotate/resize while idle · while playing · with a sheet open · with the full player open | nothing lost, no crash, no layout jump larger than the profile change |
| S7 | Dynamic Type: default, XXXL, AX5 | no clipping/overlap; 44-pt targets |
| S8 | Dark and Paper themes | contrast OK |
| S9 | Accessibility: VoiceOver, Reduce Motion, Increase Contrast | **VoiceOver/Accessibility Inspector do not work on Duo in Device Hub (F11)** — use another device or a physical Duo |
| S10 | Alternate icon + flag gate | picker hidden until flag on; switching works; switch back works |
| S11 | **Layout Lab probes** | A and B survive; C resets (proves the rule) |
| S12 | **Calibration**: record the real point sizes of E2/E3/E4/E5–E8 from the Lab | update `RadarBreakpoint` if they differ from §6.1 |

### 9.3 Definition of done (R11)
Device support is complete only when **(a)** every environment E1–E8 has run S1–S12 and the result is recorded below, **(b)** M1–M4 resize sweeps were done during playback, **(c)** the Duo simulator was exercised through close/open/rotate mid-playback, **(d)** the app builds with deployment target 17.0 and the unit tests pass, **(e)** the iOS 17 gap (§9.4) is closed or explicitly accepted.

### 9.4 iOS 17 — who tests it?
You test **only iOS 27**, and I cannot run anything. iOS 17 behaviour is therefore guarded **only** by the compiler (unguarded newer APIs fail the build), the lint, and unit tests. A run on an **iOS 17 simulator** (Device Hub supports it, F11) is `[NOT DONE]`. Recommendation: have CI run the unit tests and a launch smoke test on an iOS 17 simulator; or accept the risk explicitly.

### 9.5 Tooling limits to expect (F11)
No VoiceOver / Accessibility Inspector on the Duo simulator; black screenshots for minutes after boot; modifier keys may stop after switching displays (workaround: click the visible screen); StandBy and most extensions unavailable in the Duo sim runtime.

### 9.6 Results log (all not run)
| Env \ Scenario | S1 | S2 | S3 | S4 | S5 | S6 | S7 | S8 | S9 | S10 | S11 | S12 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| E1 iPhone | – | – | – | – | – | – | – | – | – | – | – | – |
| E2 Duo closed | – | – | – | – | – | – | – | – | n/a (F11) | – | – | – |
| E3 Duo open wide | – | – | – | – | – | – | – | – | n/a (F11) | – | – | – |
| E4 Duo open tall | – | – | – | – | – | – | – | – | n/a (F11) | – | – | – |
| E5 Air portrait | – | – | – | – | – | – | – | – | – | – | – | – |
| E6 Air landscape | – | – | – | – | – | – | – | – | – | – | – | – |
| E7 Pro portrait | – | – | – | – | – | – | – | – | – | – | – | – |
| E8 Pro landscape | – | – | – | – | – | – | – | – | – | – | – | – |

`–` = not run.

---

## 10. Changes to the Phase 3 plan

Insert, in this order (the rest of `docs/handoff/phase-2/PHASE_3_PLAN.md` still applies):
1. **Build gate with Xcode 27.1+** (generate with XcodeGen; confirm 17.0 is accepted; run all 46 existing tests incl. the 17 in `RadarLayoutTests`).
2. **Run the Layout Lab on every environment (S11, S12) before building any screen.** Update the breakpoints from real numbers.
3. **App shell before screens:** `NavigationState`, `PlayerStore`, `ScrollAnchorStore` (all above the layout) + three navigation projections (bottom bar / rail / sidebar) + two player chromes (mini / transport bar) + dock.
4. **Build every screen layout-first** from the artifact's wide layouts (§6.2) plus the §6.3 decisions.
5. **27.1 adoption wrappers** (`toolbarVerticalEdge`, `reservedRegions`, `ArrangementView`) with iOS 17 fallbacks, only after the compiler can check them.
6. QA matrix §9.

---

## 11. What cannot behave identically on iOS 17 (R4)

| Feature | iOS 27 (27.1+) | iOS 17 | Cause |
|---|---|---|---|
| Duo fold/unfold adaptation, vertical bar edge, reserved regions (fold + camera) | active | **absent** | iPhone Duo hardware ships with iOS 27; no iOS 17 device has a fold. Fallback = container-measured layout only (also what iOS 27.0 gets) |
| `ArrangementView` split/overlay at partial folds | available | custom `HStack`/`VStack` split without fold awareness | API is 27.1+ |
| Hero artwork extended under a vertical bar (`backgroundExtensionEffect`, if adopted) | available (26+) | artwork drawn edge-to-edge manually | API newer than 17 |
| Art → player zoom transition (if adopted) | `navigationTransition(.zoom)` (18+) | `matchedGeometryEffect` crossfade | API newer than 17 |
| Device Hub text-size control | n/a | can't set text size for iOS ≤ 18 simulators (F11) → set Dynamic Type in the Settings app | tooling |
| Everything else in RADAR today (Canvas logo/glitch, icon picker, flags, persistence, haptics, fonts) | uses only iOS 17-level APIs | identical | `[UNVERIFIED]` until compiled |

`[NOT DONE]` further entries are added as APIs are adopted.

---

## 12. Open questions — `[NEEDS YOU]`

| # | Question | Why it matters |
|---|---|---|
| Q1 | Which iOS 27 **point release** and Xcode do your devices/simulators run (27.0 / 27.1 / 27.2)? | Duo layout APIs are **27.1+**; on 27.0 only the fallbacks run |
| Q2 | Custom nav + `toolbarVerticalEdge` (recommended) vs system bars vs ignore? (§7.4) | Shapes the shell and the closed-Duo look |
| Q3 | Are **partially folded** poses (tent, laptop, split at the fold) in scope? You listed closed/unfolded only. | Needs `reservedRegions`/`ArrangementView` work |
| Q4 | Approve the §6.3 design-gap rules (wide-shaped containers → two-column; even grid columns; open-tall treatment)? | These extend the approved design |
| Q5 | Which iPad Air 13″ generation, and which iPadOS? | I could not verify its display spec |
| Q6 | "Persistent expanded player" = persistent transport bar + toggleable dock (artifact), or a permanent now-playing pane? | New design if the latter |
| Q7 | One resizable window only, or multi-window? | `UIApplicationSupportsMultipleScenes` |
| Q8 | Confirm Xcode 27.x accepts a 17.0 deployment target on your machine; share any error | I could not confirm it |
| Q9 | Bundle id, team, display name | `Config/Local.xcconfig` |

---

## 13. Verification log (executed in this session)

| What | Result |
|---|---|
| Public sources for Duo / iOS 27 / Xcode 27 fetched | F1–F12 above |
| Artifact CSS breakpoints extracted | 720, 900, 1000, 1100, 1280 (+ 359 max-width, hover/reduced-motion queries) |
| Artifact rendered at 466×678, 890×626, 1032×1376, 1376×1032; visible chrome measured | F14; 12 viewport renders |
| `tools/check-availability.py` on the repo | 32 Swift files, 0 errors, 0 warnings; self-test 4/4 violations caught, guarded + commented uses ignored |
| `project.yml` parsed | valid YAML; deployment 17.0; device family `1,2`; 3 + 4 orientations; `UIRequiresFullScreen` false; 10 font files present |
| Swift bracket-balance check over all Swift files | 0 unbalanced (weak check) |
| **Swift compile / any test / any simulator** | **not run** |
