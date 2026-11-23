import SwiftUI

/// The artifact's fluid type tokens: `clamp(min, N vw, max)` against the width of the screen.
enum RadarScale {
    static func clamp(min lo: CGFloat, vw: CGFloat, max hi: CGFloat, width: CGFloat) -> CGFloat {
        Swift.min(hi, Swift.max(lo, vw / 100 * width))
    }
    static func hero(_ width: CGFloat) -> CGFloat { clamp(min: 76, vw: 26, max: 176, width: width) }       // --fs-hero
    static func displayL(_ width: CGFloat) -> CGFloat { clamp(min: 56, vw: 17, max: 104, width: width) }    // --fs-display-l
    static func displayM(_ width: CGFloat) -> CGFloat { clamp(min: 40, vw: 11, max: 56, width: width) }     // --fs-display-m
    static let displayS: CGFloat = 28                                                                      // --fs-display-s
    static let gutter: CGFloat = 16                                                                        // --size-gutter
    static let touch: CGFloat = 44                                                                         // minimum touch target
    static let pageMaxWidth: CGFloat = 1360
}

extension View {
    /// `.page`: 16 pt gutters, content capped at 1360 pt and centred.
    func radarPage() -> some View {
        padding(.horizontal, RadarScale.gutter)
            .frame(maxWidth: RadarScale.pageMaxWidth)
            .frame(maxWidth: .infinity)
    }
}

/// One piece of a `Readout`.
enum ReadoutPart: Equatable, Sendable {
    case text(String)      // plain, text-3
    case strong(String)    // `<b>`: text-2
    case separator         // `<i>`: dimmed slash
}

/// `.readout`: 11 pt uppercase, 0.13 em tracking, tabular figures, wraps.
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
