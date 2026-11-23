import Foundation

/// Where the RADAR backend lives. Every value is a PUBLIC endpoint (no secrets ship in the app):
/// the database URL and the Realtime secret stay inside the Neon Function.
///
/// Values come from Info.plist (`RADARApiURL`, `RADARAuthURL`, `RADARAuthOrigin`), which are filled
/// from xcconfig (`RADAR_API_URL`, `RADAR_AUTH_URL`, `RADAR_AUTH_ORIGIN`). `BackendConfig.current`
/// is `nil` until all three are set, so a build without them simply runs on the demo catalogue.
struct BackendConfig: Equatable, Sendable {
    /// Base URL of the `radar` Neon Function, e.g. https://<branch>-radar.compute.<region>.aws.neon.tech
    let apiURL: URL
    /// Neon Auth base URL (NEON_AUTH_BASE_URL), e.g. https://ep-….neonauth.<region>.aws.neon.tech/neondb/auth
    let authURL: URL
    /// Value sent as the `Origin` header. Neon Auth rejects requests without a trusted origin
    /// (403 MISSING_OR_NULL_ORIGIN); a native app has no browser origin, so it must send one that
    /// is registered with `neon neon-auth domain add <origin>`.
    let authOrigin: String

    init?(apiURL: String?, authURL: String?, authOrigin: String?) {
        func clean(_ value: String?) -> String? {
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            // An unexpanded "$(VAR)" means the xcconfig value was never set.
            return trimmed.isEmpty || trimmed.hasPrefix("$(") ? nil : trimmed
        }
        guard
            let api = clean(apiURL).flatMap(URL.init(string:)), api.scheme == "https",
            let auth = clean(authURL).flatMap(URL.init(string:)), auth.scheme == "https",
            let origin = clean(authOrigin)
        else { return nil }
        self.apiURL = api
        self.authURL = auth
        self.authOrigin = origin
    }

    static let current: BackendConfig? = BackendConfig(
        apiURL: Bundle.main.object(forInfoDictionaryKey: "RADARApiURL") as? String,
        authURL: Bundle.main.object(forInfoDictionaryKey: "RADARAuthURL") as? String,
        authOrigin: Bundle.main.object(forInfoDictionaryKey: "RADARAuthOrigin") as? String
    )
}
