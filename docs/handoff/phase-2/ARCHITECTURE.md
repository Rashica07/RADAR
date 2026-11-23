# ARCHITECTURE

How the pieces built in Phase 2 fit together. Everything here describes **code that exists**; where something is only *intended*, it is labelled `[NOT DONE]`. No Swift in this repo has been compiled (`BUILD_STATUS.md`).

## 1. Layers (as they exist today)

```
RADAR/
├── Core/                 pure helpers, no UI        SeededRandom · Haptics · Format · Persistence
├── Models/               value types                CatalogModels · ArtSpec
├── Services/             state + logic              DemoCatalog (immutable, Sendable)
│                                                    SettingsStore · LibraryStore · DownloadCenter
│                                                    LocalLibrary · ToastCenter          (@MainActor @Observable)
│                                                    FeatureFlags · AppIconService        (@MainActor @Observable)
├── DesignSystem/
│   ├── Theme/            Colors · Typography
│   ├── Icons/            RadarIcon (+ generated RadarIconPaths)
│   └── Brand/            GlitchSpec · RadarMarks · RadarLogoReveal · LaunchSplash (+ generated RadarBrandPaths)
├── Features/
│   └── Settings/         AppIconPickerSection · FeatureFlagControls      (views only — no screen hosts them)
└── Resources/            DemoCatalog.json · Fonts/ · Assets.xcassets/
RADARTests/               GlitchTests · FeatureFlagsTests · Support/Fixture · Fixtures/*.json
tools/                    generators (Node/Python) — run on a dev machine, not shipped
docs/brand/               generated SVG sources
```

Planned-but-absent modules from the Phase 02 brief: `App/` (entry point), `Features/{Discover,Trending,Search,Library,Player}`, and most of the design system (artwork, rows, tiles, tabs, sheets, toasts host, FX layers). `[NOT DONE]`.

Dependency direction: `Features → Services → Models/Core`; `DesignSystem → Core/Models` (it reads `Haptics`); `Services` never import `DesignSystem` except `ToastCenter`/`DownloadCenter`, which refer to `RadarIconName` (an icon *name*, not a view).

## 2. Concurrency model

| Type | Isolation | Why |
|---|---|---|
| `DemoCatalog` | `final class … Sendable`, all `let` | immutable after init; safe to read from any task |
| `SettingsStore`, `LibraryStore`, `DownloadCenter`, `LocalLibrary`, `ToastCenter`, `FeatureFlags`, `AppIconService` | `@MainActor @Observable` | UI-bound state; SwiftUI observes via Observation |
| `PersistenceController` | `@unchecked Sendable`, `NSLock` + private serial queue | called from main-actor stores; writes happen off-main |
| `WaveformAnalyzer` | `actor` | caches peaks per URL (reads synchronously while it runs) |
| `Haptics` | `@MainActor enum` | UIKit feedback generators |
| `FlagProvider` | `protocol … Sendable` | fetch runs async off the store's actor hop |

The code is written for the **Swift 5 language mode**. Strict-concurrency (Swift 6) checking would flag several places (see `BUILD_STATUS.md` risk R3).

## 3. Persistence layout

`PersistenceController` writes `Application Support/RADAR/radar.v1.<key>.json`. Keys in use: `settings`, `library`, `downloads`, `local-files`, `flags`. Imported audio lives in `Application Support/RADAR/Imported/` (excluded from backup). Bump `PersistenceController.namespace` when a stored shape changes incompatibly; undecodable files are discarded (logged) and defaults are used.

## 4. The glitch system

### 4.1 One spec, two implementations

The glitch is defined **once, as an algorithm**, and implemented twice so the animated in-app logo and the baked app-icon PNG are the same look:

| | JS | Swift |
|---|---|---|
| File | `tools/glitch.js` | `RADAR/DesignSystem/Brand/GlitchSpec.swift` |
| PRNG | `rng(seed)` (mulberry32 variant using `Math.imul`) | `SeededRandom(seed:)` |
| Band generator | `bands({seed,height,amount,maxLength})` | `GlitchSpec.bands(seed:height:amount:maxLength:)` |
| Trail constants | `TRAIL_COPIES = 8`, `trailAlpha(k)` | `GlitchSpec.trailCopies`, `GlitchSpec.trailAlpha(_:)` |
| Consumer | `tools/glitch-icon.js` → SVG → PNG → asset catalog | `RadarLogoCanvas` (Canvas) |

**Algorithm (identical in both):**

```
rng = PRNG(seed); y = 0
while y < height:
    h  = 1.5 + rng()*5.5
    r1 = rng(); r2 = rng()                       # draw order is part of the spec
    yn = (y + h/2) / height
    w  = 0.10 + 0.90 * max(bump(yn, 0.20, 0.13), bump(yn, 0.93, 0.12))   # bump = exp(-((x-c)/s)^2)
    active = r1 < 0.10 + 0.75*w
    length = active ? amount * maxLength * w * (0.25 + 0.75*r2) : 0
    emit {y, h: min(h, height-y), length}; y += h
```

**Keeping them in sync.** `RADARTests/Fixtures/GlitchVectors.json` holds the JS output for 4 cases (seed/amount: 7/1, 1/1, 12345/0.5, 2166136261/0.2; height 207, maxLength 361×0.22). `GlitchTests.testBandsMatchTheJavaScriptReference` compares Swift to it within 1e-9. **To change the look:** edit `glitch.js` and `GlitchSpec.swift` together, regenerate the fixture (command in §4.5), re-run `glitch-icon.js`, re-render the icon PNGs, run the tests. Floating-point differences between V8 and Swift (`exp`) are expected to be far below 1e-9 `[UNVERIFIED]`.

### 4.2 Renderer — `RadarLogoCanvas` (`RadarMarks.swift`)

A SwiftUI `Canvas` view; no images, so it is vector-sharp at any size and costs nothing when `glitch == 0` (the only extra work is skipped by `if glitch > 0.001`).

Inputs: `layout` (`.symbol` / `.wordmark` / `.lockup`), `height`, `glitch` ∈ [0,1], `tint` ∈ [0,1], `seed`, optional `monochrome` colour.

Draw order, per layout:
1. **Trails** (only if `glitch > 0.001`): for each active band, clip to the band rectangle (`clip(to:)` in the *untranslated* coordinate space), then draw `trailCopies` copies of the whole shape translated by `−length·k/8` with opacity `trailAlpha(k)`. Symbol: the single combined path `Shapes.symbolAll`, plus a right-hand tick (`+0.1·length`, opacity 0.6) for bands longer than 12% of the symbol width. Wordmark: left trails clipped to `x ∈ [−600, 0.5]` and right trails (`amount × 0.7`, maxLength 34) clipped to `x ∈ [width−0.5, width+600]`, so only the outer edges of the first/last letters streak.
2. **Clean artwork**: `outer` (mint), `signal` (mint→coral by `tint`), then `signal` again clipped to `signalHeadClip` (mint→warm white) — the white head — then `core` and `leg` (mint). Wordmark: bodies with even-odd fill, R legs with non-zero fill, colour mint→warm by `tint`.

Everything is in the symbol's own 361×207 space (wordmark: 859×118); the canvas scales to `height`. `RadarBrandLayout` places the wordmark in the lockup (scale 0.99992, gap 70.38, origin (431.38, 51.96); `DESIGN_SPEC.md`).

Wrappers: `RadarSymbol`, `RadarWordmark`, `RadarLogo` (clean, monochrome-capable) — these are what ordinary screens should use.

### 4.3 The reveal — `RadarReveal` + `RadarLogoReveal` (`RadarLogoReveal.swift`)

- `RadarReveal.frame(at:)` is a **pure function** of elapsed time → `RevealFrame(glitch, tint, step)`; this is what the unit tests exercise.
- `RadarLogoReveal` hosts it: `TimelineView(.animation(minimumInterval: nil, paused: finished || !animated))` samples the frame each display tick and feeds `RadarLogoCanvas`, re-seeding per step via `RadarReveal.seed(forStep:)` so every hard cut shows a fresh streak layout. A `.task(id: replay)` owns the clock: sets `startedAt`, sleeps to 0.8 s, fires `Haptics.play(.light)`, sleeps to 0.95 s, sets `finished` and calls `onFinished`. Changing `replay` restarts it. `animated == false` renders the clean logo immediately and calls `onFinished` right away.

### 4.4 Splash — `LaunchSplash` (`LaunchSplash.swift`) — **state of integration**

`LaunchSplash(animated:onDone:)` exists and is self-contained: charcoal `LaunchBackground`, lockup sized to `min(0.78 × width, 520)`, runs `RadarLogoReveal`, waits 0.35 s (0.6 s when not animated), fades out over 0.3 s, then calls `onDone`.

**It is not used anywhere.** There is no `@main` app, so nothing presents it. `[NOT DONE]`. The intended wiring (a sketch, **not code in the repo**):

```swift
@main struct RadarApp: App {
    @State private var showSplash = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // stores created once and injected: SettingsStore, LibraryStore, DownloadCenter, LocalLibrary,
    // ToastCenter, FeatureFlags, AppIconService
    var body: some Scene {
        WindowGroup {
            ZStack {
                RootTabView()
                if showSplash {
                    LaunchSplash(animated: settings.fx && !reduceMotion) { showSplash = false }
                        .transition(.identity).zIndex(10)
                }
            }
            .environment(…)           // all stores
            .task { await flags.refresh() }
        }
    }
}
```
The system launch screen must be the same charcoal (`UILaunchScreen` → `LaunchBackground`) so there is no flash. Replay for the in-app logo is available by changing `RadarLogoReveal.replay`.

### 4.5 Regenerating the glitch artefacts

```
node tools/brand.js RADAR/DesignSystem/Brand docs/brand           # brand SVGs + RadarBrandPaths.swift
node tools/glitch-icon.js 7 docs/brand/radar-app-icon-glitch.svg  # glitched icon SVG
# SVG → PNG: Playwright/Chromium screenshot at 1024 and 512 (script NOT in the repo; see KNOWN_ISSUES #9)
node -e "…"   # regenerate GlitchVectors.json from tools/glitch.js (one-liner used in Phase 2; not saved as a script)
```

## 5. Icon system

```
tools/brand.js ──► docs/brand/radar-symbol.svg … radar-app-icon.svg ─(render)─► AppIcon-1024.png ─► AppIcon.appiconset      (primary)
       └─ exports SYMBOL ─► tools/glitch-icon.js ─► radar-app-icon-glitch.svg ─(render)─► AppIconGlitch-1024.png ─► AppIconGlitch.appiconset (alternate)
                                                                     └─(render 512)─► IconPreviewGlitch.png / IconPreviewDefault.png ─► imagesets (in-app previews)
```

Runtime:

- `AppIconChoice` maps UI choices to asset names (`nil` = primary `AppIcon`; `"AppIconGlitch"`).
- `AppIconService` reads `alternateIconName` (so the OS remains the source of truth and the choice persists across launches and updates by itself) and calls `setAlternateIconName`.
- Previews come from the `IconPreview*` imagesets because an alternate icon's `.appiconset` cannot be loaded by name.
- Build settings required `[NOT DONE — no project]`: `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`, `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = AppIconGlitch`.
- Constraint: icon images are compiled into the binary; a remote flag cannot deliver a new icon (`FEATURE_FLAGS.md`).

## 6. Feature flags

```
SupabaseFlagProvider.fromBundle()        ← Info.plist: RADARFlagsURL, RADARFlagsAnonKey (nil if absent/invalid)
        │ fetch() → [String: Bool]       GET {URL}/rest/v1/feature_flags?select=key,enabled
        ▼
FeatureFlags (@MainActor @Observable)
   remote[key]  ← refresh(force:)   ── cached to `flags` JSON with fetchedAt
   overrides[key] ← setOverride()   ── persisted, design-review only
   isEnabled(flag) = overrides ?? remote ?? flag.defaultValue (false)
        ▼
AppIconService.availableChoices / isPickerVisible  ──►  AppIconPickerSection (Settings)
```

`FeatureFlags.refresh()` is **never called** by existing code `[NOT DONE]`; it must be invoked at launch and on foreground (throttled to 5 min internally).

## 7. Environment contract (what the app root must inject)

`AppIconPickerSection` reads `@Environment(AppIconService.self)`, `@Environment(FeatureFlags.self)`, `@Environment(ToastCenter.self)`; `FeatureFlagControls` reads `FeatureFlags`. The Observation-style `.environment(object)` injection is required at the root, or these views trap at runtime. `RadarIcon` optionally reads `\.radarIconCut`.

## 8. Extension points

| To add… | Touch |
|---|---|
| A new alternate icon | new `AppIcon<Name>.appiconset` + `IconPreview<Name>` imageset; `AppIconChoice` case (+ `alternateName`, `previewAsset`, `requiredFlag`); `FeatureFlag` case; add to `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`; tests |
| A new feature flag | `FeatureFlag` case (`rawValue` = DB key, `defaultValue`, `title`); insert the row in the table |
| A new glitch use (e.g., artwork burst) | reuse `GlitchSpec.bands`; the *RGB-split* effect for text/art is a different, still-unported vocabulary (`DESIGN_SPEC.md` §13) |
| A new brand lockup | `RadarLogoCanvas.Layout` + `RadarBrandLayout` |
