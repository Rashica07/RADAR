# DESIGN_SPEC

Exact values as they exist in code/assets, with the sheet measurements they were fitted to. Source of truth for the visual identity is the Phase 01 artifact (tokens, behaviour) and the brand sheets you supplied (logo). `[VERIFIED]` = measured by a script run in this session; `[ASSUMPTION]` = my decision.

## 1. Sources

| Source | What it governs | Copy in this zip |
|---|---|---|
| Phase 01 artifact `Js5gigTTofFCDwYCoWtWKW` v`1795423913-ab52` | colours, type, spacing, motion, haptics, screens | `reference/artifact-screenshots/` |
| Brand sheet 1 (first upload) | logo v1 (superseded) | `reference/brand-sheets/brand-sheet-1-v1-logo.png` |
| Brand sheet 2 (1536×1024) | **logo v2** — primary logo, symbol, wordmark, monochrome, icons, palette, type | `…/brand-sheet-2-v2-logo.png` |
| Brand sheet 3 (1536×1024) | **glitched logo** and glitched icons | `…/brand-sheet-3-glitch.png` |

All three sheets are raster, AI-generated images; they are internally inconsistent (e.g. the two R's differ, the glitch icon on sheet 3 has a border). The code's vectors are *fitted traces*.

## 2. Colour

### Brand (fixed)
| Name | Hex | Swift |
|---|---|---|
| Mint | `#79E2C0` | `RadarRGB.mint` / `Color.radarMint` |
| Coral | `#FF7F76` | `.coral` / `.radarCoral` |
| Charcoal | `#101413` | `.charcoal` / `.radarCharcoal` |
| Warm white | `#F1F0E9` | `.warm` / `.radarWarm` |
| Graphite | `#252B29` | `.graphite` / `.radarGraphite` |

### Theme (asset catalog `Theme/<name>`; from artifact tokens)
| Token | Dark | Paper (light) |
|---|---|---|
| bg | `#101413` | `#F1F0E9` |
| surface / surface2 / surface3 | `#171D1B` / `#252B29` / `#313835` | `#E9E7DC` / `#DFDCCF` / `#D0CDBD` |
| text / text2 / text3 | `#F1F0E9` / `#BABCB3` / `#8F938B` | `#101413` / `#3B4440` / `#59635D` |
| line / lineStrong | `#F1F0E9` @ 8% / 18% | `#101413` @ 10% / 22% |
| accent / onAccent | `#79E2C0` / `#101413` | `#79E2C0` / `#101413` |
| accentText | `#79E2C0` | `#0A6B50` |
| accentSoft | `#79E2C0` @ 14% | `#0A6B50` @ 12% |
| signal / onSignal | `#FF7F76` / `#101413` | `#FF7F76` / `#101413` |
| signalText | `#FF8A81` | `#AB2B25` |
| signalSoft | `#FF7F76` @ 15% | `#B5302A` @ 12% |
| scrim | `#080A09` @ 72% | `#F1F0E9` @ 82% |
| navBg | `#0D1110` | `#ECEADF` |
| LaunchBackground | `#101413` (both appearances) | |

Alpha values were converted to 8-bit hex and checked by hand against the artifact (e.g. 0.72 → `B8`, 0.82 → `D1`). `[UNVERIFIED]` in Xcode.

## 3. Typography (from artifact tokens)

| Voice | Family / weights | Use | Swift |
|---|---|---|---|
| Display | Big Shoulders Display 700/800/900, uppercase, line-height ≈ 0.82–0.9 | headlines, ranks, numbers | `RadarFont.display` |
| UI | Space Grotesk 500/600/700 | titles (17 pt), labels, readouts (11 pt, +0.13 em), buttons | `RadarFont.ui` |
| Body | Inter 400/500/600/700 | reading text 15 pt, small figures | `RadarFont.body` |

Artifact sizes: hero `clamp(76px, 26vw, 176px)`, display-L `clamp(56px,17vw,104px)`, display-M `clamp(40px,11vw,56px)`, display-S 28, title 17, body 15, label/readout 11. (Not yet applied: no screens exist.)

## 4. Logo geometry

### 4.1 Symbol — box **361 × 207**, baseline y = 207
SVG path data, exactly as in `tools/brand.js` / `RadarBrandPaths.swift`:

| Piece | Colour (clean) | Path |
|---|---|---|
| `outer` (top bar + big arc) | mint | `M133 0 L225 0 A136 126 0 0 1 329 207 L320 207 A113 113 0 0 0 215 52 L79 52 Z` |
| `signal` (middle arc) | coral | `M130 92 Q150 74 200 70 A101 95 0 0 1 290.6 207 L250.3 207 A75 75 0 0 0 184 97 Q155 93 130 92 Z` |
| `signalHeadClip` (region of `signal` drawn **warm white**) | warm white | `M0 0 H317 L86 207 H0 Z` — everything left of a diagonal from (317,0) to (86,207) |
| `core` (small arch) | mint | `M159 207 L159 185 A53 37 0 0 1 212 148 L212 207 Z` |
| `leg` (rising stride) | mint | `M0 207 L87 207 L158 144 Q175 135 195 133 Q168 114 130 115 Q100 117 82 131 Z` |

### 4.2 Wordmark "RΛDΛR" — box **859 × 118** (cap height 118)
| Part | Path | Notes |
|---|---|---|
| R body (even-odd) | `M0 0 H104 A41 41 0 0 1 104 82 H32 V118 H0 Z` + counter `M32 29 H98 A14 14 0 0 1 98 57 H32 Z` | stem 32 wide, top bar 29 tall, bowl radius 41, counter radius 14 |
| R leg (non-zero) | `M40 57 H82 L148 118 H102 Z` | separate shape so it isn't cancelled by even-odd where it overlaps the bowl |
| A (no crossbar) | `M0 118 L71 0 H111 L182 118 H145 L91 28 L37 118 Z` | flat top 40 wide, feet 37 wide, inner apex at (91,28) |
| D (even-odd) | `M0 0 H96 A59 59 0 0 1 96 118 H0 Z` + counter `M33 29 H91 A29 29 0 0 1 91 87 H33 Z` | |
| Letter origins (x) | R 0 · A 158 · D 358 · A 516 · R 711 | total width 859 |

### 4.3 Lockup (brand-sheet "primary logo")
`wordScale = 207 × 0.57 / 118 = 0.99992` · `gap = 207 × 0.34 = 70.38` · wordmark origin `(361 + gap, (207 − 118·scale)/2 + 207 × 0.036) = (431.38, 51.957)` · lockup box **1291 × 207** (`ceil`). Sheet check: wordmark cap 118 vs symbol height 207 (ratio 0.57) — measured on sheet 2.

### 4.4 Fit to sheet 2 `[VERIFIED]`
Ad-hoc script (not in repo): my SVG rasterised at 1:1, sheet thresholded at luminance > 100, best integer shift in ±8 px.

| Mark | IoU | Best shift |
|---|---|---|
| Symbol | **0.957** | (0, 0) |
| Wordmark | **0.884** | (+8, +1) |

Known deviations of the wordmark (from row scans of the sheet; sheet x relative to the first R's left edge): sheet D stem 369–402 vs code 358–391; sheet A feet 165–202 / 313–351 vs code 158–195 / 303–340; first R ≈150 wide and last R ≈128 wide on the sheet, but code uses one 148-wide R twice; total 847 (sheet) vs 859 (code). **Placeholder until the Illustrator redraw.**

## 5. App icons

| | Standard | Glitch |
|---|---|---|
| File | `AppIcon-1024.png` | `AppIconGlitch-1024.png` |
| Canvas | 1024×1024, `#101413` | 1024×1024, `#101413` |
| Symbol scale | `s = 1024 × 0.64 / 361 = 1.8154` (655.4 × 375.8 px) | same |
| Translate | `(184.32, 332.11)` = `(512 − 361s/2, 512 − 207s/2 + 8)` | `(218.32, 332.11)` (+34 px x) |
| Colours | full colour (white head, coral, mint) | **all mint `#79E2C0`** + streaks |
| Previews | `IconPreviewDefault.png` 512 | `IconPreviewGlitch.png` 512 |

iOS applies the rounded-square mask; the images are full-bleed squares. `[ASSUMPTION]` charcoal `#101413` rather than the sheet's pure black. No iOS 18 tinted/dark-specific artwork exists (the `dark` entry reuses the same PNG).

## 6. The brand glitch ("speed smear")

What sheet 3 shows `[VERIFIED by zoom + row scans]`:
- Entire mark is **mint** (no coral, no white head); wordmark also mint.
- Streaks are **horizontal trails to the left** of left-facing edges: strongest at the top bar (trail ≈ 55 px on a ≈485 px symbol ≈ 11%) and the leg (≈ 105 px ≈ 22%); negligible mid-height; a few short ticks to the right of the big arc.
- Wordmark: small notches along letter tops and short streaks at the far left of the first R and far right of the last R.

**Implemented:** the symbol streaks and the wordmark end-streaks. **Not implemented:** the notches along letter tops `[NOT DONE]`.

## 7. Glitch parameters

| Constant | Value | Where |
|---|---|---|
| Band height | `1.5 + r·5.5` units | `GlitchSpec.bands` |
| Weight | `0.10 + 0.90·max(bump(y/H; 0.20, 0.13), bump(y/H; 0.93, 0.12))` | |
| Activity | `r1 < 0.10 + 0.75·weight` | |
| Length | `amount · maxLength · weight · (0.25 + 0.75·r2)` | |
| `maxLength` (symbol) | `0.22 × 361 = 79.42` units (`symbolMaxLengthFactor`) | |
| `maxLength` (wordmark left / right) | 46 / 34 units; right amount × 0.7; seeds `seed+101` / `seed+202` | `RadarLogoCanvas.drawWordmark` |
| Trail copies | 8, offsets `−length·k/8`, k = 1…8 | |
| Trail opacity `(1−k/8)^0.8 × 0.95` | 0.8537, 0.7547, 0.6523, 0.5456, 0.4335, 0.3134, 0.1800, 0.0000 | |
| Right tick | bands with length > 12% of symbol width (43.3): copy at `+0.1·length`, opacity 0.6 | |
| Default seed | **7** (`GlitchSpec.defaultSeed`) | |

### 7.1 Seed 7 — symbol, `amount = 1`, `maxLength = 79.42` `[VERIFIED]` (computed by `tools/glitch.js`)

48 bands tile the height exactly (sum of heights 207.000); **20 are active** (length > 0.5). Last column converts to pixels in the 1024 icon (× 1.8154).

| # | y (units) | h | length | y/207 | length @1024 icon px |
|---|---|---|---|---|---|
| 1 | 0.00 | 1.56 | 15.00 | 0.000 | 27 |
| 2 | 6.91 | 4.06 | 16.38 | 0.033 | 30 |
| 3 | 10.97 | 5.51 | 12.03 | 0.053 | 22 |
| 4 | 16.49 | 5.70 | 17.68 | 0.080 | 32 |
| 5 | 22.19 | 3.52 | 35.73 | 0.107 | 65 |
| 6 | 28.84 | 6.33 | 25.48 | 0.139 | 46 |
| 7 | 35.17 | 2.35 | 50.85 | 0.170 | 92 |
| 8 | 37.52 | 5.69 | **74.14** | 0.181 | 135 |
| 9 | 43.21 | 4.55 | 59.13 | 0.209 | 107 |
| 10 | 47.76 | 6.81 | 66.43 | 0.231 | 121 |
| 11 | 54.57 | 6.05 | 21.99 | 0.264 | 40 |
| 12 | 60.62 | 3.46 | 12.44 | 0.293 | 23 |
| 13 | 75.29 | 3.46 | 7.12 | 0.364 | 13 |
| 14 | 142.69 | 4.97 | 7.02 | 0.689 | 13 |
| 15 | 163.66 | 4.62 | 16.83 | 0.791 | 31 |
| 16 | 181.33 | 4.19 | 48.49 | 0.876 | 88 |
| 17 | 191.40 | 4.55 | **51.06** | 0.925 | 93 |
| 18 | 195.95 | 2.49 | 44.55 | 0.947 | 81 |
| 19 | 198.44 | 4.13 | 18.27 | 0.959 | 33 |
| 20 | 202.57 | 2.45 | 21.84 | 0.979 | 40 |

Peaks: y/H 0.05–0.35 → **74.1** · 0.45–0.65 → **0.0** · 0.80–1.00 → **51.1** (this is the property `GlitchTests.testLongestTrailsSitAtTheTopBarAndTheLeg` asserts; it was verified in JS with `maxLength = 80`: 74.7 / 0 / 51.4).

Seed choice `[ASSUMPTION]`: candidates 3, 7, 11, 19, 23, 42 were rendered; 7 chosen by eye. Seeds for the reveal steps: `7 + step × 7919` → 7, 7926, 15845, 23764, 31683, 39602, 47521, 55440, 63359, 71278.

## 8. Reveal timeline (glitched → clean) — `RadarReveal`

`duration = 0.95 s` · `hold = 0.18 s` · `stepLength = 0.07 s` · glitch levels `[0.9, 1.0, 0.65, 0.8, 0.4, 0.5, 0.2, 0.1]` (stepped, hard cuts) · streaks end at `0.18 + 8×0.07 = 0.74 s` · `tint = smoothstep((t − 0.42)/0.38)` (starts 0.42 s, complete 0.80 s) · haptic `.light` at 0.80 s.

| t (s) | glitch | tint | step (seed index) |
|---|---|---|---|
| 0.00 | 1 | 0.000 | 0 |
| 0.10 | 1 | 0.000 | 0 |
| 0.18 | 0.9 | 0.000 | 1 |
| 0.25 | 1.0 | 0.000 | 2 |
| 0.32 | 0.65 | 0.000 | 3 |
| 0.46 | 0.4 | 0.031 | 5 |
| 0.60 | 0.5 | 0.461 | 6 |
| 0.74 | 0 | 0.933 | 9 |
| 0.80 | 0 | 1.000 | 9 |
| ≥ 0.95 | 0 | 1 | clean |

Values computed from the same constants in Node (a re-implementation of `frame(at:)`); the Swift function itself has not run. Design intent: streaks snap in *hard cuts* (like the artifact's `steps(1,end)` slice animation) — they do not ease. Colour resolves *while* the last streaks vanish.

## 9. Splash
Charcoal `LaunchBackground`; lockup width `min(0.78 × screen width, 520)`; reveal 0.95 s; hold 0.35 s (0.6 s with no animation); fade-out 0.3 s ease-out → total ≈ 1.6 s animated. Reduce Motion or Signal effects off ⇒ clean logo, no glitch, no haptic. `[NOT DONE]` integration.

## 10. Icon set
44 icons, 24×24 grid, stroke 1.75, round caps/joins; `discover-fill` uses cut strokes in the surface colour (`radarIconCut`).

## 11. Motion & haptic tokens (from the artifact; not yet used in screens)
Durations fast 120 ms, base 220, slow 380, burst 380, expand 480. Easings: ease `(0.2,0.8,0.2,1)`, ease-out `(0.16,1,0.3,1)`, ease-in-out `(0.65,0,0.35,1)`, spring `(0.34,1.35,0.64,1)`. Haptics: tick→selection, select/light→light impact, medium→medium impact, success/warning→notification.

## 12. Layout tokens (from the artifact; not yet used)
Gutter 16 · row 60 (compact 52) · row art 52 (compact 42) · nav 58 · mini-player 68 (+14 waveform strip) · touch target 44 · radii: art 0, control 2, card 0, pill 999.

## 13. Two glitch vocabularies — only one is built
1. **Artifact glitch (RGB split)** — headlines and artwork: two offset copies in mint/coral clipped to bands (`±2/4 px`), animated `slice-a/slice-b` in hard steps; SVG filter bursts `fx-1…3` (R/B channel offsets 2/4/6 px, `feTurbulence` tear) on track change; scanlines (5% black, 3 px pitch) + grain on artwork. **Built in Phase 3 Step 3.2 (`RADAR/DesignSystem/FX/`).**
2. **Brand glitch (speed smear)** — the logo and Glitch icon (this phase). **Done (Swift `[UNVERIFIED]`).**

## 14. Design decisions and rationale
| Decision | Why |
|---|---|
| Logo drawn as vector `Canvas`, not images | sharp at any size; lets `glitch`/`tint` be continuous; one drawing for splash, headers, previews |
| Trails = clipped translated copies, not blur | keeps hard-edged streaks like the sheet; no offscreen buffers |
| Hard-cut steps, re-rolled per step | matches the artifact's stepped glitch character and the sheet's "data tearing" feel |
| Colour resolves late and overlaps the last streaks | reads as the signal "locking on" |
| Glitch icon shifted right | the streaks extend left; shifting keeps the visual mass centred and inside the safe area |
| Charcoal icon background | brand colour; pure black is not in the palette |
