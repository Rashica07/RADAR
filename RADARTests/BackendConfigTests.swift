import XCTest
@testable import RADAR

final class BackendConfigTests: XCTestCase {
    func testUnsetValuesDisableTheBackend() {
        XCTAssertNil(BackendConfig(apiURL: nil, authURL: nil, authOrigin: nil))
        XCTAssertNil(BackendConfig(apiURL: "", authURL: "", authOrigin: ""))
        XCTAssertNil(BackendConfig(apiURL: "$(RADAR_API_URL)", authURL: "$(RADAR_AUTH_URL)", authOrigin: "$(RADAR_AUTH_ORIGIN)"))
    }

    func testHTTPIsRejected() {
        XCTAssertNil(BackendConfig(apiURL: "http://example.com", authURL: "https://auth.example.com", authOrigin: "https://app.example.com"))
    }

    func testValidConfig() {
        let config = BackendConfig(apiURL: "https://api.example.com", authURL: "https://auth.example.com/neondb/auth", authOrigin: "https://app.example.com")
        XCTAssertEqual(config?.authOrigin, "https://app.example.com")
    }

    func testTrackIDValidationMirrorsTheServer() throws {
        XCTAssertEqual(try LibraryAPI.validated("gold-hour"), "gold-hour")
        XCTAssertThrowsError(try LibraryAPI.validated("../etc"))
        XCTAssertThrowsError(try LibraryAPI.validated("Upper"))
        XCTAssertThrowsError(try LibraryAPI.validated("-leading"))
        XCTAssertThrowsError(try LibraryAPI.validated(String(repeating: "a", count: 81)))
    }
}
