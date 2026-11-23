# RADAR

Native iOS music-discovery app (SwiftUI). Phase 02: turning the approved Phase 01 design artifact into a real iOS app.

> **Status: foundation only. Nothing in this repository has been compiled, run, or tested on a simulator or device.** The environment that wrote it has no Xcode. See `docs/handoff/phase-2/KNOWN_ISSUES.md` and `docs/PLATFORM_REQUIREMENTS.md` §9.

## Platform requirements

| | |
|---|---|
| **Minimum deployment target** | **iOS 17.0** — never raised just because development happens on a newer OS |
| **Manual testing / design target** | **iOS 27** (the owner tests only on iOS 27) |
| **Build with** | **Xcode 27.1 or later** (iPhone Duo simulator; iOS 27.1 layout APIs) |
| **Compatibility rule** | any API newer than iOS 17 is behind an availability check **with a real iOS 17 fallback**; differences are listed in `docs/PLATFORM_REQUIREMENTS.md` §11 |
| **Devices** | standard iPhones · **iPhone Duo** closed (5.4″) and unfolded (7.6″) · **13″ iPad Air** · **13″ iPad Pro** (portrait + landscape, multitasking, resizable windows) |
| **Layout rule** | decided from the **container size** only — never device model, idiom, orientation or `UIScreen` |

Full detail, verified Apple sources, the API-availability register, layout environments and the test plan: **[`docs/PLATFORM_REQUIREMENTS.md`](docs/PLATFORM_REQUIREMENTS.md)**.

**Device support is not complete** until every layout has been inspected and navigation, playback, resizing and transitions have been tested (that file's §9.3). None has been.

## Build (not yet done by anyone)

```sh
brew install xcodegen
cp Config/Local.xcconfig.example Config/Local.xcconfig     # set bundle id + team
xcodegen generate                                          # → RADAR.xcodeproj
open RADAR.xcodeproj                                       # Xcode 27.1+
```
`project.yml` and `Config/*.xcconfig` encode the requirements above (deployment target 17.0, iPhone + iPad, no orientation lock, no full-screen requirement). They have been checked only as valid YAML.

First run: the app opens the temporary **Layout Lab** (`RADAR/Features/Lab/LayoutLabView.swift`) — use it on every iOS 27 simulator/device to read real point sizes and to test state preservation while folding or resizing.

## Repository map

```
RADAR/            app source (Core, Models, Services, DesignSystem, Layout, Features, App, Resources)
RADARTests/       XCTest (46 test methods, never run) + JSON fixtures
Config/           xcconfig (deployment target, device family, icons, flags)
project.yml       XcodeGen spec
tools/            generators + tools/check-availability.py (iOS 17 / Duo anti-pattern lint)
docs/             PLATFORM_REQUIREMENTS.md · handoff/phase-2/ · brand/ · reference/
```

## Checks you can run without Xcode

```sh
python3 tools/check-availability.py      # newer-than-iOS-17 APIs without guards; Duo anti-patterns
```
(a lint, not a compiler — the real gate is building with `IPHONEOS_DEPLOYMENT_TARGET = 17.0`).

## Where to read next
1. `docs/PLATFORM_REQUIREMENTS.md` — what RADAR must run on and how it adapts
2. `docs/handoff/phase-2/README.md` — what Phase 2 built, reading order, what's unfinished
3. `docs/handoff/phase-2/BUILD_STATUS.md` — how to get to a first build
