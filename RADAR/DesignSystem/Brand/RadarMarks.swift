import SwiftUI

/// Proportions of the primary lockup from the brand sheet: the wordmark's cap height is
/// 57% of the symbol's height, the gap is 34%, and the wordmark sits 3.6% below centre.
enum RadarBrandLayout {
    static let symbol = RadarBrandPaths.symbolSize
    static let wordmark = RadarBrandPaths.wordmarkSize
    static let wordScale: CGFloat = symbol.height * 0.57 / wordmark.height
    static let gap: CGFloat = symbol.height * 0.34
    static let wordOrigin = CGPoint(
        x: symbol.width + gap,
        y: (symbol.height - wordmark.height * wordScale) / 2 + symbol.height * 0.036
    )
    static let lockup = CGSize(width: (symbol.width + gap + wordmark.width * wordScale).rounded(.up), height: symbol.height)
}

private enum Shapes {
    static let outer = Path(RadarBrandPaths.outer)
    static let signal = Path(RadarBrandPaths.signal)
    static let head = Path(RadarBrandPaths.signalHeadClip)
    static let core = Path(RadarBrandPaths.core)
    static let leg = Path(RadarBrandPaths.leg)
    static let wordmark = Path(RadarBrandPaths.wordmark)
    static let wordLegs = Path(RadarBrandPaths.wordmarkLegs)

    /// The whole symbol as one shape (used for the glitch trails).
    static let symbolAll: Path = {
        var p = Path()
        p.addPath(outer)
        p.addPath(signal)
        p.addPath(core)
        p.addPath(leg)
        return p
    }()
}

/// Draws the RADAR symbol, wordmark or lockup with a continuous glitch amount.
///
/// - `glitch` 0 … 1: how far the speed-smear extends (0 = clean artwork).
/// - `tint` 0 … 1: 0 is the glitched look (everything mint), 1 is the brand colors
///   (coral signal arc with a warm-white head, warm-white wordmark).
///
/// Drawing is vector `Canvas` work, so it stays crisp at any size and costs nothing
/// when `glitch` is 0.
struct RadarLogoCanvas: View {
    enum Layout { case symbol, wordmark, lockup }

    var layout: Layout = .lockup
    /// Overall height of the drawing (cap height for `.wordmark`).
    var height: CGFloat = 40
    var glitch: Double = 0
    var tint: Double = 1
    var seed: UInt32 = GlitchSpec.defaultSeed
    /// Draws everything in one color (monochrome logo). Ignores `tint`.
    var monochrome: Color?

    private var box: CGSize {
        switch layout {
        case .symbol: RadarBrandLayout.symbol
        case .wordmark: RadarBrandLayout.wordmark
        case .lockup: RadarBrandLayout.lockup
        }
    }

    var body: some View {
        let box = box
        Canvas { context, size in
            let scale = size.height / box.height
            var base = context
            base.scaleBy(x: scale, y: scale)
            switch layout {
            case .symbol:
                drawSymbol(base)
            case .wordmark:
                drawWordmark(base)
            case .lockup:
                drawSymbol(base)
                var word = base
                word.translateBy(x: RadarBrandLayout.wordOrigin.x, y: RadarBrandLayout.wordOrigin.y)
                word.scaleBy(x: RadarBrandLayout.wordScale, y: RadarBrandLayout.wordScale)
                drawWordmark(word)
            }
        }
        .frame(width: height * box.width / box.height, height: height)
    }

    // MARK: Colors

    private var mint: Color { monochrome ?? .radarMint }
    private var signalColor: Color { monochrome ?? RadarRGB.mint.mixed(with: .coral, tint).color }
    private var headColor: Color { monochrome ?? RadarRGB.mint.mixed(with: .warm, tint).color }
    private var wordColor: Color { monochrome ?? RadarRGB.mint.mixed(with: .warm, tint).color }

    // MARK: Drawing

    private func drawSymbol(_ context: GraphicsContext) {
        let size = RadarBrandLayout.symbol
        if glitch > 0.001 {
            let bands = GlitchSpec.bands(
                seed: seed,
                height: Double(size.height),
                amount: glitch,
                maxLength: Double(size.width) * GlitchSpec.symbolMaxLengthFactor
            )
            drawTrails(context, bands: bands, direction: -1, rightTickThreshold: Double(size.width) * 0.12) { c in
                c.fill(Shapes.symbolAll, with: .color(mint))
            }
        }
        context.fill(Shapes.outer, with: .color(mint))
        context.fill(Shapes.signal, with: .color(signalColor))
        if monochrome == nil {
            var clipped = context
            clipped.clip(to: Shapes.head)
            clipped.fill(Shapes.signal, with: .color(headColor))
        }
        context.fill(Shapes.core, with: .color(mint))
        context.fill(Shapes.leg, with: .color(mint))
    }

    private func drawWordmark(_ context: GraphicsContext) {
        let size = RadarBrandLayout.wordmark
        if glitch > 0.001 {
            // Only the outer edges of the first and last letters streak, like the sheet.
            let left = GlitchSpec.bands(seed: seed &+ 101, height: Double(size.height), amount: glitch, maxLength: 46)
            drawTrails(context, bands: left, direction: -1, clipX: -600...0.5) { c in
                drawWordShapes(c, color: wordColor)
            }
            let right = GlitchSpec.bands(seed: seed &+ 202, height: Double(size.height), amount: glitch * 0.7, maxLength: 34)
            drawTrails(context, bands: right, direction: 1, clipX: (size.width - 0.5)...(size.width + 600)) { c in
                drawWordShapes(c, color: wordColor)
            }
        }
        drawWordShapes(context, color: wordColor)
    }

    private func drawWordShapes(_ context: GraphicsContext, color: Color) {
        context.fill(Shapes.wordmark, with: .color(color), style: FillStyle(eoFill: true))
        context.fill(Shapes.wordLegs, with: .color(color))
    }

    /// Smears `draw` leftwards (or rightwards) inside each active band, as a fading
    /// stack of translated copies. The band rectangle stays put while the artwork moves.
    private func drawTrails(
        _ context: GraphicsContext,
        bands: [GlitchBand],
        direction: CGFloat,
        clipX: ClosedRange<CGFloat>? = nil,
        rightTickThreshold: Double? = nil,
        draw: (GraphicsContext) -> Void
    ) {
        let copies = GlitchSpec.trailCopies
        for band in bands where band.length > 0.5 {
            var banded = context
            banded.clip(to: Path(CGRect(x: -2000, y: band.y, width: 6000, height: band.h)))
            if let clipX {
                banded.clip(to: Path(CGRect(x: clipX.lowerBound, y: band.y - 1, width: clipX.upperBound - clipX.lowerBound, height: band.h + 2)))
            }
            for k in 1...copies {
                var copy = banded
                copy.translateBy(x: direction * CGFloat(band.length) * CGFloat(k) / CGFloat(copies), y: 0)
                copy.opacity = GlitchSpec.trailAlpha(k)
                draw(copy)
            }
            if let threshold = rightTickThreshold, band.length > threshold {
                var tick = banded
                tick.translateBy(x: CGFloat(band.length) * 0.1, y: 0)
                tick.opacity = 0.6
                draw(tick)
            }
        }
    }
}

// MARK: - Everyday wrappers

/// The RADAR symbol: three signal arcs rising from a stride.
struct RadarSymbol: View {
    enum Style { case color, monochrome }
    var height: CGFloat = 24
    var style: Style = .color

    var body: some View {
        RadarLogoCanvas(layout: .symbol, height: height, monochrome: style == .monochrome ? .radarText : nil)
            .accessibilityHidden(true)
    }
}

/// The custom "RΛDΛR" wordmark.
struct RadarWordmark: View {
    var capHeight: CGFloat = 16
    var color: Color = .radarText

    var body: some View {
        RadarLogoCanvas(layout: .wordmark, height: capHeight, monochrome: color)
            .accessibilityLabel("RADAR")
    }
}

/// Symbol + wordmark lockup (brand sheet primary logo).
struct RadarLogo: View {
    /// Height of the symbol; the wordmark follows the sheet's proportions.
    var symbolHeight: CGFloat = 26
    var style: RadarSymbol.Style = .color

    var body: some View {
        RadarLogoCanvas(
            layout: .lockup,
            height: symbolHeight,
            monochrome: style == .monochrome ? .radarText : nil
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("RADAR")
    }
}

#Preview("Marks") {
    VStack(spacing: 28) {
        RadarLogo(symbolHeight: 56)
        RadarLogo(symbolHeight: 56, style: .monochrome)
        RadarLogoCanvas(layout: .lockup, height: 56, glitch: 1, tint: 0)
        RadarLogoCanvas(layout: .symbol, height: 90, glitch: 0.5, tint: 0.5)
    }
    .padding()
    .background(Color.radarCharcoal)
}
