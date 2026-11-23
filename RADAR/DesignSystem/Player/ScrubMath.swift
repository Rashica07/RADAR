import Foundation
import CoreGraphics

/// Pure maths behind the waveform scrubber, kept apart from the view so it can be tested.
enum ScrubMath {
    /// 0…1 position for a touch at `x` inside a track of `width`; clamped, so dragging past either end holds the end.
    static func fraction(x: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return 0 }
        return Double(min(max(x / width, 0), 1))
    }

    /// How many bars fit: fixed bar + gap, never fewer than 1.
    static func barCount(width: CGFloat, bar: CGFloat = 3, gap: CGFloat = 2) -> Int {
        guard width > 0 else { return 0 }
        return max(1, Int(((width + gap) / (bar + gap)).rounded(.down)))
    }

    /// Bar heights (0…1) for `count` bars from any number of peaks.
    static func heights(peaks: [Double], count: Int) -> [Double] {
        guard count > 0, !peaks.isEmpty else { return [] }
        return DemoCatalog.bucket(peaks, bars: count)
    }

    /// Index of the first bar that is *not yet* played. Bar i counts as played once the playhead has passed its centre.
    static func playedCount(progress: Double, bars: Int) -> Int {
        guard bars > 0 else { return 0 }
        return min(bars, max(0, Int((progress * Double(bars)).rounded())))
    }

    /// Height multiplier for a bar near the finger while scrubbing: 1 far away, up to `peak` right under it.
    static func lens(barIndex: Int, centre: Double, bars: Int, radius: Double = 4, peak: Double = 1.35) -> Double {
        guard bars > 1 else { return 1 }
        let d = abs(Double(barIndex) - centre * Double(bars - 1))
        guard d < radius else { return 1 }
        let t = 1 - d / radius
        return 1 + (peak - 1) * (t * t * (3 - 2 * t))      // smoothstep
    }

    /// "1:23 of 3:45", spoken by VoiceOver on the adjustable control.
    static func spokenValue(progress: Double, duration: TimeInterval) -> String {
        "\(Format.time(progress * duration)) of \(Format.time(duration))"
    }

    /// One VoiceOver increment/decrement: 5 seconds, or 5 % when the track is short or unknown.
    static func step(duration: TimeInterval) -> Double {
        duration > 20 ? 5 / duration : 0.05
    }
}
