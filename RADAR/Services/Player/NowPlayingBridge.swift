import MediaPlayer
import SwiftUI

/// Connects `PlayerStore` to the lock screen, Control Center and headphone buttons.
/// Only real audio (imported local files) is published: demo tracks are silent, and claiming the
/// system's "Now Playing" slot for silence would hijack the user's actual music controls.
@MainActor
final class NowPlayingBridge {
    private let store: PlayerStore
    private let center = MPNowPlayingInfoCenter.default()
    private let commands = MPRemoteCommandCenter.shared()
    private var artworkFor: String?
    private var artwork: MPMediaItemArtwork?
    private let artist: (Track) -> String
    private let art: (Track) -> ArtSpec

    init(store: PlayerStore, artist: @escaping (Track) -> String, art: @escaping (Track) -> ArtSpec) {
        self.store = store
        self.artist = artist
        self.art = art
        registerCommands()
        store.onNowPlayingChange = { [weak self] in self?.refresh() }
    }

    func refresh() {
        guard let track = store.current, !store.isDemoPlayback else {
            center.nowPlayingInfo = nil
            center.playbackState = .stopped
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: artist(track),
            MPMediaItemPropertyPlaybackDuration: store.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: store.progress,
            MPNowPlayingInfoPropertyPlaybackRate: store.isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0
        ]
        if artworkFor != track.id {
            artworkFor = track.id
            artwork = Self.makeArtwork(art(track))
        }
        if let artwork { info[MPMediaItemPropertyArtwork] = artwork }
        center.nowPlayingInfo = info
        center.playbackState = store.isPlaying ? .playing : .paused
        commands.previousTrackCommand.isEnabled = true
        commands.nextTrackCommand.isEnabled = !store.queue.isEmpty
    }

    private func registerCommands() {
        commands.playCommand.addTarget { [weak self] _ in self?.store.resume(); return .success }
        commands.pauseCommand.addTarget { [weak self] _ in self?.store.pause(); return .success }
        commands.togglePlayPauseCommand.addTarget { [weak self] _ in self?.store.toggle(); return .success }
        commands.nextTrackCommand.addTarget { [weak self] _ in self?.store.next(); return .success }
        commands.previousTrackCommand.addTarget { [weak self] _ in self?.store.previous(); return .success }
        commands.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.store.seek(to: e.positionTime)
            return .success
        }
    }

    private static func makeArtwork(_ spec: ArtSpec) -> MPMediaItemArtwork? {
        let renderer = ImageRenderer(content: ArtworkView(spec).frame(width: 600, height: 600))
        renderer.scale = 1
        guard let image = renderer.uiImage else { return nil }
        return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }
}
