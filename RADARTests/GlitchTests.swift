import XCTest
@testable import RADAR

final class GlitchTests: XCTestCase {
    private struct Case: Decodable {
        struct Band: Decodable {
            let y: Double
            let h: Double
            let length: Double
        }
        let seed: UInt32
        let height: Double
        let amount: Double
        let maxLength: Double
        let bands: [Band]
    }

    /// The Swift generator and tools/glitch.js (which renders the alternate app icon)
    /// must produce identical bands, so the icon and the animated logo share one look.
    func testBandsMatchTheJavaScriptReference() throws {
        let cases = try JSONDecoder().decode([Case].self, from: Fixture.data("GlitchVectors"))
        XCTAssertFalse(cases.isEmpty)
        for c in cases {
            let bands = GlitchSpec.bands(seed: c.seed, height: c.height, amount: c.amount, maxLength: c.maxLength)
            XCTAssertEqual(bands.count, c.bands.count, "band count for seed \(c.seed)")
            for (ours, theirs) in zip(bands, c.bands) {
                XCTAssertEqual(ours.y, theirs.y, accuracy: 1e-9)
                XCTAssertEqual(ours.h, theirs.h, accuracy: 1e-9)
                XCTAssertEqual(ours.length, theirs.length, accuracy: 1e-9)
            }
        }
    }

    func testNoGlitchAmountProducesNoTrails() {
        let bands = GlitchSpec.bands(seed: 7, height: 207, amount: 0, maxLength: 80)
        XCTAssertTrue(bands.allSatisfy { $0.length == 0 })
    }

    func testBandsTileTheWholeHeightWithoutOverlap() {
        let bands = GlitchSpec.bands(seed: 99, height: 207, amount: 1, maxLength: 80)
        var expectedY = 0.0
        for band in bands {
            XCTAssertEqual(band.y, expectedY, accuracy: 1e-9)
            expectedY += band.h
        }
        XCTAssertEqual(expectedY, 207, accuracy: 1e-9)
    }

    func testLongestTrailsSitAtTheTopBarAndTheLeg() {
        let bands = GlitchSpec.bands(seed: GlitchSpec.defaultSeed, height: 207, amount: 1, maxLength: 80)
        func peak(_ range: ClosedRange<Double>) -> Double {
            bands.filter { range.contains($0.y / 207) }.map(\.length).max() ?? 0
        }
        XCTAssertGreaterThan(peak(0.05...0.35), peak(0.45...0.65))
        XCTAssertGreaterThan(peak(0.80...1.0), peak(0.45...0.65))
    }

    func testTrailOpacityFadesOut() {
        let alphas = (1...GlitchSpec.trailCopies).map(GlitchSpec.trailAlpha)
        XCTAssertEqual(alphas, alphas.sorted(by: >))
        XCTAssertGreaterThanOrEqual(alphas.last ?? -1, 0)
        XCTAssertLessThanOrEqual(alphas.first ?? 2, 1)
    }
}

final class RadarRevealTests: XCTestCase {
    func testOpensFullyGlitchedAndColorless() {
        let frame = RadarReveal.frame(at: 0)
        XCTAssertEqual(frame.glitch, 1)
        XCTAssertEqual(frame.tint, 0)
    }

    func testEndsOnTheCleanLogo() {
        XCTAssertEqual(RadarReveal.frame(at: RadarReveal.duration), .clean)
        XCTAssertEqual(RadarReveal.frame(at: RadarReveal.duration + 5), .clean)
    }

    func testStreaksAreGoneBeforeTheColorFinishesResolving() {
        let late = RadarReveal.frame(at: 0.78)
        XCTAssertEqual(late.glitch, 0)
    }

    func testColorResolvesMonotonically() {
        var previous = -1.0
        for i in 0...100 {
            let tint = RadarReveal.frame(at: Double(i) / 100 * RadarReveal.duration).tint
            XCTAssertGreaterThanOrEqual(tint, previous)
            XCTAssertTrue((0...1).contains(tint))
            previous = tint
        }
    }

    func testEveryStepRerollsTheStreakLayout() {
        let seeds = Set((0...9).map(RadarReveal.seed(forStep:)))
        XCTAssertEqual(seeds.count, 10)
    }

    func testNegativeTimeBehavesLikeTheStart() {
        XCTAssertEqual(RadarReveal.frame(at: -1), RadarReveal.frame(at: 0))
    }
}
