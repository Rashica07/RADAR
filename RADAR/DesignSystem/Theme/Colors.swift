import SwiftUI

/// A plain sRGB triple, used where colors are interpolated (brand tint transitions).
struct RadarRGB: Equatable, Sendable {
    var r: Double
    var g: Double
    var b: Double

    init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    init(hex: UInt32) {
        r = Double((hex >> 16) & 0xFF) / 255
        g = Double((hex >> 8) & 0xFF) / 255
        b = Double(hex & 0xFF) / 255
    }

    var color: Color { Color(.sRGB, red: r, green: g, blue: b, opacity: 1) }

    func mixed(with other: RadarRGB, _ t: Double) -> RadarRGB {
        let k = max(0, min(1, t))
        return RadarRGB(r: r + (other.r - r) * k, g: g + (other.g - g) * k, b: b + (other.b - b) * k)
    }

    // Brand palette (fixed — identical in dark and paper themes).
    static let mint = RadarRGB(hex: 0x79E2C0)
    static let coral = RadarRGB(hex: 0xFF7F76)
    static let charcoal = RadarRGB(hex: 0x101413)
    static let warm = RadarRGB(hex: 0xF1F0E9)
    static let graphite = RadarRGB(hex: 0x252B29)
}

extension Color {
    // MARK: Brand (fixed)
    static let radarMint = RadarRGB.mint.color
    static let radarCoral = RadarRGB.coral.color
    static let radarCharcoal = RadarRGB.charcoal.color
    static let radarWarm = RadarRGB.warm.color
    static let radarGraphite = RadarRGB.graphite.color

    // MARK: Theme (asset catalog; adapts between Dark and Paper)
    static let radarBg = Color("Theme/bg")
    static let radarSurface = Color("Theme/surface")
    static let radarSurface2 = Color("Theme/surface2")
    static let radarSurface3 = Color("Theme/surface3")
    static let radarText = Color("Theme/text")
    static let radarText2 = Color("Theme/text2")
    static let radarText3 = Color("Theme/text3")
    static let radarLine = Color("Theme/line")
    static let radarLineStrong = Color("Theme/lineStrong")
    static let radarAccent = Color("Theme/accent")
    static let radarOnAccent = Color("Theme/onAccent")
    static let radarAccentText = Color("Theme/accentText")
    static let radarAccentSoft = Color("Theme/accentSoft")
    static let radarSignal = Color("Theme/signal")
    static let radarOnSignal = Color("Theme/onSignal")
    static let radarSignalText = Color("Theme/signalText")
    static let radarSignalSoft = Color("Theme/signalSoft")
    static let radarScrim = Color("Theme/scrim")
    static let radarNavBg = Color("Theme/navBg")
}
