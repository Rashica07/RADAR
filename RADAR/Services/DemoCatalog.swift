import Foundation

/// The fictional Phase 01 catalog plus every derived view of it: charts, movers,
/// rising artists, search, related tracks, artwork specs, sparklines and waveforms.
///
/// All of it is **demo data**. The algorithms are ported 1:1 from the web artifact
/// (and verified against it in `ParityTests`), so numbers and orderings match.
final class DemoCatalog: Sendable {
    static let shared: DemoCatalog = {
        guard let url = Bundle.main.url(forResource: "DemoCatalog", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            fatalError("DemoCatalog.json is missing from the app bundle.")
        }
        do {
            return try DemoCatalog(data: data)
        } catch {
            fatalError("DemoCatalog.json is unreadable: \(error)")
        }
    }()

    let providers: [TrackSource: Provider]
    let countries: [Country]
    let artists: [Artist]
    /// Catalog tracks, in catalog order. Never includes imported local files.
    let tracks: [Track]
    let albums: [Album]
    let playlists: [EditorialPlaylist]
    let genres: [Genre]
    let trendingSearches: [TrendingSearch]
    let defaultRecentSearches: [String]
    let defaultSaved: [String]
    let defaultRecent: [DefaultRecent]
    let storyIds: [String]

    private let trackIndex: [String: Track]
    private let artistIndex: [String: Artist]
    private let artistOrder: [String: Int]
    private let albumIndex: [String: Album]
    private let playlistIndex: [String: EditorialPlaylist]

    init(data: Data) throws {
        let file = try JSONDecoder().decode(CatalogFile.self, from: data)
        var tracks = file.tracks
        // Attach album ids (the web build derives them the same way).
        var albumOf: [String: String] = [:]
        for album in file.albums {
            for id in album.trackIds { albumOf[id] = album.id }
        }
        for i in tracks.indices { tracks[i].albumId = albumOf[tracks[i].id] }

        self.providers = Dictionary(uniqueKeysWithValues: file.providers.map { ($0.id, $0) })
        self.countries = file.countries
        self.artists = file.artists
        self.tracks = tracks
        self.albums = file.albums
        self.playlists = file.playlists
        self.genres = file.genres
        self.trendingSearches = file.trendingSearches
        self.defaultRecentSearches = file.defaultRecentSearches
        self.defaultSaved = file.defaultSaved
        self.defaultRecent = file.defaultRecent
        self.storyIds = file.stories
        self.trackIndex = Dictionary(uniqueKeysWithValues: tracks.map { ($0.id, $0) })
        self.artistIndex = Dictionary(uniqueKeysWithValues: file.artists.map { ($0.id, $0) })
        self.artistOrder = Dictionary(uniqueKeysWithValues: file.artists.enumerated().map { ($1.id, $0) })
        self.albumIndex = Dictionary(uniqueKeysWithValues: file.albums.map { ($0.id, $0) })
        self.playlistIndex = Dictionary(uniqueKeysWithValues: file.playlists.map { ($0.id, $0) })
    }

    // MARK: Lookups

    func track(_ id: String) -> Track? { trackIndex[id] }
    func artist(_ id: String) -> Artist? { artistIndex[id] }
    func album(_ id: String) -> Album? { albumIndex[id] }
    func playlist(_ id: String) -> EditorialPlaylist? { playlistIndex[id] }
    func provider(_ source: TrackSource) -> Provider {
        source == .local ? .localDevice : (providers[source] ?? Provider(id: source, name: "Demo", blurb: "Fictional source"))
    }
    func countryName(_ code: String) -> String { countries.first { $0.code == code }?.name ?? code }

    func artistName(for track: Track) -> String {
        if let local = track.local { return local.artistName ?? "On this device" }
        return artist(track.artistId)?.name ?? "Unknown artist"
    }

    func tracks(by artistId: String) -> [Track] {
        tracks.filter { $0.artistId == artistId }.sorted { $0.plays > $1.plays }
    }

    func albums(by artistId: String) -> [Album] {
        albums.filter { $0.artistId == artistId }
    }

    var editorialPlaylists: [EditorialPlaylist] { playlists.filter(\.editorial) }
    var personalPlaylistsSeed: [EditorialPlaylist] { playlists.filter { !$0.editorial } }

    // MARK: Artwork

    /// Each artist owns a palette, by position in the roster (the "local" artist sat at index 23).
    func palette(forArtist id: String) -> ArtPalette {
        let all = ArtPalette.allCases
        let index = id == "local" ? 23 : (artistOrder[id] ?? 0)
        return all[index % all.count]
    }

    func art(for track: Track) -> ArtSpec {
        let key = track.albumId.flatMap { album($0)?.seed } ?? track.seed
        return ArtSpec(key: key, palette: palette(forArtist: track.isLocal ? "local" : track.artistId))
    }

    func art(for album: Album) -> ArtSpec { ArtSpec(key: album.seed, palette: palette(forArtist: album.artistId)) }
    func art(for artist: Artist) -> ArtSpec { ArtSpec(key: artist.seed, palette: palette(forArtist: artist.id)) }
    func art(forPlaylistSeed seed: String) -> ArtSpec { ArtSpec(key: seed) }
    func art(for genre: Genre) -> ArtSpec { ArtSpec(key: "genre-\(genre.id)", palette: genre.palette, style: genre.style) }

    // MARK: Charts

    /// Ranked chart for a region and window. Movement compares against a "previous"
    /// ordering derived from the same seeded scoring.
    func chart(country: String, window: ChartWindow, limit: Int = 20) -> [ChartEntry] {
        let region: String? = country == "GLOBAL" ? nil : country
        func ordering(_ key: String) -> [Track] {
            let scored = tracks.enumerated().map { index, track -> (Track, Double, Int) in
                var rng = SeededRandom("\(track.id)|\(key)")
                let noise = rng.next()
                let home = (region != nil && artist(track.artistId)?.country == region) ? 0.42 : 0
                let fresh = track.daysAgo < 14 ? 0.12 : 0
                let score = (log10(Double(track.plays) + 1) / 7.2) * 0.5 + noise * 0.38 + home + fresh
                return (track, score, index)
            }
            return scored.sorted { a, b in a.1 != b.1 ? a.1 > b.1 : a.2 < b.2 }.map(\.0)
        }
        let now = ordering("\(country)|\(window.rawValue)|now")
        let previousOrder = ordering("\(country)|\(window.rawValue)|prev")
        let previousIndex = Dictionary(uniqueKeysWithValues: previousOrder.enumerated().map { ($1.id, $0) })

        return now.prefix(limit).enumerated().map { index, track in
            let was = previousIndex[track.id] ?? -1
            let rank = index + 1
            let isNewEntry = (track.daysAgo <= window.days && index > 2) || was < 0 || was >= limit + 6
            let previous = isNewEntry ? nil : was + 1
            return ChartEntry(track: track, rank: rank, previous: previous, delta: previous.map { $0 - rank } ?? 0)
        }
    }

    /// Biggest climbers in the weekly chart.
    func movers(country: String, limit: Int = 8) -> [ChartEntry] {
        stableSorted(chart(country: country, window: .week, limit: 30).filter { $0.previous != nil && $0.delta > 0 }) { $0.delta > $1.delta }
            .prefix(limit).map { $0 }
    }

    /// Fastest-growing artists under one million monthly listeners.
    func emergingArtists(limit: Int = 8) -> [Artist] {
        Array(stableSorted(artists.filter { $0.listeners < 900_000 }) { $0.growth > $1.growth }.prefix(limit))
    }

    func risingArtists(limit: Int = 8) -> [Artist] {
        Array(stableSorted(artists) { $0.growth > $1.growth }.prefix(limit))
    }

    func newReleases(limit: Int = 12) -> [Track] {
        Array(stableSorted(tracks.filter(\.isNew)) { $0.daysAgo < $1.daysAgo }.prefix(limit))
    }

    var discoveries: [Track] { tracks.filter(\.discovery) }
    var stories: [Track] { storyIds.compactMap(track) }

    func related(to track: Track, limit: Int = 6) -> [Track] {
        let candidates = tracks.filter { $0.id != track.id && ($0.genre == track.genre || $0.artistId == track.artistId) }
        return Array(stableSorted(candidates) { a, b in
            let sameA = a.artistId == track.artistId, sameB = b.artistId == track.artistId
            if sameA != sameB { return sameA }
            return a.plays > b.plays
        }.prefix(limit))
    }

    // MARK: Search

    struct SearchResults: Sendable {
        var tracks: [Track] = []
        var artists: [Artist] = []
        var albums: [Album] = []
        var playlists: [EditorialPlaylist] = []
        var total: Int { tracks.count + artists.count + albums.count + playlists.count }
    }

    /// Local demo search over the fictional catalog. Prefix matches rank first.
    func search(_ query: String) -> SearchResults {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return SearchResults() }
        func matches(_ fields: [String]) -> Bool { fields.contains { $0.lowercased().contains(q) } }
        func prefixFirst<T>(_ items: [T], _ key: (T) -> String) -> [T] {
            stableSorted(items) { key($0).lowercased().hasPrefix(q) && !key($1).lowercased().hasPrefix(q) }
        }
        return SearchResults(
            tracks: prefixFirst(tracks.filter { matches([$0.title, artistName(for: $0), $0.genre]) }, \.title),
            artists: prefixFirst(artists.filter { matches([$0.name] + $0.genres) }, \.name),
            albums: prefixFirst(albums.filter { matches([$0.title, artist($0.artistId)?.name ?? ""]) }, \.title),
            playlists: prefixFirst(editorialPlaylists.filter { matches([$0.title, $0.blurb]) }, \.title)
        )
    }

    // MARK: Signals

    /// Fourteen points of listener growth for an artist sparkline.
    func spark(artistId: String, growth: Int, points: Int = 14) -> [Double] {
        var rng = SeededRandom(artistId)
        var value = 30 + rng.next() * 10
        var out: [Double] = []
        out.reserveCapacity(points)
        for _ in 0..<points {
            let trend = (Double(growth) / 100) * (2 + rng.next() * 2.2)
            let wobble = (rng.next() - 0.45) * 4
            value += trend + wobble
            out.append(max(4, value))
        }
        return out
    }

    /// Seeded waveform for demo tracks (no audio exists for them). Values in 0.12...1.
    static func waveform(trackId: String, bars: Int) -> [Double] {
        let raw = rawWaveform(trackId: trackId)
        return bucket(raw, bars: bars)
    }

    static func rawWaveform(trackId: String) -> [Double] {
        var rng = SeededRandom("wave|\(trackId)")
        var level = 0.5
        var raw: [Double] = []
        raw.reserveCapacity(256)
        for i in 0..<256 {
            level += (rng.next() - 0.5) * 0.55
            level = max(0.1, min(1, level))
            let t = Double(i) / 255
            let envelope = min(1, 0.35 + t * 5) * min(1, 0.4 + (1 - t) * 4)
            let accent = rng.next() > 0.86 ? 1 : 0.78 + rng.next() * 0.22
            raw.append(max(0.12, min(1, level * envelope * accent)))
        }
        return raw
    }

    /// Down-samples peaks into `bars` buckets, keeping each bucket's maximum.
    static func bucket(_ raw: [Double], bars: Int) -> [Double] {
        guard bars > 0, !raw.isEmpty else { return [] }
        let n = raw.count
        return (0..<bars).map { b in
            let start = Int((Double(b) / Double(bars) * Double(n)).rounded(.down))
            let end = max(start + 1, Int((Double(b + 1) / Double(bars) * Double(n)).rounded(.down)))
            var peak = 0.0
            for i in start..<min(end, n) { peak = max(peak, raw[i]) }
            return peak
        }
    }
}

/// Stable sort (Swift's `sorted` is not guaranteed stable; the web build's is).
func stableSorted<T>(_ items: [T], by areInIncreasingOrder: (T, T) -> Bool) -> [T] {
    items.enumerated().sorted { a, b in
        if areInIncreasingOrder(a.element, b.element) { return true }
        if areInIncreasingOrder(b.element, a.element) { return false }
        return a.offset < b.offset
    }.map(\.element)
}
