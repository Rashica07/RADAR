import Foundation

/// One horizontal slice of the brand "speed smear" glitch.
struct GlitchBand: Equatable, Sendable {
    /// Top of the band, in the artwork's own coordinate space.
    let y: Double
    let h: Double
    /// How far the artwork smears to the left inside this band. 0 = untouched.
    let length: Double
}

/// The RADAR glitch: horizontal bands inside which the artwork is smeared to the left
/// by a fading trail of copies. Bands near the symbol's top bar and its bottom leg get
/// the longest trails, matching the brand sheet.
///
/// This is the single source of truth for the effect. `tools/glitch.js` is its twin and
/// generates the alternate app icon, so the icon and the animated logo share one look.
/// `GlitchParityTests` checks the two implementations against each other.
enum GlitchSpec {
    static let trailCopies = 8
    static let defaultSeed: UInt32 = 7
    /// Longest smear, as a fraction of the symbol's width.
    static let symbolMaxLengthFactor = 0.22

    /// Opacity of the k-th trail copy (k = 1...trailCopies).
    static func trailAlpha(_ k: Int) -> Double {
        pow(1 - Double(k) / Double(trailCopies), 0.8) * 0.95
    }

    static func bands(seed: UInt32, height: Double, amount: Double, maxLength: Double) -> [GlitchBand] {
        var rng = SeededRandom(seed: seed)
        var out: [GlitchBand] = []
        var y = 0.0
        while y < height {
            let h = 1.5 + rng.next() * 5.5
            let r1 = rng.next()
            let r2 = rng.next()
            let yn = (y + h / 2) / height
            let weight = 0.10 + 0.90 * max(bump(yn, 0.20, 0.13), bump(yn, 0.93, 0.12))
            let active = r1 < 0.10 + 0.75 * weight
            let length = active ? amount * maxLength * weight * (0.25 + 0.75 * r2) : 0
            out.append(GlitchBand(y: y, h: min(h, height - y), length: length))
            y += h
        }
        return out
    }

    private static func bump(_ x: Double, _ centre: Double, _ spread: Double) -> Double {
        let d = (x - centre) / spread
        return exp(-(d * d))
    }
}
