# PHASE_3_PLAN

Recommended order of work. The guiding rule: **get a compiler in the loop before writing more code**, because ~3,300 lines of Swift are unverified and every new line built on them compounds the risk.

Sizes: S ≈ hours · M ≈ 1–2 days · L ≈ several days. `[NEEDS YOU]` = blocked on your input. Kotlin translation stays **out of scope** until the iOS build is validated (your Phase 02 instruction).

## Entry criteria (before step 1)
- A way to compile: your Mac, or approval for macOS CI minutes. **[NEEDS YOU]**
- Bundle id, team, display name, min iOS. **[NEEDS YOU]**

---

## Step 0 — Housekeeping (S)
- Decide the PR/merge policy (no merge before green CI). **[NEEDS YOU]**
- Fix the two inaccurate statements in `docs/feature-flags-and-app-icons.md` (Settings controls; launch/foreground refresh) — or delete the file in favour of this handoff.
- Add repo `README.md`, `tools/package.json` (`svgpath@2.6.0`), font OFL licence files; make `tools/icons.js` resolve `svgpath` like `brand.js`.
- Commit the missing tooling: SVG→PNG renderer, asset-catalog colourset generator, `GlitchVectors.json` regeneration script.
- Commit (or deliberately drop) the reference assets that live only in scratch space (brand sheets, reference screenshots, a fetch script for the artifact bundle).

## Step 1 — Project + first green build (M) — **the gate**
1. Create the project (XcodeGen `project.yml` recommended so it is reviewable and CI-friendly; or a hand-made `.xcodeproj`). `BUILD_STATUS.md` §3/§5.
2. Add a minimal `@main` app that shows `RadarLogoReveal`.
3. Build; clear compile risks R1–R15; keep Swift 5 mode.
4. Run the 29 existing tests; fix test or code bugs.
5. CI workflow (macOS) building + testing on every push; upload `.xcresult`.
**Exit:** `xcodebuild test` green locally/CI; reveal animation and Glitch icon switch observed on a simulator.

## Step 2 — Parity + persistence tests (M)
- `DemoCatalog` parity against `ParityVectors.json` (hash, PRNG, charts ×4, movers, emerging, rising, newReleases, search ×6, related, spark, art, wave).
- `DemoCatalog.shared` decode test (guards the `fatalError`).
- `Format` parity (generate expected strings from the bundle's `ta/na/ra/ia`).
- `PersistenceController` round-trip/corruption; `LibraryStore`, `SettingsStore`, `DownloadCenter` rules.
- Generate JS vectors for `V8RandomSort` (the bundle's `yi` generator) and test it.
**Exit:** the ported logic is proven equal to the original or each difference is understood.

## Step 3 — Design-system primitives (L)
Order chosen so each unlocks screens:
1. **Artwork:** `ArtworkView` (Canvas) porting the 8 generators `mi, hi, gi, _i, vi, yi, bi, xi` from the bundle (rings, sweep, bars, dots, arcs, blocks, waves, orbit) using `ArtSpec`; memoise by `(seed, palette, style, size)`; use `drawingGroup`/cached `Image` for scrolling lists.
2. **FX layers:** scanlines (5% black, 3 px pitch), grain (overlay noise tile), RGB-split slice text (`GlitchText`, `slice-a/b` hard-step animation), split burst on track change (`fx-1…3`, incl. the turbulence tear on `fx-3`), blip ping, EQ bars, skeleton "scan" shimmer.
3. **Type & layout:** `SectionHeader` (index, rule, readout, title), `Readout`, hero/display scaling, `Page` insets (16 gutter), `Tabs` with moving ink, buttons (`cta`, `btn`, `tag`, `slash`), `NewFlag`, `ExplicitFlag`, `DemoBadge`, `SourceTag`, `StatusLabel`, `MoveIndicator`, sparkline.
4. **Rows & tiles:** `TrackRow` with swipe-right "play next", swipe-left "save", long-press → context sheet, progress bar for downloads; `Tile`, `Lead`, `Story`, `Poster`, `Band`, `Mix`, rails with stagger, collage grid.
5. **Overlays:** toast host (render `ToastCenter`), bottom sheet, track context menu with "Add to playlist" sub-page, "About demo data" sheet, "No signal" empty-state card.
6. **Waveform scrubber** (`ka`): seeded demo waveform; real peaks via `WaveformAnalyzer` for local files.
**Exit:** a gallery/preview screen (the artifact's "Art lab" equivalent) renders every primitive.

## Step 4 — Player core (L)
- `PlayerStore` (`@MainActor @Observable`) porting the artifact's player provider: queue (`play(id, list)`, `playNext`, `enqueue`, `removeAt`, `clearUpcoming`, `jump`), shuffle (random index ≠ current), repeat off/all/one, `prev` (restart if > 3 s), history via `LibraryStore.addRecent`.
- **Demo tracks:** simulated clock (250 ms tick) exactly like the artifact — no audio exists for demo tracks; say so in the UI ("Demo playback").
- **Local files:** `AVAudioPlayer`/`AVPlayer` with `AVAudioSession` category `.playback`, interruption + route-change handling, background audio (`UIBackgroundModes: audio`), `MPNowPlayingInfoCenter` + `MPRemoteCommandCenter` (play/pause/next/prev/seek).
- Unit tests for queue/shuffle/repeat logic (pure) and a thin protocol seam for the audio backend.
**Exit:** playback state machine tested; a local file plays in background on a device.

## Step 5 — App shell + navigation (M)
- `RadarApp` (`@main`): create and inject all stores; `LaunchSplash` integration (`ARCHITECTURE.md` §4.4); `scenePhase` → `PersistenceController.flush()` and `FeatureFlags.refresh()`; `.preferredColorScheme` from settings.
- Custom bottom nav (4 tabs, active ink), `NavigationStack` per tab, the mini-player stack above the nav (swipe up to expand, swipe sideways to skip), expanded player (art swipe, pull-down dismiss, tabs Now playing / Queue), shared-element-like art transition (artifact used View Transitions; use `matchedGeometryEffect`/`navigationTransition(.zoom)` on iOS 18 where available), scroll restoration.

## Step 6 — Screens (L)
In this order (each reuses the previous): Library (tabs: Saved/Playlists/Recent/Local/Offline, playlist creation, **local import via `fileImporter`**, delete), Discover (hero + glitch-in headline, index, stories, new transmissions collage, frequencies bands, rising artists, collections), Trending (region + window tabs, number-one lead, movers, emerging, discoveries, #1 elsewhere), Search (local demo search, recents, trending searches, top result, grouped results, empty state), Detail pages (Track incl. chart position/why/related/source/download panel; Artist; Album; Playlist incl. empty state), **Settings** (Appearance, Signal & touch, Country & discovery, Providers (demo-only), Storage (demo figures), Account (demo), **App icon**, Design-review group incl. `FeatureFlagControls` under `#if DEBUG`), Art lab (debug).
**Exit:** every route in the artifact has a native equivalent.

## Step 7 — Flags go live (S–M)
- With your answer on the backend **[NEEDS YOU]**: create the table + RLS (SQL in `FEATURE_FLAGS.md` §7), set URL/key via `.xcconfig`, ensure `refresh()` runs at launch/foreground.
- Add a `URLProtocol`-stubbed `SupabaseFlagProvider` test.
- Dry run: flag off → no picker; flip on → picker appears within one refresh; pick Glitch; flip off → picker still shows because Glitch is active; switch back → picker disappears.

## Step 8 — Quality pass (L)
- **Fidelity:** screenshot every screen at 393×852 (+ SE 375×667, Pro Max 430×932) in dark and Paper; diff against `reference/artifact-screenshots/`; iterate.
- **Accessibility:** VoiceOver labels/traits/order, Dynamic Type up to AX sizes (fixed-size display type needs care), Reduce Motion/Cross-fade, contrast in Paper theme, 44 pt targets, accessible alternatives to swipe gestures (the artifact's rows have buttons too).
- **Performance:** Instruments (Time Profiler, Allocations, SwiftUI) on long lists (collage, rows); artwork cache sizing; waveform memory for long files; confirm 60 fps during reveal and scrolling.
- **Robustness:** corrupt persistence files, missing imported files, low disk, interruption handling.
- **Privacy/compliance:** `PrivacyInfo.xcprivacy`, permission strings, licence notices (fonts), review notes mentioning the remote icon switch.

## Step 9 — Delivery (M)
Project README; build/test instructions that have been *executed*; asset catalog audit; release configuration (strip debug controls); TestFlight build; final handoff. Only then consider the Kotlin phase.

## Risks to manage
| Risk | Mitigation |
|---|---|
| Compounding unverified code | Step 1 gate; CI from day one |
| Logo placeholder | Swap in your Illustrator SVGs early; regenerate |
| Artwork performance (Canvas × many tiles) | Cache rasterised covers; measure early (Step 3.1) |
| Artifact behaviours that rely on browser features (View Transitions, `pointer` events, CSS filters) | Map to SwiftUI equivalents deliberately; keep a list |
| macOS CI cost on a private repo | Cache derived data; build only on PRs; or use your Mac |
| Scope creep into real YouTube/SoundCloud | Brief forbids pretending; keep providers "Demo" until authorised |

## Suggested first message for the next session
"Here is my Mac / approve macOS CI. Bundle id is …, min iOS 17. The backend is …. Illustrator SVGs attached. Start at Step 1."
