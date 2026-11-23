import AVFoundation
import Foundation

/// What the player needs from something that really makes sound. The store only talks to this,
/// so tests use a fake and demo tracks (which have no audio) never touch it.
@MainActor
protocol AudioBackend: AnyObject {
    var onProgress: ((TimeInterval) -> Void)? { get set }
    var onFinish: (() -> Void)? { get set }
    /// The system interrupted playback (call, Siri, another app). `shouldResume` is set when it ended and resuming is fine.
    var onInterruption: ((_ began: Bool, _ shouldResume: Bool) -> Void)? { get set }
    /// Headphones unplugged or the route went away: pause.
    var onRouteLost: (() -> Void)? { get set }

    func load(url: URL, startAt: TimeInterval) throws
    func play()
    func pause()
    func seek(to seconds: TimeInterval)
    func setVolume(_ volume: Float)
    func stop()
}

/// Plays local files with `AVPlayer` under the `.playback` category so it keeps going with the screen
/// locked and shows up in Control Center and on the lock screen.
@MainActor
final class AVPlayerBackend: AudioBackend {
    var onProgress: ((TimeInterval) -> Void)?
    var onFinish: (() -> Void)?
    var onInterruption: ((Bool, Bool) -> Void)?
    var onRouteLost: (() -> Void)?

    private let player = AVPlayer()
    private var timeObserver: Any?
    private var observers: [NSObjectProtocol] = []

    init() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            let info = note.userInfo
            let type = (info?[AVAudioSessionInterruptionTypeKey] as? UInt).flatMap(AVAudioSession.InterruptionType.init)
            let options = AVAudioSession.InterruptionOptions(rawValue: (info?[AVAudioSessionInterruptionOptionKey] as? UInt) ?? 0)
            Task { @MainActor in
                switch type {
                case .began: self?.onInterruption?(true, false)
                case .ended: self?.onInterruption?(false, options.contains(.shouldResume))
                default: break
                }
            }
        })
        observers.append(center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] note in
            let reason = (note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt).flatMap(AVAudioSession.RouteChangeReason.init)
            if reason == .oldDeviceUnavailable { Task { @MainActor in self?.onRouteLost?() } }
        })
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.25, preferredTimescale: 600), queue: .main) { [weak self] t in
            let s = t.seconds
            if s.isFinite { Task { @MainActor in self?.onProgress?(s) } }
        }
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
        if let timeObserver { player.removeTimeObserver(timeObserver) }
    }

    func load(url: URL, startAt: TimeInterval) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        observers.append(NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.onFinish?() }
        })
        if startAt > 0 { seek(to: startAt) }
    }

    func play() { player.play() }
    func pause() { player.pause() }
    func seek(to seconds: TimeInterval) {
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
    }
    func setVolume(_ volume: Float) { player.volume = volume }
    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
    }
}
