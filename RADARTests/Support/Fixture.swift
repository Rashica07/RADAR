import Foundation

/// Loads JSON fixtures generated from the Phase 01 JavaScript (see tools/).
enum Fixture {
    private final class BundleToken {}

    enum FixtureError: Error { case missing(String) }

    static func data(_ name: String) throws -> Data {
        let bundle = Bundle(for: BundleToken.self)
        for subdirectory in [nil, "Fixtures"] as [String?] {
            if let url = bundle.url(forResource: name, withExtension: "json", subdirectory: subdirectory) {
                return try Data(contentsOf: url)
            }
        }
        throw FixtureError.missing(name)
    }
}
