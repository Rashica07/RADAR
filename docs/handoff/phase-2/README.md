# RADAR — Phase 2 Handoff Package

**Phase:** 02 — Design artifact → production SwiftUI (native iOS)
**Written:** 2026-11-23, from an inspection of the actual repository and git state
**Repository:** https://github.com/Rashica07/RADAR (private) · **Default branch:** `main` @ `eecc676`
**Phase 2 code was merged by PR #1** (see `GIT_STATE.md`).

---

## Read this first — three facts

1. **Nothing in this repository has been compiled, run, or tested.** The environment that did this work is Linux with no Swift toolchain and no Xcode. The 29 XCTest methods exist but have never executed. Every "works" claim in these documents is tagged `[VERIFIED]`, `[UNVERIFIED]`, or `[NOT DONE]` — trust the tags.
2. **This is a foundation, not an app.** There is no Xcode project, no `@main` entry point, no screens, no player, no CI. What exists is the design system's brand/theme/icon layer, the data + service layer, the glitch→clean logo system, the alternate-icon feature and its remote flag, and tests for those.
3. **PR #1 (a work-in-progress, never compiled) is already merged into `main`.** `main` therefore contains uncompiled code, and PR #1's description is stale. This handoff is committed on the same branch name restarted from the merged `main`.

---

## Status at a glance

| Area | State | Evidence |
|---|---|---|
| Artifact analysed & reverse-engineered | Done | `[VERIFIED]` bundle downloaded, prettified, screenshotted at 393×852 |
| Fonts (10 static TTFs) | Done | `[VERIFIED]` converted; PostScript names + glyph coverage checked. `[UNVERIFIED]` loading in an app |
| Asset catalog (themes, icons, launch colour) | Authored | `[VERIFIED]` JSON valid. `[UNVERIFIED]` Xcode accepts it |
| Demo catalog + chart/search/related algorithms | Ported | `[UNVERIFIED]` — no Swift ran; no parity test consumes the fixtures |
| Core + Services (library, settings, downloads, local import) | Written | `[UNVERIFIED]` |
| Brand: symbol + wordmark (v2 trace) | Done (placeholder) | `[VERIFIED]` IoU vs sheet: symbol 0.957, wordmark 0.884 |
| Glitch spec + renderer + reveal + splash view | Written | JS twin `[VERIFIED]`; Swift `[UNVERIFIED]`; **splash not wired into any app** |
| Glitch alternate app icon (art) | Done | `[VERIFIED]` rendered + eyeballed. `[UNVERIFIED]` on device |
| Feature flags + icon picker | Written | `[UNVERIFIED]`; **no backend exists, `refresh()` is never called, picker not mounted** |
| Design-system components (rows, tiles, tabs, artwork, FX…) | **Not started** | — |
| Screens (Discover, Trending, Search, Library, Settings, details) | **Not started** | — |
| Player (queue, mini/expanded, AVFoundation, Now Playing) | **Not started** | — |
| Local audio *playback* | **Not started** (import service exists) | — |
| Xcode project, `@main`, Info.plist, CI | **Not started** | — |
| Screenshot comparison vs artifact | **Not started** | reference shots exist (see zip `reference/`) |

## Reading order

| # | File | Read it for |
|---|---|---|
| 1 | `README.md` | this page |
| 2 | `BUILD_STATUS.md` | what blocks a build and the exact steps to get one |
| 3 | `KNOWN_ISSUES.md` | everything incomplete, wrong, or needing attention |
| 4 | `GIT_STATE.md` | branch, commits, PR, working tree |
| 5 | `IMPLEMENTATION.md` | what was built, in detail |
| 6 | `ARCHITECTURE.md` | how the glitch renderer, JS/Swift spec, icon system, flags and splash fit together |
| 7 | `DESIGN_SPEC.md` | exact measurements, colours, seed 7, streak geometry, timeline |
| 8 | `FEATURE_FLAGS.md` | flag behaviour, Supabase expectations, SQL |
| 9 | `TESTING.md` | what was run vs. what was only written |
| 10 | `FILES_CHANGED.md` | every file with its purpose (generated from git) |
| 11 | `DEPENDENCIES.md` | tools, versions, environment |
| 12 | `PHASE_3_PLAN.md` | recommended order of work |

## Evidence legend (used in every document)

- `[VERIFIED]` — an executed command or an observed artefact backs the statement; the command/output is cited.
- `[UNVERIFIED]` — written but never compiled/executed; correctness is by inspection only.
- `[NOT DONE]` — does not exist.
- `[ASSUMPTION]` — a decision made without confirmation; may be wrong.

## What I need from you (manual input)

These block or shape the next phase. Details are in the linked file.

1. **Illustrator redraw of the logo** — symbol + wordmark as SVG, with layers named `outer`, `signal`, `core`, `leg`, `wordmark` (`DESIGN_SPEC.md` §Logo, `KNOWN_ISSUES.md` #8). My traces are placeholders.
2. **A way to compile Swift** — your Mac with Xcode, *or* approval to use a macOS GitHub Actions runner (metered; this repo is private) (`BUILD_STATUS.md`).
3. **Confirm what "the database" is.** You said the database gates the icon feature; I **assumed Supabase** (a connector is attached) and wrote the client for it. Provide the project URL + publishable key, *or* tell me to create the project/table, *or* name a different backend (`FEATURE_FLAGS.md`).
4. **App identity** — bundle identifier, Apple team, display name, minimum iOS version (I assumed iOS 17.0).
5. **Approve the glitch icon** (seed 7, chosen by me from 6 candidates) or pick another (`DESIGN_SPEC.md`).
6. **Product decisions** — whether the Settings "Design review controls" (incl. flag overrides) must be stripped from release builds (I recommend yes), and whether demo-data wording stays.
7. **Reference assets** — the three brand-sheet images you sent exist only in this session's upload folder; they are copied into this zip under `reference/`. Decide whether to commit them (≈2.8 MB) and how to credit/licence them. Also add the OFL licence texts for the three fonts (`KNOWN_ISSUES.md` #14).
8. **Merge etiquette** — PR #1 was merged while still marked WIP. Tell me whether you want future work merged only after a green CI build.

## Zip manifest

```
README.md  BUILD_STATUS.md  KNOWN_ISSUES.md  GIT_STATE.md  IMPLEMENTATION.md
ARCHITECTURE.md  DESIGN_SPEC.md  FEATURE_FLAGS.md  TESTING.md  FILES_CHANGED.md
DEPENDENCIES.md  PHASE_3_PLAN.md
reference/brand-sheets/        3 images you supplied in chat (v1 sheet, v2 sheet, glitch sheet)
reference/artifact-screenshots/ 11 screenshots of the Phase 01 web artifact at 393×852
reference/tools/               the Playwright scripts that produced them (not in the repo)
```

The same Markdown files are committed at `docs/handoff/phase-2/` in the repository.

## Do not do

- Do not treat the Swift as known-good. Expect compile errors on first build (`BUILD_STATUS.md` lists the likeliest).
- Do not rely on `docs/feature-flags-and-app-icons.md` for current behaviour without reading `KNOWN_ISSUES.md` #3 and #4 first.
- Do not start the Kotlin translation: the iOS implementation is not validated yet (your instruction from the Phase 02 brief).
