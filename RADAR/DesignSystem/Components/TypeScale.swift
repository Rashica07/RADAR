import SwiftUI

/// Layout constants and type sizes. Sizes are base values for the default text size; every one is
/// attached to a Dynamic Type style, so they grow and shrink with the reader's setting.
enum RadarScale {
    static let gutter: CGFloat = 16
    static let touch: CGFloat = 44              // smallest tappable height
    static let readableWidth: CGFloat = 720     // text columns on wide screens
    static let pageMaxWidth: CGFloat = 1360

    /// Display sizes for titles. `.hero` is for the Home lead, `.large` for screen titles, `.medium` for sections.
    enum Title {
        case hero, large, medium, small
        var size: CGFloat { switch self { case .hero: 88; case .large: 60; case .medium: 42; case .small: 28 } }
        var style: Font.TextStyle { switch self { case .hero, .large: .largeTitle; case .medium: .title; case .small: .title2 } }
        var font: Font { RadarFont.display(size, .black, relativeTo: style) }
    }
}

extension View {
    /// Page gutters, with content centred and capped on wide windows.
    func radarPage() -> some View {
        padding(.horizontal, RadarScale.gutter)
            .frame(maxWidth: RadarScale.pageMaxWidth)
            .frame(maxWidth: .infinity)
    }

    /// Big uppercase display title that shrinks (never clips) to fit a few lines.
    func radarTitle(_ title: RadarScale.Title, lines: Int = 3) -> some View {
        font(title.font).textCase(.uppercase).lineLimit(lines).minimumScaleFactor(0.5)
    }
}

/// One piece of a `Readout`.
enum ReadoutPart: Equatable, Sendable {
    case text(String)      // plain
    case strong(String)    // emphasised
    case separator         // dimmed slash
}

/// Small uppercase status line: "WEEK 47 / 12 PLAYS / IT".
struct Readout: View {
    var parts: [ReadoutPart]
    var hot = false

    init(_ parts: [ReadoutPart], hot: Bool = false) { self.parts = parts; self.hot = hot }
    init(_ text: String, hot: Bool = false) { self.init([.text(text)], hot: hot) }

    var body: some View {
        parts.reduce(Text("")) { acc, part in
            switch part {
            case .text(let s): acc + Text(s)
            case .strong(let s): acc + Text(s).foregroundColor(hot ? .radarSignalText : .radarText2).fontWeight(.semibold)
            case .separator: acc + Text(" / ").foregroundColor((hot ? Color.radarSignalText : .radarText3).opacity(0.55))
            }
        }
        .monospacedDigit()
        .radarReadout(hot ? .radarSignalText : .radarText3)
        .fixedSize(horizontal: false, vertical: true)
    }
}
