import SwiftUI

/// RADAR's three type voices, from the Phase 01 tokens:
/// - **Display** — Big Shoulders Display, uppercase, tight. Headlines, ranks, numbers.
/// - **UI** — Space Grotesk. Titles, labels, readouts, buttons.
/// - **Body** — Inter. Reading text and small figures.
///
/// Fonts are bundled static instances (see Resources/Fonts) registered through
/// `UIAppFonts`. All sizes scale with Dynamic Type relative to a text style.
enum RadarFont {
    enum Display: String {
        case bold = "BigShouldersDisplay-Bold"
        case extraBold = "BigShouldersDisplay-ExtraBold"
        case black = "BigShouldersDisplay-Black"
    }

    enum UI: String {
        case medium = "SpaceGrotesk-Medium"
        case semibold = "SpaceGrotesk-SemiBold"
        case bold = "SpaceGrotesk-Bold"
    }

    enum Body: String {
        case regular = "Inter-Regular"
        case medium = "Inter-Medium"
        case semibold = "Inter-SemiBold"
        case bold = "Inter-Bold"
    }

    static func display(_ size: CGFloat, _ weight: Display = .black, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .custom(weight.rawValue, size: size, relativeTo: style)
    }

    static func ui(_ size: CGFloat, _ weight: UI = .semibold, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(weight.rawValue, size: size, relativeTo: style)
    }

    static func body(_ size: CGFloat, _ weight: Body = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(weight.rawValue, size: size, relativeTo: style)
    }

    /// Font file names that must be listed under `UIAppFonts` in Info.plist.
    static let bundledFiles: [String] = [
        "BigShouldersDisplay-Bold.ttf", "BigShouldersDisplay-ExtraBold.ttf", "BigShouldersDisplay-Black.ttf",
        "SpaceGrotesk-Medium.ttf", "SpaceGrotesk-SemiBold.ttf", "SpaceGrotesk-Bold.ttf",
        "Inter-Regular.ttf", "Inter-Medium.ttf", "Inter-SemiBold.ttf", "Inter-Bold.ttf",
    ]
}

extension View {
    /// The "readout" style: 11 pt Space Grotesk, uppercase, wide tracking.
    func radarReadout(_ color: Color = .radarText3) -> some View {
        font(RadarFont.ui(11, .semibold, relativeTo: .caption2))
            .tracking(11 * 0.13)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}
