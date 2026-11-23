import SwiftUI

/// Press feedback shared by every button: a quick spring down to 0.97, a light tap on press-down,
/// everything inside the 44 pt touch rule and growing with Dynamic Type.
private struct PressFeel: ViewModifier {
    let pressed: Bool
    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? 0.97 : 1)
            .animation(.spring(duration: 0.22, bounce: 0.2), value: pressed)
            .sensoryFeedback(.impact(weight: .light), trigger: pressed) { _, now in now && Haptics.isEnabled }
    }
}

/// Square control: filled (primary), outlined, or text only (ghost).
struct RadarButtonStyle: ButtonStyle {
    enum Kind { case primary, outline, ghost }
    enum Size { case sm, md, lg }
    var kind: Kind = .primary
    var size: Size = .md
    var block = false
    @Environment(\.isEnabled) private var enabled
    @ScaledMetric(relativeTo: .body) private var scale = 1

    private var height: CGFloat { size == .sm ? 40 : size == .lg ? 52 : 44 }
    private var pad: CGFloat { size == .sm ? 16 : size == .lg ? 26 : 20 }
    private var fontSize: CGFloat { size == .sm ? 12 : size == .lg ? 14 : 13 }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RadarFont.ui(fontSize, .bold, relativeTo: .footnote))
            .tracking(fontSize * 0.1).textCase(.uppercase).lineLimit(1)
            .foregroundStyle(kind == .primary ? Color.radarOnAccent : Color.radarText)
            .padding(.horizontal, pad)
            .frame(maxWidth: block ? .infinity : nil, minHeight: height * scale)
            .background(kind == .primary ? Color.radarAccent : .clear)
            .overlay { if kind != .primary { Rectangle().strokeBorder(Color.radarLineStrong, lineWidth: 1) } }
            .contentShape(Rectangle())
            .opacity(enabled ? 1 : 0.45)
            .modifier(PressFeel(pressed: configuration.isPressed))
    }
}

/// Big display-type call to action. A 3 pt accent underline floods the whole button while pressed.
struct CTAButtonStyle: ButtonStyle {
    @ScaledMetric(relativeTo: .title) private var minHeight: CGFloat = 48
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RadarFont.display(28, .extraBold, relativeTo: .title))
            .tracking(0.5).textCase(.uppercase)
            .foregroundStyle(configuration.isPressed ? Color.radarOnAccent : Color.radarText)
            .padding(.horizontal, 2).frame(minHeight: minHeight)
            .background(alignment: .bottom) {
                Color.radarAccent.frame(height: configuration.isPressed ? nil : 3)
            }
            .animation(.spring(duration: 0.28, bounce: 0.1), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, now in now && Haptics.isEnabled }
    }
}

/// Outlined chip; `on` fills it with the accent. `ghost` is text only.
struct TagButtonStyle: ButtonStyle {
    var isOn = false
    var ghost = false
    @ScaledMetric(relativeTo: .footnote) private var minHeight: CGFloat = 40
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RadarFont.ui(13, .semibold, relativeTo: .footnote)).tracking(0.3)
            .foregroundStyle(ghost ? Color.radarAccentText : isOn ? Color.radarOnAccent : (configuration.isPressed ? Color.radarText : Color.radarText2))
            .padding(.horizontal, ghost ? 6 : 14)
            .frame(minHeight: minHeight)
            .background(isOn && !ghost ? Color.radarAccent : .clear)
            .overlay { if !ghost && !isOn { Rectangle().strokeBorder(Color.radarLineStrong, lineWidth: 1) } }
            .contentShape(Rectangle())
            .modifier(PressFeel(pressed: configuration.isPressed))
            .sensoryFeedback(.selection, trigger: isOn) { _, _ in Haptics.isEnabled }
    }
}

/// "/ label" text link with a padded hit area.
struct SlashButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 1) {
            Text("/").fontWeight(.bold).foregroundStyle(Color.radarAccentText)
            configuration.label.foregroundStyle(configuration.isPressed ? Color.radarText : Color.radarText2)
        }
        .font(RadarFont.ui(13, .semibold, relativeTo: .footnote)).tracking(0.15)
        .frame(minHeight: RadarScale.touch)
        .contentShape(Rectangle())
        .modifier(PressFeel(pressed: configuration.isPressed))
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
