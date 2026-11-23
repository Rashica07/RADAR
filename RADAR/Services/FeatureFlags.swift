import Foundation
import Observation
import OSLog

/// Features that ship inside the app but stay hidden until they're switched on remotely.
enum FeatureFlag: String, CaseIterable, Codable, Sendable {
    /// Shows the "Glitch" alternate app icon in Settings.
    case glitchAppIcon = "glitch_app_icon"

    /// Every flag fails closed: off until a source says otherwise.
    var defaultValue: Bool { false }

    var title: String {
        switch self {
        case .glitchAppIcon: "Glitch app icon"
        }
    }
}

/// Where remote flag values come from.
protocol FlagProvider: Sendable {
    func fetch() async throws -> [String: Bool]
}

/// Reads flags from a Supabase table through its REST API (`feature_flags`: key, enabled).
///
/// Only the project URL and the **publishable (anon) key** are needed. Both are meant to
/// be public; access is limited by a read-only row-level-security policy (see
/// docs/feature-flags.md). They come from Info.plist (`RADARFlagsURL`, `RADARFlagsAnonKey`)
/// so nothing is hard-coded, and the provider is `nil` until they are set.
struct SupabaseFlagProvider: FlagProvider {
    let baseURL: URL
    let anonKey: String
    var table = "feature_flags"

    struct Row: Decodable {
        let key: String
        let enabled: Bool
    }

    enum FlagError: Error { case badStatus(Int), badResponse }

    func fetch() async throws -> [String: Bool] {
        var components = URLComponents(url: baseURL.appendingPathComponent("rest/v1/\(table)"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "select", value: "key,enabled")]
        guard let url = components?.url else { throw FlagError.badResponse }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 8)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        // Legacy anon keys are JWTs and go in Authorization too; newer publishable keys are
        // not JWTs and must only be sent as `apikey`.
        if anonKey.hasPrefix("eyJ") {
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw FlagError.badResponse }
        guard http.statusCode == 200 else { throw FlagError.badStatus(http.statusCode) }
        let rows = try JSONDecoder().decode([Row].self, from: data)
        return Dictionary(rows.map { ($0.key, $0.enabled) }, uniquingKeysWith: { _, last in last })
    }

    /// A provider from Info.plist, or nil when remote flags aren't configured.
    static func fromBundle(_ bundle: Bundle = .main) -> SupabaseFlagProvider? {
        guard let urlString = bundle.object(forInfoDictionaryKey: "RADARFlagsURL") as? String,
              let key = bundle.object(forInfoDictionaryKey: "RADARFlagsAnonKey") as? String,
              !key.isEmpty,
              let url = URL(string: urlString),
              url.scheme == "https", url.host != nil else { return nil }
        return SupabaseFlagProvider(baseURL: url, anonKey: key)
    }
}

/// Resolves feature flags: a local override wins, then the last remote value, then the
/// flag's default (off). The last remote answer is cached so flags survive being offline.
@MainActor
@Observable
final class FeatureFlags {
    private struct Snapshot: Codable {
        var remote: [String: Bool] = [:]
        var overrides: [String: Bool] = [:]
        var fetchedAt: Date?
    }

    private static let key = "flags"
    private static let minimumRefreshInterval: TimeInterval = 300

    private let provider: FlagProvider?
    private let persistence: PersistenceController
    private let log = Logger(subsystem: "app.radar", category: "flags")

    private(set) var remote: [String: Bool]
    private(set) var overrides: [String: Bool]
    private(set) var lastRefresh: Date?
    private(set) var lastError: String?

    /// False until a project URL and key are provided in Info.plist.
    var isRemoteConfigured: Bool { provider != nil }

    init(provider: FlagProvider? = SupabaseFlagProvider.fromBundle(), persistence: PersistenceController = .shared) {
        self.provider = provider
        self.persistence = persistence
        let snapshot = persistence.load(Snapshot.self, key: Self.key) ?? Snapshot()
        remote = snapshot.remote
        overrides = snapshot.overrides
        lastRefresh = snapshot.fetchedAt
    }

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        overrides[flag.rawValue] ?? remote[flag.rawValue] ?? flag.defaultValue
    }

    /// What the server last said, ignoring overrides. Nil when never fetched or unset.
    func remoteValue(_ flag: FeatureFlag) -> Bool? { remote[flag.rawValue] }

    func override(_ flag: FeatureFlag) -> Bool? { overrides[flag.rawValue] }

    /// Local override for design review and testing. Pass nil to clear it.
    func setOverride(_ flag: FeatureFlag, _ value: Bool?) {
        overrides[flag.rawValue] = value
        save()
    }

    /// Fetches flags. Throttled to once per five minutes unless `force` is set.
    /// Failures keep the cached values — a flag never flips because of a bad network.
    func refresh(force: Bool = false) async {
        guard let provider else { return }
        if !force, let last = lastRefresh, Date().timeIntervalSince(last) < Self.minimumRefreshInterval { return }
        do {
            let values = try await provider.fetch()
            remote = values
            lastRefresh = .now
            lastError = nil
            save()
        } catch {
            lastError = error.localizedDescription
            log.error("Flag refresh failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func save() {
        persistence.save(Snapshot(remote: remote, overrides: overrides, fetchedAt: lastRefresh), key: Self.key)
    }
}
