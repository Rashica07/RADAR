import Foundation

// MARK: - Sources & availability

/// Where a track comes from. Every catalog provider in this build is a demo provider,
/// and its name always starts with "Demo" so it can't be mistaken for real provider data.
enum TrackSource: String, Codable, Hashable, Sendable {
    case catalog
    case indie
    case local
}

/// Rights-holder download status. For catalog tracks this is demo metadata.
enum DownloadStatus: String, Codable, Hashable, Sendable {
    case available
    case downloaded
    case streamingOnly = "streaming-only"
    case unavailable
    case local
}

struct Provider: Codable, Hashable, Identifiable, Sendable {
    let id: TrackSource
    let name: String
    let blurb: String

    static let localDevice = Provider(id: .local, name: "On this device", blurb: "Files you imported. Never uploaded")
}

struct Country: Codable, Hashable, Identifiable, Sendable {
    let code: String
    let name: String
    var id: String { code }
    var isGlobal: Bool { code == "GLOBAL" }
}

// MARK: - Catalog entities

struct Artist: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let country: String
    let genres: [String]
    let listeners: Int
    let growth: Int
    let bio: String
    let seed: String
}

struct Track: Codable, Hashable, Identifiable, Sendable {
    let id: String
    var title: String
    var artistId: String
    var genre: String
    /// Seconds.
    var duration: Double
    var daysAgo: Int
    var plays: Int
    var source: TrackSource
    var download: DownloadStatus
    var bpm: Int
    var explicit: Bool
    var discovery: Bool
    var why: String?
    var seed: String
    var albumId: String?
    /// Present only for audio files the user imported.
    var local: LocalFile?

    var isLocal: Bool { source == .local }
    /// Released in the last 14 days.
    var isNew: Bool { daysAgo <= 14 && !isLocal }

    /// Metadata for an imported audio file, stored inside the app sandbox.
    struct LocalFile: Codable, Hashable, Sendable {
        /// File name inside `LocalLibrary.directory`.
        var storedName: String
        var originalName: String
        var artistName: String?
        var albumTitle: String?
        var sizeBytes: Int64
        var addedAt: Date

        var sizeMB: Double { Double(sizeBytes) / 1_048_576 }
    }
}

struct Album: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let artistId: String
    let kind: String
    let year: Int
    let trackIds: [String]
    let seed: String
}

struct EditorialPlaylist: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let curator: String
    let blurb: String
    let editorial: Bool
    let seed: String
    let trackIds: [String]
}

struct Genre: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let blurb: String
    let palette: ArtPalette
    let style: ArtStyle
}

struct TrendingSearch: Codable, Hashable, Sendable {
    let q: String
    let delta: Int?
}

struct DefaultRecent: Codable, Hashable, Sendable {
    let id: String
    let minsAgo: Double
}

/// The on-disk demo catalog (Resources/DemoCatalog.json). Fictional content.
struct CatalogFile: Codable, Sendable {
    let providers: [Provider]
    let countries: [Country]
    let artists: [Artist]
    let tracks: [Track]
    let albums: [Album]
    let playlists: [EditorialPlaylist]
    let genres: [Genre]
    let trendingSearches: [TrendingSearch]
    let defaultRecentSearches: [String]
    let defaultSaved: [String]
    let defaultRecent: [DefaultRecent]
    let stories: [String]
}

// MARK: - Charts

enum ChartWindow: String, CaseIterable, Codable, Hashable, Sendable {
    case day = "24h"
    case week = "7d"
    case month = "30d"

    var label: String { rawValue.uppercased() }
    var days: Int {
        switch self {
        case .day: 1
        case .week: 7
        case .month: 30
        }
    }
}

struct ChartEntry: Hashable, Identifiable, Sendable {
    let track: Track
    let rank: Int
    /// Previous rank, or nil for a new entry.
    let previous: Int?
    /// Places moved since the previous period (positive = up).
    let delta: Int

    var id: String { track.id }
    var isNew: Bool { previous == nil }
    var isClimbing: Bool { delta > 0 || previous == nil }
}

// MARK: - User collections

struct UserPlaylist: Codable, Hashable, Identifiable, Sendable {
    let id: String
    var title: String
    var trackIds: [String]
    var seed: String
    var blurb: String
}

struct RecentPlay: Codable, Hashable, Sendable {
    let id: String
    let at: Date
}
