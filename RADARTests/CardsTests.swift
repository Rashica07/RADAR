import XCTest
@testable import RADAR

final class CardsTests: XCTestCase {
    private func track(explicit: Bool = false) -> Track {
        DemoCatalog.shared.tracks.first!
    }

    func testRowLabelIncludesEverythingAVoiceOverUserNeeds() {
        var t = track()
        t.explicit = true
        let entry = ChartEntry(track: t, rank: 3, previous: 5, delta: 2)
        let m = TrackRowModel(track: t, artist: "Noor", entry: entry, isCurrent: true, isPlaying: true, isSaved: true, downloadProgress: 0.5)
        XCTAssertEqual(m.accessibilityLabel, "3. \(t.title), by Noor, explicit, up 2 places, now playing, saved, downloading 50 percent")
    }

    func testRowLabelPlainTrack() {
        var t = track(); t.explicit = false
        let m = TrackRowModel(track: t, artist: "Noor")
        XCTAssertEqual(m.accessibilityLabel, "\(t.title), by Noor")
        XCTAssertEqual(m.playHint, "Plays this track")
    }

    func testPausedCurrentTrackSaysPausedAndHintResumes() {
        let m = TrackRowModel(track: track(), artist: "A", isCurrent: true, isPlaying: false)
        XCTAssertTrue(m.accessibilityLabel.hasSuffix("paused"))
        XCTAssertEqual(m.playHint, "Resumes playback")
    }

    func testCollageFrameCounts() {
        let size = CGSize(width: 100, height: 100)
        XCTAssertEqual(CollageFrames.frames(count: 0, in: size).count, 0)
        for n in 1...4 { XCTAssertEqual(CollageFrames.frames(count: n, in: size).count, n) }
        XCTAssertEqual(CollageFrames.frames(count: 9, in: size).count, 4)
    }

    func testCollageFramesStayInsideAndDoNotOverlap() {
        let size = CGSize(width: 120, height: 120)
        for n in 1...4 {
            let f = CollageFrames.frames(count: n, in: size, spacing: 2)
            let bounds = CGRect(origin: .zero, size: size).insetBy(dx: -0.001, dy: -0.001)
            for r in f { XCTAssertTrue(bounds.contains(r), "n=\(n) \(r)") }
            for i in f.indices { for j in f.indices where j > i { XCTAssertFalse(f[i].intersects(f[j]), "n=\(n) \(i)/\(j)") } }
        }
    }

    func testGlyphOutlineFitsItsRect() {
        let rect = CGRect(x: 0, y: 0, width: 60, height: 56)
        let box = GlyphOutline(text: "12").path(in: rect).boundingRect
        XCTAssertFalse(box.isEmpty)
        XCTAssertLessThanOrEqual(box.width, 60.01)
        XCTAssertLessThanOrEqual(box.height, 56.01)
        XCTAssertGreaterThanOrEqual(box.minX, -0.01)
        XCTAssertGreaterThanOrEqual(box.minY, -0.01)
    }

    func testGlyphOutlineOfEmptyTextIsEmpty() {
        XCTAssertTrue(GlyphOutline(text: "").path(in: CGRect(x: 0, y: 0, width: 10, height: 10)).isEmpty)
    }
}
