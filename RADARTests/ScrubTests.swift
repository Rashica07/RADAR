import XCTest
@testable import RADAR

final class ScrubTests: XCTestCase {
    func testFractionClampsAtBothEnds() {
        XCTAssertEqual(ScrubMath.fraction(x: -30, width: 200), 0)
        XCTAssertEqual(ScrubMath.fraction(x: 500, width: 200), 1)
        XCTAssertEqual(ScrubMath.fraction(x: 50, width: 200), 0.25, accuracy: 1e-9)
        XCTAssertEqual(ScrubMath.fraction(x: 10, width: 0), 0)
    }

    func testBarCount() {
        XCTAssertEqual(ScrubMath.barCount(width: 0), 0)
        XCTAssertEqual(ScrubMath.barCount(width: 1), 1)
        XCTAssertEqual(ScrubMath.barCount(width: 100, bar: 3, gap: 2), 20)    // 20*3 + 19*2 = 98 ≤ 100
        XCTAssertEqual(ScrubMath.barCount(width: 98, bar: 3, gap: 2), 20)
        XCTAssertEqual(ScrubMath.barCount(width: 97, bar: 3, gap: 2), 19)
    }

    func testHeightsResampleAndStayInRange() {
        let raw = DemoCatalog.rawWaveform(trackId: "t1")
        let h = ScrubMath.heights(peaks: raw, count: 40)
        XCTAssertEqual(h.count, 40)
        XCTAssertTrue(h.allSatisfy { $0 >= 0.12 && $0 <= 1 })
        XCTAssertEqual(ScrubMath.heights(peaks: [], count: 10), [])
        XCTAssertEqual(ScrubMath.heights(peaks: raw, count: 0), [])
        XCTAssertEqual(h, ScrubMath.heights(peaks: raw, count: 40), "deterministic")
    }

    func testPlayedCount() {
        XCTAssertEqual(ScrubMath.playedCount(progress: 0, bars: 50), 0)
        XCTAssertEqual(ScrubMath.playedCount(progress: 1, bars: 50), 50)
        XCTAssertEqual(ScrubMath.playedCount(progress: 0.5, bars: 50), 25)
        XCTAssertEqual(ScrubMath.playedCount(progress: 1.4, bars: 50), 50)
        XCTAssertEqual(ScrubMath.playedCount(progress: -1, bars: 50), 0)
    }

    func testLensPeaksUnderFingerAndFadesOut() {
        let under = ScrubMath.lens(barIndex: 10, centre: 10.0 / 19, bars: 20)
        XCTAssertEqual(under, 1.35, accuracy: 1e-9)
        XCTAssertEqual(ScrubMath.lens(barIndex: 0, centre: 1, bars: 20), 1)
        let near = ScrubMath.lens(barIndex: 12, centre: 10.0 / 19, bars: 20)
        XCTAssertTrue(near > 1 && near < under)
    }

    func testSpokenValueAndStep() {
        XCTAssertEqual(ScrubMath.spokenValue(progress: 0.5, duration: 200), "1:40 of 3:20")
        XCTAssertEqual(ScrubMath.step(duration: 200), 0.025, accuracy: 1e-9)
        XCTAssertEqual(ScrubMath.step(duration: 10), 0.05)
    }
}
