import SwiftUI

/// The RADAR symbol: three signal arcs rising from a stride. Mint + coral, or monochrome.
struct RadarSymbol: View {
    enum Style { case color, monochrome }
    var height: CGFloat = 24
    var style: Style = .color

    var body: some View {
        let size = RadarBrandPaths.symbolSize
        let width = height * size.width / size.height
        Canvas { context, canvas in
            let scale = canvas.height / size.height
            context.scaleBy(x: scale, y: scale)
            let mint: Color = style == .color ? .radarMint : .radarText
            let coral: Color = style == .color ? .radarCoral : .radarText
            context.fill(Path(RadarBrandPaths.outer), with: .color(mint))
            context.fill(Path(RadarBrandPaths.signal), with: .color(coral))
            context.fill(Path(RadarBrandPaths.core), with: .color(mint))
            context.fill(Path(RadarBrandPaths.leg), with: .color(mint))
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }
}

/// The custom "RΛDΛR" wordmark, drawn as vectors.
struct RadarWordmark: View {
    var capHeight: CGFloat = 16
    var color: Color = .radarText

    var body: some View {
        let size = RadarBrandPaths.wordmarkSize
        Canvas { context, canvas in
            let scale = canvas.height / size.height
            context.scaleBy(x: scale, y: scale)
            context.fill(Path(RadarBrandPaths.wordmark), with: .color(color), style: FillStyle(eoFill: true))
        }
        .frame(width: capHeight * size.width / size.height, height: capHeight)
        .accessibilityLabel("RADAR")
    }
}

/// Symbol + wordmark lockup (brand sheet "01 · Primary logo"): the wordmark's cap
/// height is half the symbol's height, vertically centred slightly low.
struct RadarLogo: View {
    var symbolHeight: CGFloat = 26
    var style: RadarSymbol.Style = .color

    var body: some View {
        HStack(alignment: .center, spacing: symbolHeight * 0.36) {
            RadarSymbol(height: symbolHeight, style: style)
            RadarWordmark(capHeight: symbolHeight * 0.5)
                .offset(y: symbolHeight * 0.06)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("RADAR")
    }
}

#Preview {
    VStack(spacing: 24) {
        RadarLogo(symbolHeight: 48)
        RadarLogo(symbolHeight: 48, style: .monochrome)
        RadarSymbol(height: 120)
    }
    .padding()
    .background(Color.radarBg)
}
