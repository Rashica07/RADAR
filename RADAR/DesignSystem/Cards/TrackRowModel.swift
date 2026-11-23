import Foundation

/// Everything a track row shows, resolved up front so the view stays dumb and the wording
/// (including the VoiceOver label) is unit-tested.
struct TrackRowModel: Equatable, Sendable, Identifiable {
    var id: String
    var title: String
    var artist: String
    var isExplicit = false
    var isLocal = false
    var duration: String
    var rank: Int?
    var move: ChartMove?
    var isCurrent = false
    var isPlaying = false
    var isSaved = false
    /// 0…1 while a (demo) download is running.
    var downloadProgress: Double?

    init(track: Track, artist: String, entry: ChartEntry? = nil, isCurrent: Bool = false,
         isPlaying: Bool = false, isSaved: Bool = false, downloadProgress: Double? = nil) {
        id = track.id
        title = track.title
        self.artist = artist
        isExplicit = track.explicit
        isLocal = track.isLocal
        duration = Format.time(track.duration)
        rank = entry?.rank
        move = entry.map { ChartMove(delta: $0.delta, previous: $0.previous) }
        self.isCurrent = isCurrent
        self.isPlaying = isPlaying
        self.isSaved = isSaved
        self.downloadProgress = downloadProgress
    }

    /// "3. Ottobre, by Noor, explicit, up 2 places, now playing, saved"
    var accessibilityLabel: String {
        var parts: [String] = []
        let head = rank.map { "\($0). \(title), by \(artist)" } ?? "\(title), by \(artist)"
        parts.append(head)
        if isExplicit { parts.append("explicit") }
        if let move { parts.append(move.accessibilityLabel.lowercased()) }
        if isCurrent { parts.append(isPlaying ? "now playing" : "paused") }
        if isSaved { parts.append("saved") }
        if let p = downloadProgress { parts.append("downloading \(Int((p * 100).rounded())) percent") }
        return parts.joined(separator: ", ")
    }

    var playHint: String { isCurrent ? (isPlaying ? "Pauses playback" : "Resumes playback") : "Plays this track" }
}

/// What a row can do. The row itself never reaches into stores.
struct TrackRowActions {
    var play: () -> Void
    var playNext: () -> Void = {}
    var enqueue: () -> Void = {}
    var toggleSave: (() -> Void)?
    var addToPlaylist: (() -> Void)?
    var openDetails: (() -> Void)?
}
