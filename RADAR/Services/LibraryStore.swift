import Foundation
import Observation

/// Saved tracks, play history, personal playlists and recent searches. Persisted locally.
@MainActor
@Observable
final class LibraryStore {
    private struct Snapshot: Codable {
        var saved: [String]
        var recent: [RecentPlay]
        var playlists: [UserPlaylist]
        var searches: [String]
    }

    private static let key = "library"
    private let persistence: PersistenceController
    private let catalog: DemoCatalog

    private(set) var saved: [String] { didSet { persist() } }
    private(set) var recent: [RecentPlay] { didSet { persist() } }
    private(set) var playlists: [UserPlaylist] { didSet { persist() } }
    private(set) var searches: [String] { didSet { persist() } }

    init(catalog: DemoCatalog, persistence: PersistenceController = .shared) {
        self.catalog = catalog
        self.persistence = persistence
        if let s = persistence.load(Snapshot.self, key: Self.key) {
            saved = s.saved
            recent = s.recent
            playlists = s.playlists
            searches = s.searches
        } else {
            let d = Self.defaults(catalog)
            saved = d.saved
            recent = d.recent
            playlists = d.playlists
            searches = d.searches
        }
    }

    private static func defaults(_ catalog: DemoCatalog) -> Snapshot {
        let now = Date()
        return Snapshot(
            saved: catalog.defaultSaved,
            recent: catalog.defaultRecent.map { RecentPlay(id: $0.id, at: now.addingTimeInterval(-$0.minsAgo * 60)) },
            playlists: catalog.personalPlaylistsSeed.map {
                UserPlaylist(id: $0.id, title: $0.title, trackIds: $0.trackIds, seed: $0.seed, blurb: $0.blurb)
            },
            searches: catalog.defaultRecentSearches
        )
    }

    private func persist() {
        persistence.save(Snapshot(saved: saved, recent: recent, playlists: playlists, searches: searches), key: Self.key)
    }

    // MARK: Saved

    func isSaved(_ id: String) -> Bool { saved.contains(id) }

    /// Returns true when the track is now saved.
    @discardableResult
    func toggleSave(_ id: String) -> Bool {
        if let i = saved.firstIndex(of: id) {
            saved.remove(at: i)
            return false
        }
        saved.insert(id, at: 0)
        return true
    }

    func unsave(_ id: String) {
        saved.removeAll { $0 == id }
    }

    // MARK: History

    func addRecent(_ id: String) {
        var next = recent.filter { $0.id != id }
        next.insert(RecentPlay(id: id, at: .now), at: 0)
        recent = Array(next.prefix(30))
    }

    // MARK: Playlists

    func playlist(_ id: String) -> UserPlaylist? { playlists.first { $0.id == id } }

    func createPlaylist() -> UserPlaylist {
        let n = playlists.filter { $0.title.hasPrefix("New playlist") }.count + 1
        let stamp = Int(Date().timeIntervalSince1970 * 1000)
        let playlist = UserPlaylist(
            id: "u-\(stamp)",
            title: "New playlist \(n)",
            trackIds: [],
            seed: "pl-user-\(stamp)",
            blurb: "Empty for now. Add tracks from any track menu."
        )
        playlists.insert(playlist, at: 0)
        return playlist
    }

    /// Returns false when the track was already in the playlist.
    @discardableResult
    func add(_ trackId: String, to playlistId: String) -> Bool {
        guard let i = playlists.firstIndex(where: { $0.id == playlistId }),
              !playlists[i].trackIds.contains(trackId) else { return false }
        playlists[i].trackIds.append(trackId)
        return true
    }

    func remove(at offset: Int, from playlistId: String) {
        guard let i = playlists.firstIndex(where: { $0.id == playlistId }),
              playlists[i].trackIds.indices.contains(offset) else { return }
        playlists[i].trackIds.remove(at: offset)
    }

    func rename(_ playlistId: String, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let i = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        playlists[i].title = trimmed
    }

    func deletePlaylist(_ playlistId: String) {
        playlists.removeAll { $0.id == playlistId }
    }

    /// Removes a track id everywhere (used when a local file is deleted).
    func purge(trackId: String) {
        saved.removeAll { $0 == trackId }
        recent.removeAll { $0.id == trackId }
        for i in playlists.indices { playlists[i].trackIds.removeAll { $0 == trackId } }
    }

    // MARK: Searches

    func addSearch(_ query: String) {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        var next = searches.filter { $0.lowercased() != q.lowercased() }
        next.insert(q, at: 0)
        searches = Array(next.prefix(8))
    }

    func removeSearch(_ query: String) { searches.removeAll { $0 == query } }
    func clearSearches() { searches = [] }

    // MARK: Reset

    func resetAll() {
        let d = Self.defaults(catalog)
        saved = d.saved
        recent = d.recent
        playlists = d.playlists
        searches = d.searches
    }
}
