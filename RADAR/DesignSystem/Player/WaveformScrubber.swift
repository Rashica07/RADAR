import SwiftUI

/// Seek bar drawn as a waveform. Touch tracks 1:1 from the first point (no slop, no jump to centre);
/// bars under the finger swell like a lens, a time bubble rides above it, and seeking commits on release.
/// `peaks == nil` means "still reading the file" and shows a skeleton instead of a blank bar.
struct WaveformScrubber: View {
    let peaks: [Double]?
    /// Current playback position, 0…1.
    let progress: Double
    let duration: TimeInterval
    var height: CGFloat = 56
    var onScrubChange: (Double) -> Void = { _ in }
    var onSeek: (Double) -> Void

    @State private var scrubbing: Double?
    @State private var lastTick = -1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let bar: CGFloat = 3, gap: CGFloat = 2
    private var shown: Double { scrubbing ?? progress }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let count = ScrubMath.barCount(width: width, bar: bar, gap: gap)
            ZStack(alignment: .topLeading) {
                if let peaks, !peaks.isEmpty {
                    let hs = ScrubMath.heights(peaks: peaks, count: count)
                    Canvas { ctx, size in draw(ctx, size, hs) }
                        .animation(nil, value: scrubbing)
                } else {
                    SkeletonBlock().frame(height: height * 0.5).frame(maxHeight: .infinity, alignment: .center)
                }
                if let s = scrubbing {
                    bubble(for: s, width: width)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        let f = ScrubMath.fraction(x: v.location.x, width: width)
                        scrubbing = f
                        onScrubChange(f)
                        let bucket = Int(f * Double(max(count - 1, 1)))
                        if bucket != lastTick { lastTick = bucket; Haptics.play(.tick) }
                    }
                    .onEnded { v in
                        let f = ScrubMath.fraction(x: v.location.x, width: width)
                        onSeek(f)
                        scrubbing = nil
                        lastTick = -1
                    }
            )
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityLabel("Seek")
        .accessibilityValue(ScrubMath.spokenValue(progress: progress, duration: duration))
        .accessibilityAdjustableAction { dir in
            let step = ScrubMath.step(duration: duration)
            switch dir {
            case .increment: onSeek(min(1, progress + step))
            case .decrement: onSeek(max(0, progress - step))
            @unknown default: break
            }
        }
    }

    private func draw(_ ctx: GraphicsContext, _ size: CGSize, _ hs: [Double]) {
        let n = hs.count
        let played = ScrubMath.playedCount(progress: shown, bars: n)
        let lens = scrubbing != nil && !reduceMotion
        for i in 0..<n {
            var h = hs[i] * Double(size.height) * 0.9
            if lens { h *= ScrubMath.lens(barIndex: i, centre: shown, bars: n) }
            h = min(max(h, 3), Double(size.height))
            let rect = CGRect(x: CGFloat(i) * (bar + gap), y: (size.height - h) / 2, width: bar, height: h)
            let colour = i < played ? Color.radarAccent : Color.radarText3.opacity(0.55)
            ctx.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(colour))
        }
        // Playhead hairline while scrubbing.
        if scrubbing != nil {
            let x = CGFloat(shown) * size.width
            ctx.fill(Path(CGRect(x: min(max(x - 0.5, 0), size.width - 1), y: 0, width: 1, height: size.height)), with: .color(.radarText))
        }
    }

    private func bubble(for f: Double, width: CGFloat) -> some View {
        let text = Format.time(f * duration)
        let x = min(max(CGFloat(f) * width, 26), width - 26)
        return Text(text)
            .font(RadarFont.ui(12, .bold, relativeTo: .caption)).monospacedDigit()
            .foregroundStyle(Color.radarOnAccent)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Color.radarAccent)
            .position(x: x, y: -14)
            .allowsHitTesting(false)
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }
}

/// Time labels under the scrubber: elapsed left, remaining right, tabular digits.
struct ScrubTimes: View {
    let progress: Double
    let duration: TimeInterval
    var body: some View {
        HStack {
            Text(Format.time(progress * duration))
            Spacer()
            Text("-" + Format.time((1 - progress) * duration))
        }
        .font(RadarFont.body(12, .medium, relativeTo: .caption)).monospacedDigit()
        .foregroundStyle(Color.radarText2)
        .accessibilityHidden(true)
    }
}
