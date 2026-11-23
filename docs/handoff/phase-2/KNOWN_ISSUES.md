# KNOWN_ISSUES

Everything incomplete, wrong, risky, or needing attention. Severity: **Blocker** (stops the phase), **High**, **Medium**, **Low**. **[NEEDS YOU]** marks items I cannot resolve without your input.

## Issues

| # | Sev | Issue | Detail / evidence | Action |
|---|---|---|---|---|
| 1 | Blocker | **Nothing has been compiled, run, or tested** | No Swift toolchain here (`BUILD_STATUS.md` §2). 29 tests never executed | Get a compiler: Mac or macOS CI **[NEEDS YOU]** |
| 2 | Blocker | **No Xcode project, no `@main`, no Info.plist, no CI** | `find` found none | `BUILD_STATUS.md` §5; bundle id/team/min-iOS **[NEEDS YOU]** |
| 3 | High | **Settings views are not mounted; a repo doc says they exist** | `AppIconPickerSection`/`FeatureFlagControls` are referenced by nothing (grep `[VERIFIED]`). No Settings screen exists. `docs/feature-flags-and-app-icons.md` says "Settings → Design review controls lets you override them locally" | Build the Settings screen; until then correct the doc |
| 4 | High | **Flags are never refreshed; a repo doc says they are** | `FeatureFlags.refresh()` has no caller. The same doc says the app "picks the change up on the next launch or foreground" | Call at launch + `scenePhase == .active`; fix the doc |
| 5 | High | **No flag backend exists** | No Supabase project/table created or touched. "Supabase" is **my assumption** about "the database" | Confirm backend; URL + publishable key, or authorise me to create it **[NEEDS YOU]** (`FEATURE_FLAGS.md` §10) |
| 6 | High | **Splash is not integrated** | `LaunchSplash` has no caller; no app entry exists | Wire into `@main` (`ARCHITECTURE.md` §4.4) |
| 7 | High | **PR #1 merged uncompiled WIP into `main`; its description is stale** | `GIT_STATE.md`: merged 09:30:51Z, 0 checks; body predates glitch/flags work | Consider a rule: merge only after green CI **[NEEDS YOU]**; update/replace PR text if useful |
| 8 | High | **Logo vectors are fitted traces, not the real artwork** | Wordmark IoU 0.884 vs sheet; D/A positions off by ≈10–11 units; one R shape used twice but sheet R's differ (≈150 vs ≈128 wide); letter-top notches in the glitched wordmark not reproduced | Your Illustrator redraw (layers `outer`, `signal`, `core`, `leg`, `wordmark`) **[NEEDS YOU]**; then update `tools/brand.js` and regenerate |
| 9 | High | **Generators are not reproducible from the repo** | No `package.json` (needs `svgpath@2.6.0`); `tools/icons.js` hard-codes `./npm/node_modules/svgpath`; the SVG→PNG Playwright renderer, asset-catalog colourset generator and the `GlitchVectors.json` regeneration one-liner were run ad hoc and **are not saved**; `extract.js`/`fonts.py` need the artifact bundle that exists only in scratch space | Add `package.json`, commit the renderer + catalog generator, save the bundle (or its fetch script) |
| 10 | High | **No parity tests for the ported logic** | `ParityVectors.json` (hash, prng, charts, movers, search, related, spark, art, wave) is generated but **no test reads it**; `Format`, `V8RandomSort`, persistence untested | Write them first thing after the build works (`TESTING.md` §3) |
| 11 | High | **Local audio: import exists, playback does not** | `LocalLibrary` has no UI caller; there is no player; `WaveformAnalyzer` reads synchronously on its actor | Player + importer UI in Phase 3 |
| 12 | High | **Design system is mostly missing** | Not written: artwork renderer (8 styles; "blocks" needs `V8RandomSort`), scanlines/grain/RGB-split FX, glitch text, section header, tabs with moving ink, track row with swipe/long-press, tiles, lead/story/poster/band/mix, rails, skeletons, "No signal" card, toast host, sheets/context menu, waveform scrubber, EQ bars, ping blip, buttons | `PHASE_3_PLAN.md` |
| 13 | High | **No screens, navigation, or player** | Discover, Trending, Search, Library, Settings, Track/Artist/Album/Playlist detail, Art lab, mini + expanded player, queue, playlists UI, gestures — none exist | Phase 3 |
| 14 | Medium | **Font licences not included; Latin subset only** | Big Shoulders Display, Inter, Space Grotesk are believed to be SIL OFL 1.1 (from the artifact's package naming — I did not read licence files). No licence/notice files are in the repo. Extended/Cyrillic/Greek/Vietnamese subsets were not converted | Add OFL texts + attribution **[NEEDS YOU]** to confirm; convert more subsets if needed |
| 15 | Medium | **Reference material lives only in ephemeral locations** | Brand sheets: this session's upload folder. Screenshots, patched site, prettified bundle, scripts: scratch space. Artifact itself persists on claude.ai (URL in `IMPLEMENTATION.md`) | Copies are in this zip (`reference/`); commit what you want kept **[NEEDS YOU]** |
| 16 | Medium | **Icon limits** | No iOS 18 dark/tinted variants (the `dark` entry reuses the standard art); Android/favicon variants from the sheet not generated; icons ship in the binary so a *new* icon needs an app update; iOS always shows its own confirmation alert | Decide scope **[NEEDS YOU]** |
| 17 | Medium | **Demo catalog differs from the artifact** | 51 → 46 tracks, 24 → 23 artists, 3 → 2 providers (fictional local files dropped on purpose) | Confirm **[NEEDS YOU]** |
| 18 | Medium | **Accessibility not done** | Only `relativeTo:` Dynamic Type scaling in fonts, `accessibilityLabel`s on logo/picker. Nothing audited; Reduce Motion is honoured only by the splash/reveal (via `animated`) | Phase 3 QA |
| 19 | Medium | **Performance unmeasured** | No Instruments/profiling; `RadarLogoCanvas` draws up to ≈20 bands × 8 copies per frame during the 0.95 s reveal (not measured) | Profile after build |
| 20 | Medium | **Release-build exposure of design-review controls** | `FeatureFlagControls` would let any user override flags locally if shipped | Wrap in `#if DEBUG`/build flag when mounting **[NEEDS YOU]** to confirm |
| 21 | Medium | **Privacy / compliance not addressed** | No `PrivacyInfo.xcprivacy`; anon key will sit in Info.plist (public by design, but must be the publishable key only); local file import uses security-scoped URLs (handled in code, untested) | Review before TestFlight |
| 22 | Low | **Haptics** | UIKit generators only; no CoreHaptics; global enable flag only | — |
| 23 | Low | **`V8RandomSort` is unproven and unused** | No JS-generated permutations to test against | Generate vectors from the bundle's `yi` generator |
| 24 | Low | **Two glitch vocabularies** | Brand speed-smear (done) vs artifact RGB-split/scanlines/grain (not done) | `DESIGN_SPEC.md` §13 |
| 25 | Low | **Seed 7 and 64%/+34 px icon placement are my choices** | Picked by eye | Approve or change **[NEEDS YOU]** |
| 26 | Low | **`docs/feature-flags-and-app-icons.md` duplicates parts of this handoff** | Risk of drifting apart | Keep one |

## Phase 02 brief — requirement status

| Brief section | Status |
|---|---|
| 1. Repository inspection + plan | Done (repo was empty; plan delivered in chat) |
| 2. Native implementation (Swift/SwiftUI/AVFoundation/async) | Partial — services + brand only; no UI shell; AVFoundation used only for import/waveform |
| 3. Visual fidelity (type, palette, artwork, glitch, rows, nav, players, gestures) | Partial — palette, type, icons, logo, brand-glitch only |
| 4. Architecture (App/Core/DesignSystem/Features/Services/Models/Resources) | Partial — `App`, 5 of 6 `Features` folders and most of `DesignSystem` absent |
| 5. Functional behaviour (nav, search, queue, playlists, library, local audio, player, settings) | Logic for search/library/playlists/settings/downloads exists; **no UI or player**; queue logic not ported |
| 6. Performance & accessibility | Not started |
| 7. Testing (build, navigation, player, persistence, gestures, device sizes, screenshots) | 29 tests written, 0 run; nothing else |
| 8. Delivery (Xcode project, screens, design system, assets, docs, build/test instructions) | Assets + partial design system + this documentation; **no project, no screens, no build instructions verified** |

## Things that look finished but are not
- "Glitch app icon behind a remote flag" — the art is finished; the gate has no backend, no refresh call, and no screen.
- "Splash" — a view exists; nothing shows it.
- "Local audio import" — a service exists; nothing calls it and nothing can play the result.
- "Parity fixtures" — generated; no test reads them.
