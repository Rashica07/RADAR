import SwiftUI

/// `.btn`: 44 pt (sm 40, lg 52) uppercase control with square corners.
struct RadarButtonStyle: ButtonStyle {
    enum Kind { case primary, outline, ghost }
    enum Size { case sm, md, lg }
    var kind: Kind = .primary
    var size: Size = .md
    var block = false
    @Environment(\.isEnabled) private var enabled

    private var height: CGFloat { size == .sm ? 40 : size == .lg ? 52 : 44 }
    private var pad: CGFloat { size == .sm ? 16 : size == .lg ? 26 : 20 }
    private var fontSize: CGFloat { size == .sm ? 12 : size == .lg ? 14 : 13 }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RadarFont.ui(fontSize, .bold, relativeTo: .footnote))
            .tracking(fontSize * 0.1).textCase(.uppercase).lineLimit(1)
            .foregroundStyle(kind == .primary ? Color.radarOnAccent : Color.radarText)
            .padding(.horizontal, pad)
            .frame(maxWidth: block ? .infinity : nil, minHeight: height)
            .background(kind == .primary ? Color.radarAccent : .clear)
            .overlay { if kind != .primary { Rectangle().strokeBorder(Color.radarLineStrong, lineWidth: 1) } }
            .contentShape(Rectangle())
            .opacity(enabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.985 : 1).offset(y: configuration.isPressed ? 1 : 0)
            .animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.12), value: configuration.isPressed)
    }
}

/// `.cta`: big display-type call to action with a 3 pt accent underline that floods on press.
struct CTAButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RadarFont.display(28, .extraBold, relativeTo: .title))
            .tracking(28 * 0.02).textCase(.uppercase)
            .foregroundStyle(configuration.isPressed ? Color.radarOnAccent : Color.radarText)
            .padding(.horizontal, 2).frame(minHeight: 48)
            .background(alignment: .bottom) {
                Color.radarAccent.frame(height: configuration.isPressed ? nil : 3)
            }
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.22), value: configuration.isPressed)
    }
}

/// `.tag`: outlined 40 pt chip; `isOn` fills it with the accent. `ghost` is text-only.
struct TagButtonStyle: ButtonStyle {
    var isOn = false
    var ghost = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RadarFont.ui(13, .semibold, relativeTo: .footnote)).tracking(13 * 0.02)
            .foregroundStyle(ghost ? Color.radarAccentText : isOn ? Color.radarOnAccent : (configuration.isPressed ? Color.radarText : Color.radarText2))
            .padding(.horizontal, ghost ? 6 : 14)
            .frame(minHeight: 40)
            .background(isOn && !ghost ? Color.radarAccent : .clear)
            .overlay { if !ghost && !isOn { Rectangle().strokeBorder(Color.radarLineStrong, lineWidth: 1) } }
            .contentShape(Rectangle())
    }
}

/// `.slash`: "/ label" text link, 32 pt tall visually (hit area padded to 44 pt).
struct SlashButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 1) {
            Text("/").fontWeight(.bold).foregroundStyle(Color.radarAccentText)
            configuration.label.foregroundStyle(configuration.isPressed ? Color.radarText : Color.radarText2)
        }
        .font(RadarFont.ui(13, .semibold, relativeTo: .footnote)).tracking(13 * 0.01)
        .frame(minHeight: 32)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == RadarButtonStyle {
    static var radarPrimary: RadarButtonStyle { RadarButtonStyle(kind: .primary) }
    static var radarOutline: RadarButtonStyle { RadarButtonStyle(kind: .outline) }
    static func radar(_ kind: RadarButtonStyle.Kind, size: RadarButtonStyle.Size = .md, block: Bool = false) -> RadarButtonStyle {
        RadarButtonStyle(kind: kind, size: size, block: block)
    }
}
extension ButtonStyle where Self == CTAButtonStyle { static var radarCTA: CTAButtonStyle { CTAButtonStyle() } }
extension ButtonStyle where Self == SlashButtonStyle { static var radarSlash: SlashButtonStyle { SlashButtonStyle() } }
extension ButtonStyle where Self == TagButtonStyle {
    static func radarTag(on: Bool = false, ghost: Bool = false) -> TagButtonStyle { TagButtonStyle(isOn: on, ghost: ghost) }
}
