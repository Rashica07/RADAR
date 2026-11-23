import AVFoundation
import XCTest
@testable import RADAR

final class PlayQueueTests: XCTestCase {
    func testPlayWithListReplacesQueueAndSetsIndex() {
        var q = PlayQueue(ids: ["x"])
        q.play("b", in: ["a", "b", "c"])
        XCTAssertEqual(q.ids, ["a", "b", "c"]); XCTAssertEqual(q.current, "b")
        XCTAssertEqual(q.upcoming, ["c"]); XCTAssertEqual(q.history, ["a"])
    }

    func testPlayQueuedIdJumpsAndUnknownIdIsInsertedAfterCurrent() {
        var q = PlayQueue(ids: ["a", "b", "c"], index: 0)
        q.play("c"); XCTAssertEqual(q.index, 2)
        q.play("z"); XCTAssertEqual(q.ids, ["a", "b", "c", "z"]); XCTAssertEqual(q.current, "z")
        var m = PlayQueue(ids: ["a", "b", "c"], index: 0)
        m.play("z"); XCTAssertEqual(m.ids, ["a", "z", "b", "c"]); XCTAssertEqual(m.current, "z")
    }

    func testPlayIntoEmptyQueueWorks() {
        var q = PlayQueue()
        q.play("a"); XCTAssertEqual(q.ids, ["a"]); XCTAssertEqual(q.current, "a")
        var n = PlayQueue(); n.playNext("a"); XCTAssertEqual(n.current, "a")
    }

    func testPlayNextEnqueueAndClearUpcoming() {
        var q = PlayQueue(ids: ["a", "b", "c"], index: 1)
        q.playNext("n"); XCTAssertEqual(q.ids, ["a", "b", "n", "c"])
        q.enqueue("e"); XCTAssertEqual(q.ids.last, "e")
        q.clearUpcoming(); XCTAssertEqual(q.ids, ["a", "b"]); XCTAssertEqual(q.current, "b")
    }

    func testRemoveKeepsCurrentTrackCurrent() {
        var q = PlayQueue(ids: ["a", "b", "c", "d"], index: 2)
        q.remove(at: 0); XCTAssertEqual(q.current, "c"); XCTAssertEqual(q.index, 1)
        q.remove(at: 2); XCTAssertEqual(q.current, "c")            // after it: no effect on index
        q.remove(at: 1); XCTAssertEqual(q.current, "b")            // the current one: moves to what follows, or clamps
        q.remove(at: 0); q.remove(at: 0); XCTAssertTrue(q.isEmpty); XCTAssertNil(q.current)
        q.remove(at: 5)                                             // out of range is ignored
    }

    func testRemoveAllDropsEveryCopy() {
        var q = PlayQueue(ids: ["a", "x", "b", "x"], index: 3)
        q.removeAll("x")
        XCTAssertEqual(q.ids, ["a", "b"]); XCTAssertEqual(q.current, "b")
    }

    func testAdvanceInOrderRepeatAllAndEnd() {
        var q = PlayQueue(ids: ["a", "b"], index: 0)
        XCTAssertEqual(q.advance(shuffle: false, repeatMode: .off), .moved); XCTAssertEqual(q.current, "b")
        XCTAssertEqual(q.advance(shuffle: false, repeatMode: .off), .ended); XCTAssertEqual(q.current, "b")
        XCTAssertEqual(q.advance(shuffle: false, repeatMode: .all), .wrapped); XCTAssertEqual(q.current, "a")
        var empty = PlayQueue()
        XCTAssertEqual(empty.advance(shuffle: true, repeatMode: .all), .ended)
    }

    func testShufflePicksAnotherTrackAndNeverTheSameOne() {
        var q = PlayQueue(ids: ["a", "b", "c", "d"], index: 1)
        _ = q.advance(shuffle: true, repeatMode: .off, pick: { count, excluding in
            XCTAssertEqual(count, 4); XCTAssertEqual(excluding, 1); return 3 })
        XCTAssertEqual(q.current, "d")
        for _ in 0..<200 {
            let before = q.index
            _ = q.advance(shuffle: true, repeatMode: .off)
            XCTAssertNotEqual(q.index, before)
        }
        var single = PlayQueue(ids: ["a"])                         // one track: shuffle falls back to ordering rules
        XCTAssertEqual(single.advance(shuffle: true, repeatMode: .off), .ended)
    }

    func testPreviousRestartsAfterThreeSecondsOrAtTheStart() {
        var q = PlayQueue(ids: ["a", "b", "c"], index: 2)
        XCTAssertFalse(q.previous(progress: 3.5)); XCTAssertEqual(q.current, "c")
        XCTAssertTrue(q.previous(progress: 3)); XCTAssertEqual(q.current, "b")        // exactly 3 s still goes back
        XCTAssertTrue(q.previous(progress: 0)); XCTAssertEqual(q.current, "a")
        XCTAssertFalse(q.previous(progress: 0)); XCTAssertEqual(q.current, "a")
    }

    func testRepeatModeCycle() {
        XCTAssertEqual(RepeatMode.off.cycled, .all); XCTAssertEqual(RepeatMode.all.cycled, .one); XCTAssertEqual(RepeatMode.one.cycled, .off)
    }
}

@MainActor
private final class FakeBackend: AudioBackend {
    var onProgress: ((TimeInterval) -> Void)?
    var onFinish: (() -> Void)?
    var onInterruption: ((Bool, Bool) -> Void)?
    var onRouteLost: (() -> Void)?
    var log: [String] = []
    var failLoad = false
    func load(url: URL, startAt: TimeInterval) throws {
        if failLoad { throw NSError(domain: "t", code: 1) }
        log.append("load \(url.lastPathComponent)")
    }
    func play() { log.append("play") }
    func pause() { log.append("pause") }
    func seek(to seconds: TimeInterval) { log.append("seek \(Int(seconds))") }
    func setVolume(_ volume: Float) { log.append("vol \(volume)") }
    func stop() { log.append("stop") }
}

@MainActor
final class PlayerStoreTests: XCTestCase {
    private var tracks: [String: Track] = [:]
    private var played: [String] = []

    private func fake(_ id: String, local: Bool = false) -> Track {
        Track(id: id, title: "Track \(id)", artistId: "a", genre: "Jazz", duration: 10, daysAgo: 30, plays: 1,
              source: local ? .local : .catalog, download: local ? .local : .available, bpm: 100, explicit: false,
              discovery: false, why: nil, seed: id, albumId: nil,
              local: local ? .init(storedName: "\(id).m4a", originalName: "x.m4a", artistName: nil, albumTitle: nil, sizeBytes: 1, addedAt: .now) : nil)
    }

    override func setUp() async throws {
        tracks = Dictionary(uniqueKeysWithValues: (0..<5).map { ("t\($0)", fake("t\($0)")) })
        played = []
    }

    private func localTrack(_ id: String) -> Track { fake(id, local: true) }

    private func store(_ ids: [String] = ["t0", "t1", "t2"], backend: AudioBackend? = nil,
                       extra: [String: Track] = [:], urls: Bool = true) -> PlayerStore {
        let all = tracks.merging(extra) { $1 }
        return PlayerStore(queue: ids, backend: backend, resolve: { all[$0] },
                           localURL: { urls ? URL(fileURLWithPath: "/tmp/\($0.id).m4a") : nil },
                           onPlayed: { [unowned self] in played.append($0) },
                           pick: { _, ex in (ex + 1) % 3 }, runsClock: false)
    }

    func testDemoPlaybackAdvancesOnTheClockAndMovesToTheNextTrack() {
        let s = store()
        s.play("t0")
        XCTAssertTrue(s.isPlaying); XCTAssertTrue(s.isDemoPlayback)
        s.advanceClock(by: 4); XCTAssertEqual(s.progress, 4, accuracy: 1e-9)
        s.advanceClock(by: 6)                                                   // reaches 10 s: next track
        XCTAssertEqual(s.queue.current, "t1"); XCTAssertEqual(s.progress, 0); XCTAssertTrue(s.isPlaying)
    }

    func testStopsAtTheEndOfTheQueueUnlessRepeatAll() {
        let s = store(["t0", "t1"])
        s.play("t1"); s.advanceClock(by: 10)
        XCTAssertFalse(s.isPlaying); XCTAssertEqual(s.progress, 0); XCTAssertEqual(s.queue.current, "t1")
        s.repeatMode = .all; s.resume(); s.advanceClock(by: 10)
        XCTAssertEqual(s.queue.current, "t0"); XCTAssertTrue(s.isPlaying)
    }

    func testRepeatOneRestartsTheSameTrack() {
        let s = store(); s.repeatMode = .one
        s.play("t1"); s.advanceClock(by: 10)
        XCTAssertEqual(s.queue.current, "t1"); XCTAssertEqual(s.progress, 0); XCTAssertTrue(s.isPlaying)
    }

    func testClockOnlyRunsWhilePlaying() {
        let s = store(); s.play("t0"); s.pause()
        s.advanceClock(by: 5); XCTAssertEqual(s.progress, 0)
        s.toggle(); s.advanceClock(by: 5); XCTAssertEqual(s.progress, 5, accuracy: 1e-9)
    }

    func testPreviousRestartsLateAndGoesBackEarly() {
        let s = store(); s.play("t2")
        s.advanceClock(by: 5); s.previous()
        XCTAssertEqual(s.queue.current, "t2"); XCTAssertEqual(s.progress, 0)
        s.previous(); XCTAssertEqual(s.queue.current, "t1")
    }

    func testSeekClampsAndFractionTracksProgress() {
        let s = store(); s.play("t0")
        s.seek(fraction: 0.5); XCTAssertEqual(s.progress, 5, accuracy: 1e-9); XCTAssertEqual(s.fraction, 0.5, accuracy: 1e-9)
        s.seek(to: 99); XCTAssertEqual(s.progress, 10); s.seek(to: -4); XCTAssertEqual(s.progress, 0)
    }

    func testShuffleUsesTheInjectedPick() {
        let s = store(); s.toggleShuffle(); s.play("t0"); s.next()
        XCTAssertEqual(s.queue.current, "t1")
    }

    func testHistoryIsLoggedOncePerTrack() {
        let s = store(); s.play("t0"); s.pause(); s.resume(); s.advanceClock(by: 1); s.next()
        XCTAssertEqual(played, ["t0", "t1"])
    }

    func testQueueEditsWhileEmptyStartTheFirstTrackPaused() {
        let s = store([])
        s.enqueue("t3")
        XCTAssertEqual(s.current?.id, "t3"); XCTAssertFalse(s.isPlaying)
    }

    func testPurgeOfThePlayingTrackMovesOn() {
        let s = store(["t0", "t1", "t2"]); s.play("t1"); s.purge(trackId: "t1")
        XCTAssertEqual(s.queue.ids, ["t0", "t2"]); XCTAssertEqual(s.queue.current, "t2"); XCTAssertTrue(s.isPlaying)
    }

    func testMissingTrackSetsAnErrorInsteadOfCrashing() {
        let s = store(["t0", "gone"]); s.play("gone")
        XCTAssertFalse(s.isPlaying); XCTAssertNotNil(s.playbackError); XCTAssertNil(s.current)
    }

    func testLocalTrackUsesTheBackendAndIsNotDemo() {
        let b = FakeBackend(); let l = localTrack("loc")
        let s = store(["t0", "loc"], backend: b, extra: ["loc": l])
        s.play("loc")
        XCTAssertFalse(s.isDemoPlayback); XCTAssertTrue(s.isPlaying)
        XCTAssertEqual(b.log.filter { $0.hasPrefix("load") }, ["load loc.m4a"]); XCTAssertTrue(b.log.contains("play"))
        s.advanceClock(by: 5); XCTAssertEqual(s.progress, 0, "the demo clock must not drive a real track")
        b.onProgress?(7.5); XCTAssertEqual(s.progress, 7.5)
        s.pause(); XCTAssertEqual(b.log.last, "pause")
        s.seek(to: 3); XCTAssertEqual(b.log.last, "seek 3")
    }

    func testBackendFinishAndInterruptionAndRouteLoss() {
        let b = FakeBackend(); let l = localTrack("loc")
        let s = store(["loc", "t1"], backend: b, extra: ["loc": l])
        s.play("loc")
        b.onInterruption?(true, false); XCTAssertFalse(s.isPlaying)
        b.onInterruption?(false, true); XCTAssertTrue(s.isPlaying, "resumes after the interruption ends")
        b.onRouteLost?(); XCTAssertFalse(s.isPlaying)
        b.onInterruption?(false, true); XCTAssertFalse(s.isPlaying, "a manual pause is not undone by an old interruption")
        s.resume(); b.onFinish?()
        XCTAssertEqual(s.queue.current, "t1"); XCTAssertTrue(s.isDemoPlayback)
    }

    func testLocalFileMissingOrUnplayableReportsAnError() {
        let l = localTrack("loc")
        let noFile = store(["loc"], backend: FakeBackend(), extra: ["loc": l], urls: false)
        noFile.play("loc"); XCTAssertFalse(noFile.isPlaying); XCTAssertNotNil(noFile.playbackError)
        let b = FakeBackend(); b.failLoad = true
        let bad = store(["loc"], backend: b, extra: ["loc": l]); bad.play("loc")
        XCTAssertFalse(bad.isPlaying); XCTAssertNotNil(bad.playbackError)
    }

    func testVolumeAndMute() {
        let b = FakeBackend(); let s = store(backend: b)
        s.setVolume(0.5); XCTAssertEqual(b.log.last, "vol 0.5")
        s.toggleMute(); XCTAssertEqual(b.log.last, "vol 0.0")
        s.setVolume(0.7); XCTAssertFalse(s.muted)
        s.setVolume(7); XCTAssertEqual(s.volume, 1)
    }
}

@MainActor
final class AVPlayerBackendTests: XCTestCase {
    /// A real file through the real backend: it must report progress and then finish.
    func testRealFilePlaysToTheEnd() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("radar-test-\(UUID().uuidString).wav")
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        let frames = AVAudioFrameCount(44_100 * 1)                         // 1 s of silence
        do {
            let file = try AVAudioFile(forWriting: url, settings: format.settings)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
            buffer.frameLength = frames
            try file.write(from: buffer)
        }
        defer { try? FileManager.default.removeItem(at: url) }

        let backend = AVPlayerBackend()
        var progress: [TimeInterval] = []
        let finished = expectation(description: "finished")
        backend.onProgress = { progress.append($0) }
        backend.onFinish = { finished.fulfill() }
        try backend.load(url: url, startAt: 0)
        backend.setVolume(0)
        backend.play()
        await fulfillment(of: [finished], timeout: 10)
        XCTAssertFalse(progress.isEmpty, "progress callbacks must arrive while playing")
        XCTAssertTrue(progress.allSatisfy { $0 >= 0 && $0 <= 1.5 })
        backend.stop()
    }
}
