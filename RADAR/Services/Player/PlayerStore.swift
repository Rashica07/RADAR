import Foundation
import Observation

/// Playback state for the whole app: the queue, what is playing, and where in the track it is.
///
/// Two kinds of track:
/// - **Demo tracks** have no audio. A 250 ms clock advances `progress` so the UI behaves like a player;
///   the interface says "Demo playback" (`isDemoPlayback`).
/// - **Local files** (imported by the user) play for real through an `AudioBackend`.
@MainActor
@Observable
final class PlayerStore {
    private(set) var queue: PlayQueue
    private(set) var isPlaying = false
    /// Seconds into the current track.
    private(set) var progress: TimeInterval = 0
    private(set) var playbackError: String?
    var shuffle = false
    var repeatMode: RepeatMode = .off
    private(set) var volume = 0.8
    private(set) var muted = false
    var expanded = false
    var dockOpen = false

    @ObservationIgnored private let resolve: (String) -> Track?
    @ObservationIgnored private let localURL: (Track) -> URL?
    @ObservationIgnored private let backend: AudioBackend?
    @ObservationIgnored private let onPlayed: (String) -> Void
    @ObservationIgnored private let pick: (Int, Int) -> Int
    @ObservationIgnored private var clock: Task<Void, Never>?
    @ObservationIgnored private var lastLogged: String?
    @ObservationIgnored private var resumeAfterInterruption = false
    /// Called after anything the lock screen cares about changed (track, play/pause, seek).
    @ObservationIgnored var onNowPlayingChange: (() -> Void)?

    static let tick: TimeInterval = 0.25

    init(queue ids: [String] = [], index: Int = 0,
         backend: AudioBackend? = nil,
         resolve: @escaping (String) -> Track?,
         localURL: @escaping (Track) -> URL? = { _ in nil },
         onPlayed: @escaping (String) -> Void = { _ in },
         pick: @escaping (Int, Int) -> Int = PlayQueue.randomOther,
         runsClock: Bool = true) {
        queue = PlayQueue(ids: ids, index: index)
        self.backend = backend
        self.resolve = resolve
        self.localURL = localURL
        self.onPlayed = onPlayed
        self.pick = pick
        self.runsClockEnabled = runsClock
        wireBackend()
    }

    @ObservationIgnored private let runsClockEnabled: Bool

    // MARK: Read

    var current: Track? { queue.current.flatMap(resolve) }
    var queueTracks: [Track] { queue.ids.compactMap(resolve) }
    var upcomingTracks: [Track] { queue.upcoming.compactMap(resolve) }
    var duration: TimeInterval { Double(current?.duration ?? 0) }
    var fraction: Double { duration > 0 ? min(1, progress / duration) : 0 }
    /// True when the current track has no real audio behind it.
    var isDemoPlayback: Bool {
        guard let t = current else { return false }
        return !(t.isLocal && localURL(t) != nil)
    }
    private var usesBackend: Bool { backend != nil && !isDemoPlayback && current != nil }

    // MARK: Transport

    func play(_ id: String, in list: [String]? = nil) {
        queue.play(id, in: list)
        startCurrent(autoplay: true)
    }

    func toggle() {
        guard current != nil else { return }
        if isPlaying { pause() } else { resume() }
    }

    func pause() {
        guard isPlaying else { return }
        isPlaying = false
        if usesBackend { backend?.pause() }
        stopClock()
        onNowPlayingChange?()
    }

    func resume() {
        guard current != nil, !isPlaying else { return }
        if playbackError != nil { startCurrent(autoplay: true); return }
        isPlaying = true
        if usesBackend { backend?.play() } else { startClock() }
        log()
        onNowPlayingChange?()
    }

    func next() {
        guard !queue.isEmpty else { return }
        let result = queue.advance(shuffle: shuffle, repeatMode: repeatMode, pick: pick)
        if result == .ended {
            // Past the last track: stop at the start of it, like the original.
            isPlaying = false; progress = 0; stopClock()
            if usesBackend { backend?.pause(); backend?.seek(to: 0) }
            onNowPlayingChange?()
        } else {
            startCurrent(autoplay: true)
        }
    }

    func previous() {
        if queue.previous(progress: progress) {
            startCurrent(autoplay: true)
        } else {
            seek(to: 0)
        }
    }

    func seek(to seconds: TimeInterval) {
        progress = min(max(seconds, 0), duration)
        if usesBackend { backend?.seek(to: progress) }
        onNowPlayingChange?()
    }

    func seek(fraction f: Double) { seek(to: min(max(f, 0), 1) * duration) }

    func jump(to index: Int) {
        queue.jump(to: index)
        startCurrent(autoplay: true)
    }

    // MARK: Queue edits

    func playNext(_ id: String) {
        let wasEmpty = queue.isEmpty
        queue.playNext(id)
        if wasEmpty { startCurrent(autoplay: false) }
    }

    func enqueue(_ id: String) {
        let wasEmpty = queue.isEmpty
        queue.enqueue(id)
        if wasEmpty { startCurrent(autoplay: false) }
    }

    func removeAt(_ i: Int) {
        let was = queue.current
        queue.remove(at: i)
        if queue.current != was { startCurrent(autoplay: isPlaying) }
    }

    func clearUpcoming() { queue.clearUpcoming() }

    /// A local file was deleted: drop it from the queue (and stop it if it was playing).
    func purge(trackId: String) {
        let was = queue.current
        queue.removeAll(trackId)
        if was == trackId { startCurrent(autoplay: isPlaying) }
    }

    // MARK: Modes and volume

    func toggleShuffle() { shuffle.toggle() }
    func cycleRepeat() { repeatMode = repeatMode.cycled }
    func setVolume(_ v: Double) {
        volume = min(max(v, 0), 1)
        if v > 0 { muted = false }
        applyVolume()
    }
    func toggleMute() { muted.toggle(); applyVolume() }
    private func applyVolume() { backend?.setVolume(muted ? 0 : Float(volume)) }

    // MARK: Engine

    /// Moves the demo clock. Called every 250 ms while a demo track plays; tests call it directly.
    func advanceClock(by dt: TimeInterval = PlayerStore.tick) {
        guard isPlaying, isDemoPlayback, current != nil else { return }
        let end = duration
        progress += dt
        if progress >= end { trackFinished() }
    }

    private func trackFinished() {
        if repeatMode == .one {
            progress = 0
            if usesBackend { backend?.seek(to: 0); backend?.play() }
            onNowPlayingChange?()
        } else {
            next()
        }
    }

    private func startCurrent(autoplay: Bool) {
        stopClock()
        progress = 0
        playbackError = nil
        guard let track = current else {
            isPlaying = false
            if queue.current != nil { playbackError = "This track is no longer available." }
            backend?.stop()
            onNowPlayingChange?()
            return
        }
        if track.isLocal {
            guard let url = localURL(track), let backend else {
                isPlaying = false
                playbackError = "The file for \u{201C}\(track.title)\u{201D} can't be found."
                onNowPlayingChange?()
                return
            }
            do {
                try backend.load(url: url, startAt: 0)
                applyVolume()
                isPlaying = autoplay
                if autoplay { backend.play() }
            } catch {
                isPlaying = false
                playbackError = "Couldn't play \u{201C}\(track.title)\u{201D}."
            }
        } else {
            backend?.stop()
            isPlaying = autoplay
            if autoplay { startClock() }
        }
        if isPlaying { log() }
        onNowPlayingChange?()
    }

    private func startClock() {
        guard runsClockEnabled else { return }
        stopClock()
        clock = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }
                self?.advanceClock()
            }
        }
    }

    private func stopClock() { clock?.cancel(); clock = nil }

    /// History gets one entry per track that starts playing, not one per tick.
    private func log() {
        guard let id = queue.current, id != lastLogged else { return }
        lastLogged = id
        onPlayed(id)
    }

    private func wireBackend() {
        backend?.onProgress = { [weak self] t in
            guard let self, self.isPlaying, self.usesBackend else { return }
            self.progress = t
        }
        backend?.onFinish = { [weak self] in self?.trackFinished() }
        backend?.onInterruption = { [weak self] began, shouldResume in
            guard let self else { return }
            if began {
                self.resumeAfterInterruption = self.isPlaying
                self.pause()
            } else if shouldResume && self.resumeAfterInterruption {
                self.resumeAfterInterruption = false
                self.resume()
            }
        }
        backend?.onRouteLost = { [weak self] in self?.pause() }
    }
}
