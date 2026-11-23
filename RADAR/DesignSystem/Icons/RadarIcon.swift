import SwiftUI

/// One drawable piece of an icon, in the 24 × 24 design grid.
struct IconPart {
    let fill: Bool
    let stroke: Bool
    /// Stroked in the "cut" color (the surface behind the icon) to knock a gap out of a solid shape.
    let cut: Bool
    let path: Path

    init(fill: Bool, stroke: Bool, cut: Bool, _ build: (inout Path) -> Void) {
        self.fill = fill
        self.stroke = stroke
        self.cut = cut
        var p = Path()
        build(&p)
        path = p
    }
}

private struct RadarIconCutKey: EnvironmentKey {
    static let defaultValue = Color.radarNavBg
}

extension EnvironmentValues {
    /// Color used to cut gaps out of filled icons (the filled Discover icon). Set it to
    /// the background the icon sits on.
    var radarIconCut: Color {
        get { self[RadarIconCutKey.self] }
        set { self[RadarIconCutKey.self] = newValue }
    }
}

/// RADAR's icon set, drawn natively from the Phase 01 vector paths: 1.75 stroke, round
/// caps and joins. Color follows `foregroundStyle`.
struct RadarIcon: View {
    let name: RadarIconName
    var size: CGFloat = 24

    @Environment(\.radarIconCut) private var cut

    init(_ name: RadarIconName, size: CGFloat = 24) {
        self.name = name
        self.size = size
    }

    var body: some View {
        Canvas { context, canvasSize in
            let scale = canvasSize.width / 24
            var c = context
            c.scaleBy(x: scale, y: scale)
            let style = StrokeStyle(lineWidth: 1.75, lineCap: .round, lineJoin: .round)
            for part in name.parts {
                if part.fill { c.fill(part.path, with: .foreground) }
                if part.stroke { c.stroke(part.path, with: .foreground, style: style) }
                if part.cut { c.stroke(part.path, with: .color(cut), style: style) }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
