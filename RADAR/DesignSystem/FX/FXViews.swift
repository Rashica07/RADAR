import SwiftUI

// MARK: - Environment

/// The artifact's `data-fx` / `data-motion` switches. The app shell sets this from `SettingsStore`
/// (`fx`, `reduceMotion`); the system Reduce Motion setting is honoured on top of it.
struct RadarFXEnvironment: Equatable, Sendable {
    var enabled = true
    var reducedMotion = false
}

extension EnvironmentValues {
    @Entry var radarFX = RadarFXEnvironment()
}

// MARK: - Scanlines + grain (`.art--fx:before/:after`)

/// 5 % black lines every 3 pt, plus film grain blended with `overlay` at 50 %. Place over artwork.
struct ArtFXOverlay: View {
    @Environment(\.radarFX) private var fx

    var body: some View {
        if fx.enabled {
            ZStack {
                Canvas { context, size in
                    var y: CGFloat = 0
                    while y < size.height {
                        context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                                     with: .color(.black.opacity(FX.scan)))
                        y += FX.scanPitch
                    }
                }
                Canvas { context, size in
                    let tile = GrainTile.image
                    let resolved = context.resolve(Image(decorative: tile, scale: 1))
                    var layer = context
                    layer.blendMode = .overlay
                    layer.opacity = FX.grain
                    let side = GrainTile.side
                    var y: CGFloat = 0
                    while y < size.height {
                        var x: CGFloat = 0
                        while x < size.width {
                            layer.draw(resolved, in: CGRect(x: x, y: y, width: side, height: side))
                            x += side
                        }
                        y += side
                    }
                }
            }
            .clipped()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// A 180×180 white noise tile with varying alpha — the stand-in for the artifact's
/// `feTurbulence fractalNoise baseFrequency=.85 numOctaves=2` data-URI (same size, same
/// recipe: white, alpha ≈ 0.9 × noise). Deterministic, generated once.
enum GrainTile {
    static let side: CGFloat = 180

    static func alpha(at index: Int, rng: inout SeededRandom) -> UInt8 {
        // Sum of two uniforms ≈ soft noise centred on 0.5, like fractal noise's alpha channel.
        let n = (rng.next() + rng.next()) / 2
        return UInt8((n * 0.9 * 255).rounded())
    }

    static let image: CGImage = {
        let n = Int(side)
        var rng = SeededRandom(seed: 180)
        var pixels = [UInt8](repeating: 255, count: n * n * 4)
        for i in 0..<(n * n) {
            let a = alpha(at: i, rng: &rng)
            // premultiplied white: colour = alpha
            pixels[i * 4] = a; pixels[i * 4 + 1] = a; pixels[i * 4 + 2] = a; pixels[i * 4 + 3] = a
        }
        let provider = CGDataProvider(data: Data(pixels) as CFData)!
        return CGImage(width: n, height: n, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: n * 4,
                       space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    }()
}

extension View {
    /// Artwork frame with scanlines and grain on top (`.art--fx`).
    func artFX() -> some View { overlay { ArtFXOverlay() } }
}

// MARK: - RGB-split text (`.glitch`)

private struct BandShape: Shape {
    var top: Double, bottom: Double
    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX, y: rect.minY + rect.height * top,
                    width: rect.width, height: rect.height * max(0, 1 - top - bottom)))
    }
}

/// Text with two offset copies — coral above-left, mint below-right — each clipped to a thin
/// band behind the real text. The copies jump in hard steps for `FX.burst` seconds when the view
/// appears, when `trigger` changes, or when `play()` is called through the binding.
struct GlitchText: View {
    let text: String
    var font: Font = .largeTitle
    var color: Color = .radarText
    var trigger: Int = 0
    var animateOnAppear = true

    @Environment(\.radarFX) private var fx
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var started: Date?

    var body: some View {
        ZStack(alignment: .leading) {
            if fx.enabled {
                if let started, !(fx.reducedMotion || systemReduceMotion) {
                    TimelineView(.animation) { timeline in
                        let p = timeline.date.timeIntervalSince(started) / FX.burst
                        slices(progress: p)
                    }
                } else {
                    slices(progress: 1)
                }
            }
            Text(text).font(font).foregroundStyle(color)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .onAppear { if animateOnAppear { start() } }
        .onChange(of: trigger) { start() }
    }

    private func slices(progress p: Double) -> some View {
        let a = GlitchSlice.frame(.a, progress: p)
        let b = GlitchSlice.frame(.b, progress: p)
        return ZStack(alignment: .leading) {
            Text(text).font(font).foregroundStyle(Color.radarAccent)
                .clipShape(BandShape(top: a.top, bottom: a.bottom)).offset(x: a.dx)
            Text(text).font(font).foregroundStyle(Color.radarSignal)
                .clipShape(BandShape(top: b.top, bottom: b.bottom)).offset(x: b.dx)
        }
        .accessibilityHidden(true)
    }

    private func start() {
        let now = Date()
        started = now
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(FX.burst + 0.05))
            if started == now { started = nil }
        }
    }
}

// MARK: - Channel split + burst (`filter: url(#fx-1…3)`, `.fx-burst`)

/// Renders `content` three times, once per colour channel, with red shifted left and blue right,
/// (pure channel colours — `Color.red` etc. are tinted system colours) and adds the channels back together (the artifact's `feOffset` + `feBlend screen`). With
/// `tear`, the picture is also cut into bands that slide sideways (`feDisplacementMap`).
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

private struct FXBurstModifier: ViewModifier {
    let key: AnyHashable?
    @Environment(\.radarFX) private var fx
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var started: Date?
    @State private var armed = false

    func body(content: Content) -> some View {
        Group {
            if let started, fx.enabled, !(fx.reducedMotion || systemReduceMotion) {
                TimelineView(.animation) { timeline in
                    let p = timeline.date.timeIntervalSince(started) / FX.burst
                    if let step = FXBurstTiming.step(progress: p) {
                        RGBSplit(dx: step.dx, tear: step.tear) { content }
                    } else {
                        content
                    }
                }
            } else {
                content
            }
        }
        .onChange(of: key) {
            guard armed else { return }
            let now = Date()
            started = now
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(FX.burst + 0.05))
                if started == now { started = nil }
            }
        }
        .onAppear { armed = true }
    }
}

extension View {
    /// Plays the 0.38 s channel-split burst whenever `key` changes (track change on the player art).
    func fxBurst(key: some Hashable) -> some View { modifier(FXBurstModifier(key: AnyHashable(key))) }

    /// Static 2 pt channel split (`.is-pressing .art`, `.art.is-split`).
    func fxSplit(_ active: Bool) -> some View {
        modifier(FXSplitModifier(active: active))
    }
}

private struct FXSplitModifier: ViewModifier {
    let active: Bool
    @Environment(\.radarFX) private var fx
    func body(content: Content) -> some View {
        if active, fx.enabled { RGBSplit(dx: FX.rgb) { content } } else { content }
    }
}

// MARK: - Ping blip (`.blip--ping`)

/// A small signal-coloured dot with an expanding ring every 3.2 s.
struct PingBlip: View {
    var size: CGFloat = 8
    var ping = true
    @Environment(\.radarFX) private var fx
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    var body: some View {
        ZStack {
            if ping, fx.enabled, !(fx.reducedMotion || systemReduceMotion) {
                TimelineView(.animation) { timeline in
                    let s = PingTiming.state(time: timeline.date.timeIntervalSinceReferenceDate)
                    Circle().stroke(Color.radarSignal, lineWidth: 2)
                        .scaleEffect(s.scale).opacity(s.opacity)
                }
            }
            Circle().fill(Color.radarSignal)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - EQ bars (`.eq`)

/// Four bars; animates (6-step "digital" movement) while `playing`.
struct EQBars: View {
    var playing: Bool
    var width: CGFloat = 16
    var height: CGFloat = 16
    @Environment(\.radarFX) private var fx
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    var body: some View {
        let animate = playing && !(fx.reducedMotion || systemReduceMotion)
        TimelineView(.animation(paused: !animate)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<4, id: \.self) { i in
                    Rectangle().fill(Color.radarAccentText)
                        .frame(height: height * EQTiming.height(bar: i, time: t, playing: animate))
                }
            }
            .frame(width: width, height: height, alignment: .bottom)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Skeleton (`.sk`)

/// Loading placeholder: surface block with a 40 %-wide accent sweep stepping across it.
struct SkeletonBlock: View {
    @Environment(\.radarFX) private var fx
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    var body: some View {
        let animate = fx.enabled && !(fx.reducedMotion || systemReduceMotion)
        Color.radarSurface2
            .overlay {
                GeometryReader { proxy in
                    TimelineView(.animation(paused: !animate)) { timeline in
                        let w = proxy.size.width * 0.4
                        let x = SkeletonTiming.offset(time: animate ? timeline.date.timeIntervalSinceReferenceDate : 0) * w
                        LinearGradient(colors: [.clear, Color.radarAccent.opacity(0.16), .clear],
                                       startPoint: .leading, endPoint: .trailing)
                            .frame(width: w).offset(x: x)
                    }
                }
                .opacity(animate ? 1 : 0)
            }
            .clipped()
            .accessibilityHidden(true)
    }
}
