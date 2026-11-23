#!/usr/bin/env python3
"""
RADAR platform guard: iOS 17.0 deployment target, iOS 27.x development/testing.

Scans Swift sources for
  1. APIs newer than iOS 17 used WITHOUT an availability guard   (error)
  2. layout anti-patterns that break on iPhone Duo / iPad windowing (error)
  3. size-class / idiom checks that need a human look               (warning)

THIS IS A LINT, NOT A COMPILER. The real gate is building with a deployment target of
17.0: the Swift compiler rejects unguarded use of any newer API. This script exists
because the code is authored on machines that cannot compile Swift, and to catch Duo
anti-patterns the compiler can't see.

Usage:  python3 tools/check-availability.py [paths...]      (default: RADAR RADARTests)
Exit status 1 if any error is found.

Sources for the lists (retrieved 2026-11-23):
  - iPhone Duo anti-patterns: developer.apple.com/iphone-duo/prepare/
  - iOS 27.1 availability of ArrangementView, reservedRegions, toolbarVerticalEdge:
    their API reference pages ("iOS 27.1+")
  - iOS 18 / 26 names: from the author's knowledge, NOT re-verified this session;
    treat as "probably newer than 17, confirm in the SDK before relying on it".
"""
import re
import sys
from pathlib import Path

# name -> (min OS, provenance)
NEWER_THAN_17 = {
    # iOS 27.1 — verified on the API reference pages
    r"\bArrangementView\b": ("27.1", "verified"),
    r"\barrangementViewStyle\b": ("27.1", "same family as ArrangementView; confirm"),
    r"\breservedRegions\b": ("27.1", "verified"),
    r"\bReservedRegion\b": ("27.1", "verified"),
    r"\btoolbarVerticalEdge\b": ("27.1", "verified"),
    # named in Apple's Duo guidance; minimum versions NOT verified — treat as new
    r"\btoolbarVerticalBehavior\b": ("27.x?", "unverified"),
    r"\bpresentationPlacement\b": ("27.x?", "unverified"),
    r"\baxisBehavior\b": ("27.x?", "unverified"),
    r"\bvisibilityPriority\b": ("27.x?", "unverified"),
    r"\bToolbarOverflowMenu\b": ("27.x?", "unverified"),
    r"\btopBarPinnedTrailing\b": ("27.x?", "unverified"),
    r"\bbackgroundExtensionEffect\b": ("26?", "unverified"),
    # iOS 26 (Liquid Glass era) — from memory
    r"\bglassEffect\b": ("26", "from memory"),
    r"\bGlassEffectContainer\b": ("26", "from memory"),
    r"\btabBarMinimizeBehavior\b": ("26", "from memory"),
    r"\bscrollEdgeEffect": ("26", "from memory"),
    # iOS 18 — from memory
    r"\bsidebarAdaptable\b": ("18", "from memory"),
    r"\.navigationTransition\(": ("18", "from memory"),
    r"\bMeshGradient\b": ("18", "from memory"),
    r"\bonScrollGeometryChange\b": ("18", "from memory"),
    r"\bpresentationSizing\b": ("18", "from memory"),
    r"\bTabSection\b": ("18", "from memory"),
    r"\bTab\(\s*\"": ("18", "from memory (Tab struct)"),
    r"\bonGeometryChange\b": ("16+ back-deployed? unverified", "use GeometryReader (iOS 13) instead"),
}

# Always wrong for RADAR, regardless of guards (Apple's iPhone Duo guidance)
ANTI_PATTERNS = {
    r"\bUIScreen\.main\b": "sizes must come from the view/window/scene (GeometryReader), never the main screen",
    r"\bUIDevice\.current\.orientation\b": "orientation does not describe the app's shape on iPhone Duo",
    r"\binterfaceOrientation\b": "orientation does not describe the app's shape on iPhone Duo",
    r"\bstatusBarOrientation\b": "orientation does not describe the app's shape on iPhone Duo",
    r"\buserInterfaceIdiom\b": "do not choose a layout by idiom (.phone/.pad)",
    r"\bUIDevice\.current\.model\b": "do not branch on device model",
    r"\bUIWindow\(frame:\s*UIScreen": "create windows from a scene",
}

# Needs a human: allowed only with a comment explaining why it is not 'iPad vs iPhone'
REVIEW = {
    r"\bhorizontalSizeClass\s*==": "regular width no longer means iPad; prefer RadarLayoutProfile (container-based)",
    r"\bverticalSizeClass\s*==": "any combination of size classes is possible on iPhone",
}

GUARD = re.compile(r"#available\s*\(\s*iOS|@available\s*\(\s*iOS|if\s+#unavailable|#if\s+compiler|#if\s+swift")
GUARD_WINDOW = 40  # lines


def strip(source: str) -> str:
    """Blank out comments and string literals so names inside them don't match."""
    source = re.sub(r"/\*.*?\*/", lambda m: re.sub(r"[^\n]", " ", m.group()), source, flags=re.S)
    source = re.sub(r"//[^\n]*", "", source)
    source = re.sub(r'"""(?:.|\n)*?"""', lambda m: re.sub(r"[^\n]", " ", m.group()), source)
    source = re.sub(r'"(?:\\.|[^"\\\n])*"', '""', source)
    return source


def main(paths):
    files = []
    for p in paths:
        p = Path(p)
        files += [p] if p.is_file() else sorted(p.rglob("*.swift"))
    errors, warnings = [], []
    for f in files:
        raw = f.read_text(encoding="utf-8", errors="ignore").splitlines()
        clean = strip("\n".join(raw)).splitlines()
        file_guard = any(re.search(r"@available\s*\(\s*iOS", l) for l in clean[:30])
        for i, line in enumerate(clean):
            for pat, (min_os, why) in NEWER_THAN_17.items():
                if re.search(pat, line):
                    window = clean[max(0, i - GUARD_WINDOW): i + 1]
                    if not (file_guard or any(GUARD.search(w) for w in window)):
                        errors.append(f"{f}:{i+1}: API newer than iOS 17 (min {min_os}, {why}) used without an availability guard: {line.strip()[:90]}")
            for pat, why in ANTI_PATTERNS.items():
                if re.search(pat, line):
                    errors.append(f"{f}:{i+1}: forbidden pattern — {why}: {line.strip()[:90]}")
            for pat, why in REVIEW.items():
                if re.search(pat, line):
                    warnings.append(f"{f}:{i+1}: review — {why}: {line.strip()[:90]}")
    print(f"scanned {len(files)} Swift files")
    for w in warnings:
        print("WARN ", w)
    for e in errors:
        print("ERROR", e)
    print(f"{len(errors)} error(s), {len(warnings)} warning(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:] or ["RADAR", "RADARTests"]))
