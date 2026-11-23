import Foundation

/// One of the ten artwork palettes. Each artist owns a palette; each release picks a composition.
enum ArtPalette: String, Codable, CaseIterable, Hashable, Sendable {
    case ember, ultramarine, ochre, plum, moss, bone, lagoon, rose, slate, clay

    /// Four colors: background, primary, secondary, highlight (hex, 0xRRGGBB).
    var hex: [UInt32] {
        switch self {
        case .ember: [0x2B1410, 0xE8553D, 0xF2A65A, 0xF6E3C4]
        case .ultramarine: [0x0E1B3D, 0x3B5BFF, 0x9AB0FF, 0xF1F0E9]
        case .ochre: [0x2A2108, 0xE0A82E, 0xF3D77A, 0x8A6A14]
        case .plum: [0x24112B, 0xA24BCF, 0xE7A6F2, 0xFFD9F5]
        case .moss: [0x10201A, 0x4FA36A, 0xB7E08C, 0xF1F0E9]
        case .bone: [0xE9E4D4, 0x101413, 0xFF7F76, 0x79E2C0]
        case .lagoon: [0x0A2A2E, 0x2CC5C0, 0x79E2C0, 0xE8FFF8]
        case .rose: [0x3A1520, 0xFF6F91, 0xFFC2D1, 0xFFF0F3]
        case .slate: [0x1D2330, 0x7C8BA8, 0xC7D0E3, 0xFF7F76]
        case .clay: [0x3B2A22, 0xC98A62, 0xEBC9A6, 0xF6EFE4]
        }
    }
}

/// One of the eight generative compositions.
enum ArtStyle: String, Codable, CaseIterable, Hashable, Sendable {
    case rings, sweep, bars, dots, arcs, blocks, waves, orbit
}

/// Everything needed to draw a cover: a seed, a palette and a composition.
struct ArtSpec: Hashable, Sendable {
    let seed: UInt32
    let palette: ArtPalette
    let style: ArtStyle

    init(seed: UInt32, palette: ArtPalette, style: ArtStyle) {
        self.seed = seed
        self.palette = palette
        self.style = style
    }

    /// Derives palette and style from a key, unless overridden. Same rules as the web build.
    init(key: String, palette: ArtPalette? = nil, style: ArtStyle? = nil) {
        let seed = SeededHash.fnv1a(key)
        let palettes = ArtPalette.allCases
        let styles = ArtStyle.allCases
        self.seed = seed
        self.palette = palette ?? palettes[Int(seed % UInt32(palettes.count))]
        self.style = style ?? styles[Int((seed >> 4) % UInt32(styles.count))]
    }
}
