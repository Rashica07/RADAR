import SwiftUI

/// Horizontal shelf that snaps card by card, with the content inset to the page gutter —
/// the system's paging physics rather than a hand-rolled carousel.
struct Rail<Item: Identifiable, Content: View>: View {
    let items: [Item]
    var cardsVisible: CGFloat = 2.3
    var spacing: CGFloat = 12
    @ViewBuilder var content: (Item) -> Content

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: spacing) {
                ForEach(items) { item in
                    content(item)
                        .containerRelativeFrame(.horizontal, count: Int((cardsVisible * 10).rounded()), span: 10, spacing: spacing * cardsVisible / 2)
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, RadarScale.gutter, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
    }
}

/// Square cover with title and subtitle underneath. Press = soft scale; the art can fan out
/// into a hero transition via `matchedTransitionSource` at the call site.
struct Tile: View {
    let title: String
    let subtitle: String
    let art: ArtSpec
    var badge: String?
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ArtworkView(art).artFX().aspectRatio(1, contentMode: .fit)
                    .overlay(alignment: .topLeading) {
                        if let badge {
                            Text(badge).font(RadarFont.ui(10, .bold, relativeTo: .caption2)).textCase(.uppercase)
                                .foregroundStyle(Color.radarOnAccent).padding(.horizontal, 6).padding(.vertical, 3)
                                .background(Color.radarAccent).padding(8)
                        }
                    }
                Text(title).font(RadarFont.ui(15, .semibold, relativeTo: .subheadline)).foregroundStyle(Color.radarText).lineLimit(2).multilineTextAlignment(.leading)
                Text(subtitle).font(RadarFont.body(12, .regular, relativeTo: .caption)).foregroundStyle(Color.radarText2).lineLimit(1)
            }
        }
        .buttonStyle(TilePressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(subtitle)")
    }
}

struct TilePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(duration: 0.28, bounce: 0.3), value: configuration.isPressed)
    }
}

/// Where each cover of a collage goes. Pure so it can be tested.
enum CollageFrames {
    /// 1 → full; 2 → halves; 3 → one tall + two stacked; 4+ → 2×2 (extra covers ignored).
    static func frames(count: Int, in size: CGSize, spacing: CGFloat = 2) -> [CGRect] {
        let w = size.width, h = size.height
        switch count {
        case ...0: return []
        case 1: return [CGRect(origin: .zero, size: size)]
        case 2:
            let cw = (w - spacing) / 2
            return [CGRect(x: 0, y: 0, width: cw, height: h), CGRect(x: cw + spacing, y: 0, width: cw, height: h)]
        case 3:
            let lw = (w - spacing) * 0.6, rw = w - spacing - lw, ch = (h - spacing) / 2
            return [CGRect(x: 0, y: 0, width: lw, height: h),
                    CGRect(x: lw + spacing, y: 0, width: rw, height: ch),
                    CGRect(x: lw + spacing, y: ch + spacing, width: rw, height: ch)]
        default:
            let cw = (w - spacing) / 2, ch = (h - spacing) / 2
            return [CGRect(x: 0, y: 0, width: cw, height: ch), CGRect(x: cw + spacing, y: 0, width: cw, height: ch),
                    CGRect(x: 0, y: ch + spacing, width: cw, height: ch), CGRect(x: cw + spacing, y: ch + spacing, width: cw, height: ch)]
        }
    }
}

/// Playlist-style mosaic of up to four covers, as a custom `Layout`.
struct CollageLayout: Layout {
    var spacing: CGFloat = 2
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let side = proposal.width ?? proposal.height ?? 160
        return CGSize(width: side, height: proposal.height ?? side)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let frames = CollageFrames.frames(count: subviews.count, in: bounds.size, spacing: spacing)
        for (i, view) in subviews.enumerated() {
            if i < frames.count {
                let f = frames[i]
                view.place(at: CGPoint(x: bounds.minX + f.minX, y: bounds.minY + f.minY), proposal: ProposedViewSize(f.size))
            } else {
                view.place(at: bounds.origin, proposal: ProposedViewSize(width: 0, height: 0))
            }
        }
    }
}

struct Collage: View {
    let arts: [ArtSpec]
    var body: some View {
        CollageLayout {
            ForEach(Array(arts.prefix(4).enumerated()), id: \.offset) { _, spec in
                ArtworkView(spec).clipped()
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// Large chart numeral drawn as real glyph outlines (CoreText), so stroke width is true and it scales with Dynamic Type.
struct GlyphOutline: Shape {
    var text: String
    var fontName = RadarFont.Display.black.rawValue

    func path(in rect: CGRect) -> Path {
        let font = CTFontCreateWithName(fontName as CFString, 100, nil)
        var chars = Array(text.utf16)
        var glyphs = [CGGlyph](repeating: 0, count: chars.count)
        guard CTFontGetGlyphsForCharacters(font, &chars, &glyphs, chars.count) else { return Path() }
        var advances = [CGSize](repeating: .zero, count: glyphs.count)
        CTFontGetAdvancesForGlyphs(font, .horizontal, glyphs, &advances, glyphs.count)
        var combined = CGMutablePath()
        var x: CGFloat = 0
        for (g, a) in zip(glyphs, advances) {
            if let p = CTFontCreatePathForGlyph(font, g, nil) {
                combined.addPath(p, transform: CGAffineTransform(translationX: x, y: 0))
            }
            x += a.width
        }
        let box = combined.boundingBoxOfPath
        guard box.width > 0, box.height > 0 else { return Path() }
        let s = min(rect.width / box.width, rect.height / box.height)
        // CoreText is y-up: flip, scale, then centre.
        var t = CGAffineTransform(translationX: -box.minX, y: -box.minY)
        t = t.concatenating(CGAffineTransform(scaleX: s, y: -s))
        t = t.concatenating(CGAffineTransform(translationX: rect.midX - box.width * s / 2, y: rect.midY + box.height * s / 2))
        return Path(combined.copy(using: &t) ?? combined)
    }
}

/// Chart card: art with an outlined rank numeral across the corner.
struct Poster: View {
    let rank: Int
    let title: String
    let subtitle: String
    let art: ArtSpec
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                ArtworkView(art).artFX().aspectRatio(3.0 / 4.0, contentMode: .fit)
                LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 2) {
                    GlyphOutline(text: "\(rank)")
                        .stroke(rank == 1 ? Color.radarAccent : Color.white, lineWidth: 2)
                        .frame(width: rank >= 10 ? 62 : 38, height: 56)
                    Text(title).font(RadarFont.ui(15, .bold, relativeTo: .subheadline)).foregroundStyle(.white).lineLimit(1)
                    Text(subtitle).font(RadarFont.body(12, .regular, relativeTo: .caption)).foregroundStyle(.white.opacity(0.75)).lineLimit(1)
                }
                .padding(12)
            }
            .clipShape(Rectangle())
        }
        .buttonStyle(TilePressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Number \(rank), \(title), \(subtitle)")
    }
}

/// Genre / mood band: art strip with a big title.
struct Band: View {
    let title: String
    let detail: String
    let art: ArtSpec
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                ArtworkView(art).artFX().frame(height: 84).frame(maxWidth: .infinity)
                LinearGradient(colors: [.black.opacity(0.7), .clear], startPoint: .leading, endPoint: .trailing)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(RadarFont.display(30, .black, relativeTo: .title)).textCase(.uppercase).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.6)
                    Text(detail).font(RadarFont.body(12, .medium, relativeTo: .caption)).foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 84).clipShape(Rectangle())
        }
        .buttonStyle(TilePressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(detail)")
    }
}

/// Playlist card: collage + title + count.
struct Mix: View {
    let title: String
    let subtitle: String
    let arts: [ArtSpec]
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Collage(arts: arts)
                Text(title).font(RadarFont.ui(15, .semibold, relativeTo: .subheadline)).foregroundStyle(Color.radarText).lineLimit(2).multilineTextAlignment(.leading)
                Text(subtitle).font(RadarFont.body(12, .regular, relativeTo: .caption)).foregroundStyle(Color.radarText2).lineLimit(1)
            }
        }
        .buttonStyle(TilePressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(subtitle)")
    }
}
