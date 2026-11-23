import Foundation

/// Design tokens and pure timing functions for the artifact's "FX" vocabulary (RGB-split,
/// scanlines, grain, ping, EQ, skeleton scan). Kept free of SwiftUI so every curve is unit-tested
/// against the CSS keyframes it was ported from (`index-BqwRgFdI.css`).
enum FX {
    static let rgb: Double = 2            // --fx-rgb
    static let rgbStrong: Double = 4      // --fx-rgb-strong
    static let grain: Double = 0.5        // --fx-grain
    static let scan: Double = 0.05        // --fx-scan (scanline alpha)
    static let scanPitch: Double = 3      // --fx-scan-pitch
    static let burst: Double = 0.38       // --m-burst (seconds)
}

/// CSS `cubic-bezier(x1, y1, x2, y2)` timing function.
struct CubicBezier: Sendable {
    let x1, y1, x2, y2: Double

    static let ease = CubicBezier(x1: 0.2, y1: 0.8, x2: 0.2, y2: 1)          // --m-ease
    static let easeOut = CubicBezier(x1: 0.16, y1: 1, x2: 0.3, y2: 1)        // --m-ease-out
    static let easeInOut = CubicBezier(x1: 0.65, y1: 0, x2: 0.35, y2: 1)     // --m-ease-in-out
    static let spring = CubicBezier(x1: 0.34, y1: 1.35, x2: 0.64, y2: 1)     // --m-spring

    func value(at x: Double) -> Double {
        if x <= 0 { return 0 }
        if x >= 1 { return 1 }
        // Solve bezierX(t) = x by bisection (robust; 40 iterations is far below a pixel).
        var lo = 0.0, hi = 1.0, t = x
        for _ in 0..<40 {
            t = (lo + hi) / 2
            if sample(t, x1, x2) < x { lo = t } else { hi = t }
        }
        return sample(t, y1, y2)
    }

    private func sample(_ t: Double, _ a: Double, _ b: Double) -> Double {
        let u = 1 - t
        return 3 * u * u * t * a + 3 * u * t * t * b + t * t * t
    }
}

// MARK: - RGB-split slices (`.glitch:before/:after`, `@keyframes slice-a/slice-b`)

/// A clipped band of the text: `top`/`bottom` are CSS `inset(top 0 bottom)` fractions of the
/// height (0…1) and `dx` the horizontal shift in points.
struct SliceFrame: Equatable, Sendable {
    var top: Double, bottom: Double, dx: Double
}

enum GlitchSlice {
    enum Layer { case a, b }   // a = ::before (accent), b = ::after (signal)

    /// Resting position (what the CSS draws when no animation runs).
    static func rest(_ layer: Layer, rgb: Double = FX.rgb) -> SliceFrame {
        switch layer {
        case .a: SliceFrame(top: 0.24, bottom: 0.68, dx: -rgb * 1.2)
        case .b: SliceFrame(top: 0.66, bottom: 0.24, dx: rgb)
        }
    }

    /// `animation: slice-x var(--m-burst) steps(1, end) 1` — each keyframe holds until the next
    /// one; the final keyframe (100%) is only reached when the animation ends.
    static func frame(_ layer: Layer, progress p: Double, rgb: Double = FX.rgb) -> SliceFrame {
        guard p < 1 else { return rest(layer, rgb: rgb) }
        let keys: [(Double, SliceFrame)]
        switch layer {
        case .a:
            keys = [(0, SliceFrame(top: 0.06, bottom: 0.78, dx: -7)), (0.18, SliceFrame(top: 0.44, bottom: 0.30, dx: 5)),
                    (0.36, SliceFrame(top: 0.72, bottom: 0.06, dx: -5)), (0.58, SliceFrame(top: 0.24, bottom: 0.50, dx: 3))]
        case .b:
            keys = [(0, SliceFrame(top: 0.66, bottom: 0.10, dx: 6)), (0.22, SliceFrame(top: 0.08, bottom: 0.76, dx: -6)),
                    (0.44, SliceFrame(top: 0.50, bottom: 0.28, dx: 4)), (0.66, SliceFrame(top: 0.82, bottom: 0.02, dx: -3))]
        }
        return keys.last(where: { $0.0 <= max(0, p) })!.1
    }
}

// MARK: - Burst (`@keyframes burst`: fx-3 → fx-1 → fx-2 → fx-1 → none, `step-end`)

struct BurstStep: Equatable, Sendable {
    /// Channel offset in points (red moves −dx, blue +dx).
    var dx: Double
    /// `fx-3` also tears the picture with a vertical-frequency displacement map.
    var tear: Bool
}

enum FXBurstTiming {
    static func step(progress p: Double) -> BurstStep? {
        guard p >= 0, p < 1 else { return nil }
        if p < 0.22 { return BurstStep(dx: 6, tear: true) }
        if p < 0.44 { return BurstStep(dx: 2, tear: false) }
        if p < 0.66 { return BurstStep(dx: 4, tear: false) }
        return BurstStep(dx: 2, tear: false)
    }

    /// Stand-in for `feTurbulence baseFrequency="0 0.06" seed=3`: a deterministic horizontal
    /// displacement per band, in points, within ±scale/2 (the filter's `scale` is 14).
    static func tearOffsets(bands: Int, scale: Double = 14) -> [Double] {
        var rng = SeededRandom(seed: 3)
        var previous = rng.next()
        return (0..<bands).map { _ in
            let next = rng.next()
            defer { previous = next }
            // Smooth along y like low-frequency noise: average with the previous sample.
            return ((previous + next) / 2 - 0.5) * scale
        }
    }
}

// MARK: - EQ bars (`.eq`, `@keyframes eq`)

enum EQTiming {
    static let rest: [Double] = [0.45, 0.85, 0.60, 0.35]      // static heights of the 4 bars
    static let delays: [Double] = [0, -0.3, -0.6, -0.15]       // animation-delay (s)

    /// Height fraction of bar `index` at `time` seconds: `0.9s steps(6,end) infinite`,
    /// keyframes 0%/100% = 25%, 50% = 100%.
    static func height(bar index: Int, time: Double, playing: Bool) -> Double {
        guard playing else { return rest[index] }
        let period = 0.9
        var t = (time - delays[index]).truncatingRemainder(dividingBy: period) / period
        if t < 0 { t += 1 }
        func stepped(_ x: Double) -> Double { (x * 6).rounded(.down) / 6 }
        if t < 0.5 { return 0.25 + 0.75 * stepped(t / 0.5) }
        return 1 - 0.75 * stepped((t - 0.5) / 0.5)
    }
}

// MARK: - Ping (`@keyframes ping`, 3.2 s, ease) and skeleton scan (`@keyframes scan`)

enum PingTiming {
    static let duration = 3.2
    /// (opacity, scale) of the expanding ring at `time` seconds.
    static func state(time: Double) -> (opacity: Double, scale: Double) {
        var p = time.truncatingRemainder(dividingBy: duration) / duration
        if p < 0 { p += 1 }
        guard p < 0.7 else { return (0, 3.2) }
        let e = CubicBezier.ease.value(at: p / 0.7)
        return (0.9 * (1 - e), 1 + 2.2 * e)
    }
}

enum SkeletonTiming {
    static let duration = 1.3
    /// Horizontal position of the sweep, as a multiple of the sweep's own width, starting at −1
    /// and ending at 2.6: `1.3s steps(16,end) infinite`.
    static func offset(time: Double) -> Double {
        var p = time.truncatingRemainder(dividingBy: duration) / duration
        if p < 0 { p += 1 }
        return -1 + 3.6 * (p * 16).rounded(.down) / 16
    }
}
