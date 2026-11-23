import SwiftUI

// MARK: - Settings

/// Whether decorative effects run. The app shell fills this from `SettingsStore` (`fx`, `reduceMotion`);
/// the system's Reduce Motion is honoured on top of it.
struct RadarFXEnvironment: Equatable, Sendable {
    var enabled = true
    var reducedMotion = false
}

extension EnvironmentValues {
    @Entry var radarFX = RadarFXEnvironment()
}

/// Shared constants for the effects.
enum FX {
    static let rgb: Double = 2          // resting channel offset, points
    static let grain: Double = 0.35
    static let scan: Double = 0.05      // scanline darkening
    static let scanPitch: Double = 3    // points between scanlines
    static let burst: Double = 0.38     // seconds
}

/// Hands a view the answer to "may I animate?" so each effect stays a few lines.
private struct MotionGate<Content: View>: View {
    @ViewBuilder var content: (_ visible: Bool, _ animated: Bool) -> Content
    @Environment(\.radarFX) private var fx
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    var body: some View { content(fx.enabled, fx.enabled && !(fx.reducedMotion || systemReduceMotion)) }
}

// MARK: - Cover film (grain + scanlines)

extension View {
    /// Film grain and faint scanlines over a cover, as one GPU pass (`Film.metal`).
    func artFX() -> some View { modifier(FilmModifier()) }
}

private struct FilmModifier: ViewModifier {
    @Environment(\.radarFX) private var fx
    func body(content: Content) -> some View {
        content.colorEffect(
            ShaderLibrary.radarFilm(.float(FX.scanPitch), .float(FX.scan), .float(FX.grain)),
            isEnabled: fx.enabled)
    }
}

// MARK: - Glitch data

/// A band of the text, as fractions of its height, and its horizontal shift in points.
struct SliceFrame: Equatable, Sendable {
    var top: Double, bottom: Double, dx: Double
}

/// The glitch's choreography: which band of the title each coloured copy shows, and where it
/// jumps, at each beat of a burst. Pure data so it can be tested; the beats are held, not tweened.
enum GlitchSlice {
    enum Layer { case a, b }   // a = accent copy, b = signal copy

    static func rest(_ layer: Layer, rgb: Double = FX.rgb) -> SliceFrame {
        switch layer {
        case .a: SliceFrame(top: 0.24, bottom: 0.68, dx: -rgb * 1.2)
        case .b: SliceFrame(top: 0.66, bottom: 0.24, dx: rgb)
        }
    }

    /// Frame at `progress` (0…1 through the burst). At 1 and beyond the copies are back at rest.
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

/// One beat of the channel-split burst on artwork.
struct BurstStep: Equatable, Sendable {
    var dx: Double      // red moves −dx, blue +dx
    var tear: Bool      // rips the picture into sideways-sliding bands
}

enum FXBurstTiming {
    static func step(progress p: Double) -> BurstStep? {
        guard p >= 0, p < 1 else { return nil }
        if p < 0.22 { return BurstStep(dx: 6, tear: true) }
        if p < 0.44 { return BurstStep(dx: 2, tear: false) }
        if p < 0.66 { return BurstStep(dx: 4, tear: false) }
        return BurstStep(dx: 2, tear: false)
    }

    /// Deterministic sideways shift per tear band, smooth from band to band, within ±scale/2 points.
    static func tearOffsets(bands: Int, scale: Double = 14) -> [Double] {
        var rng = SeededRandom(seed: 3)
        var previous = rng.next()
        return (0..<bands).map { _ in
            let next = rng.next()
            defer { previous = next }
            return ((previous + next) / 2 - 0.5) * scale
        }
    }
}

private struct BandShape: Shape {
    var top: Double, bottom: Double
    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX, y: rect.minY + rect.height * top,
                    width: rect.width, height: rect.height * max(0, 1 - top - bottom)))
    }
}

// MARK: - Glitch text

/// Title with two coloured copies jittering behind it for `FX.burst` seconds on appear and whenever
/// `trigger` changes. The burst is a single keyframe-driven progress value; the beats are read from `GlitchSlice`.
struct GlitchText: View {
    let text: String
    var font: Font = .largeTitle
    var color: Color = .radarText
    var trigger: Int = 0
    var animateOnAppear = true

    @State private var appeared = 0

    var body: some View {
        MotionGate { visible, animated in
            Text(text).font(font).foregroundStyle(color)
                .keyframeAnimator(initialValue: 1.0, trigger: trigger &+ appeared) { base, p in
                    base.background { if visible { slices(progress: animated ? p : 1) } }
                } keyframes: { _ in
                    KeyframeTrack { MoveKeyframe(0.0); LinearKeyframe(1.0, duration: FX.burst) }
                }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .onAppear { if animateOnAppear { appeared = 1 } }
    }

    private func slices(progress p: Double) -> some View {
        let a = GlitchSlice.frame(.a, progress: p), b = GlitchSlice.frame(.b, progress: p)
        return ZStack(alignment: .leading) {
            Text(text).font(font).foregroundStyle(Color.radarAccent)
                .clipShape(BandShape(top: a.top, bottom: a.bottom)).offset(x: a.dx)
            Text(text).font(font).foregroundStyle(Color.radarSignal)
                .clipShape(BandShape(top: b.top, bottom: b.bottom)).offset(x: b.dx)
        }
    }
}

// MARK: - Channel split

/// The view drawn three times, once per colour channel, red nudged left and blue right, then added
/// back together. Uses pure RGB multipliers (the `Color.red/.green/.blue` system colours are tinted).
/// With `tear`, the picture is also cut into bands that slide sideways.
struct RGBSplit<Content: View>: View {
    let dx: Double
    var tear = false
    @ViewBuilder var content: Content

    private static var bandCount: Int { 14 }

    var body: some View {
        ZStack {
            channel(Color(red: 1, green: 0, blue: 0), shift: -dx)
            channel(Color(red: 0, green: 1, blue: 0), shift: 0)
            channel(Color(red: 0, green: 0, blue: 1), shift: dx)
        }
        .compositingGroup()
    }

    @ViewBuilder
    private func channel(_ color: Color, shift: Double) -> some View {
        let base = content.colorMultiply(color)
        Group {
            if tear {
                let offsets = FXBurstTiming.tearOffsets(bands: Self.bandCount)
                ZStack {
                    ForEach(0..<Self.bandCount, id: \.self) { i in
                        base.offset(x: offsets[i])
                            .clipShape(BandShape(top: Double(i) / Double(Self.bandCount),
                                                 bottom: 1 - Double(i + 1) / Double(Self.bandCount)))
                    }
                }
            } else {
                base
            }
        }
        .offset(x: shift)
        .blendMode(.plusLighter)
    }
}

private struct BurstModifier<Key: Hashable>: ViewModifier {
    let key: Key
    func body(content: Content) -> some View {
        MotionGate { _, animated in
            content.keyframeAnimator(initialValue: 1.0, trigger: key) { view, p in
                if animated, let step = FXBurstTiming.step(progress: p) {
                    RGBSplit(dx: step.dx, tear: step.tear) { view }
                } else {
                    view
                }
            } keyframes: { _ in
                KeyframeTrack { MoveKeyframe(0.0); LinearKeyframe(1.0, duration: FX.burst) }
            }
        }
    }
}

private struct SplitModifier: ViewModifier {
    let active: Bool
    @Environment(\.radarFX) private var fx
    func body(content: Content) -> some View {
        if active, fx.enabled { RGBSplit(dx: FX.rgb) { content } } else { content }
    }
}

extension View {
    /// Plays the channel-split burst whenever `key` changes (a track change on the player cover).
    func fxBurst(key: some Hashable) -> some View { modifier(BurstModifier(key: key)) }
    /// Holds a small channel split (while a cover is pressed, say).
    func fxSplit(_ active: Bool) -> some View { modifier(SplitModifier(active: active)) }
}

// MARK: - Ping

/// Small signal dot with a ring that swells and fades every few seconds.
struct PingBlip: View {
    var size: CGFloat = 8
    var ping = true

    private struct Ring { var scale = 1.0; var opacity = 0.9 }

    var body: some View {
        MotionGate { visible, animated in
            ZStack {
                if ping, animated {
                    Circle().stroke(Color.radarSignal, lineWidth: 2)
                        .keyframeAnimator(initialValue: Ring(), repeating: true) { ring, r in
                            ring.scaleEffect(r.scale).opacity(r.opacity)
                        } keyframes: { _ in
                            KeyframeTrack(\.scale) { CubicKeyframe(3.2, duration: 2.2); LinearKeyframe(3.2, duration: 1.0) }
                            KeyframeTrack(\.opacity) { CubicKeyframe(0, duration: 2.2); LinearKeyframe(0, duration: 1.0) }
                        }
                }
                Circle().fill(Color.radarSignal)
            }
            .frame(width: size, height: size)
            .opacity(visible ? 1 : 0.6)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Equaliser

/// Four bars that dance while `playing` and rest at fixed heights otherwise.
struct EQBars: View {
    var playing: Bool
    var width: CGFloat = 16
    var height: CGFloat = 16

    static let rest: [Double] = [0.45, 0.85, 0.60, 0.35]
    /// Each bar loops through its own five heights, so the four never move in lockstep.
    static let routes: [[Double]] = [
        [0.30, 1.00, 0.45, 0.85, 0.35],
        [0.80, 0.35, 1.00, 0.50, 0.70],
        [0.50, 0.90, 0.30, 0.75, 1.00],
        [0.25, 0.60, 0.95, 0.40, 0.65]
    ]

    var body: some View {
        MotionGate { _, animated in
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<4, id: \.self) { i in
                    if playing && animated {
                        let r = Self.routes[i]
                        Rectangle().fill(Color.radarAccentText)
                            .keyframeAnimator(initialValue: r[0], repeating: true) { bar, h in
                                bar.frame(height: height * h)
                            } keyframes: { _ in
                                KeyframeTrack {
                                    CubicKeyframe(r[1], duration: 0.22 + Double(i) * 0.03)
                                    CubicKeyframe(r[2], duration: 0.26)
                                    CubicKeyframe(r[3], duration: 0.20 + Double(i) * 0.02)
                                    CubicKeyframe(r[4], duration: 0.24)
                                    CubicKeyframe(r[0], duration: 0.22)
                                }
                            }
                    } else {
                        Rectangle().fill(Color.radarAccentText).frame(height: height * Self.rest[i])
                    }
                }
            }
            .frame(width: width, height: height, alignment: .bottom)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Skeleton

/// Loading placeholder: a surface block with a soft accent sheen sliding across it.
struct SkeletonBlock: View {
    var body: some View {
        MotionGate { _, animated in
            Color.radarSurface2
                .overlay {
                    if animated {
                        GeometryReader { proxy in
                            LinearGradient(colors: [.clear, Color.radarAccent.opacity(0.16), .clear],
                                           startPoint: .leading, endPoint: .trailing)
                                .frame(width: proxy.size.width * 0.4)
                                .keyframeAnimator(initialValue: -0.4, repeating: true) { sheen, x in
                                    sheen.offset(x: x * proxy.size.width)
                                } keyframes: { _ in
                                    KeyframeTrack { LinearKeyframe(1.0, duration: 1.3) }
                                }
                        }
                    }
                }
                .clipped()
        }
        .accessibilityHidden(true)
    }
}
