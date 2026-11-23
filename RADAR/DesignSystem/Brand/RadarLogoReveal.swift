import SwiftUI

/// One frame of the glitched → clean logo transition.
struct RevealFrame: Equatable, Sendable {
    var glitch: Double
    var tint: Double
    /// Which stepped glitch layout is showing (0 = the opening hold). Each step re-rolls the streaks.
    var step: Int

    static let clean = RevealFrame(glitch: 0, tint: 1, step: 0)
}

/// Choreography of the reveal: the logo opens fully glitched (all mint, long left-hand
/// streaks), the streaks snap shorter in stepped, re-rolled frames — hard cuts, like the
/// web build's `steps(1, end)` slice animation — and finally the brand colors resolve.
enum RadarReveal {
    static let duration = 0.95
    private static let hold = 0.18
    private static let stepLength = 0.07
    private static let levels: [Double] = [0.9, 1.0, 0.65, 0.8, 0.4, 0.5, 0.2, 0.1]
    /// When the hold ends, in seconds, for haptic timing.
    static let colorResolveTime = 0.8

    static func frame(at time: Double) -> RevealFrame {
        if time >= duration { return .clean }
        let t = max(0, time)
        var glitch = 1.0
        var step = 0
        let glitchEnd = hold + stepLength * Double(levels.count)
        if t >= glitchEnd {
            glitch = 0
            step = levels.count + 1
        } else if t >= hold {
            let i = min(Int((t - hold) / stepLength), levels.count - 1)
            glitch = levels[i]
            step = i + 1
        }
        return RevealFrame(glitch: glitch, tint: smoothstep((t - 0.42) / 0.38), step: step)
    }

    static func seed(forStep step: Int) -> UInt32 {
        GlitchSpec.defaultSeed &+ UInt32(truncatingIfNeeded: step) &* 7919
    }

    private static func smoothstep(_ x: Double) -> Double {
        let k = max(0, min(1, x))
        return k * k * (3 - 2 * k)
    }
}

/// The RADAR logo resolving from its glitched form into the clean mark.
///
/// Pass `animated: false` (Reduce Motion, or Signal effects switched off) to show the
/// clean logo immediately. Change `replay` to run it again.
struct RadarLogoReveal: View {
    var layout: RadarLogoCanvas.Layout = .lockup
    var height: CGFloat = 60
    var animated = true
    var replay = 0
    var onFinished: (() -> Void)?

    @State private var startedAt: Date?
    @State private var finished = false

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: finished || !animated)) { timeline in
            let frame = currentFrame(at: timeline.date)
            RadarLogoCanvas(
                layout: layout,
                height: height,
                glitch: frame.glitch,
                tint: frame.tint,
                seed: RadarReveal.seed(forStep: frame.step)
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("RADAR")
        .task(id: replay) { await run() }
    }

    private func currentFrame(at date: Date) -> RevealFrame {
        guard animated, !finished else { return .clean }
        guard let startedAt else { return RadarReveal.frame(at: 0) }
        return RadarReveal.frame(at: date.timeIntervalSince(startedAt))
    }

    @MainActor
    private func run() async {
        guard animated else {
            finished = true
            onFinished?()
            return
        }
        finished = false
        startedAt = .now
        try? await Task.sleep(for: .seconds(RadarReveal.colorResolveTime))
        if Task.isCancelled { return }
        Haptics.play(.light)
        try? await Task.sleep(for: .seconds(RadarReveal.duration - RadarReveal.colorResolveTime))
        if Task.isCancelled { return }
        finished = true
        onFinished?()
    }
}

private struct RevealPreview: View {
    @State private var replay = 0

    var body: some View {
        VStack(spacing: 40) {
            RadarLogoReveal(height: 60, replay: replay)
            Button("Replay") { replay += 1 }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.radarCharcoal)
    }
}

#Preview("Reveal") {
    RevealPreview()
}
