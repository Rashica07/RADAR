import Foundation

/// The RADAR API's saved-tracks endpoints (`/v1/library/*`), authenticated with a Neon Auth JWT.
/// The server takes the user from the verified token; the client can never name another user.
struct LibraryAPI: Sendable {
    struct SavedTrack: Decodable, Equatable, Sendable {
        let trackId: String
        let savedAt: Date
    }

    enum APIError: Error, Equatable {
        case unauthorized
        case invalidTrackID
        case badStatus(Int)
        case badResponse
    }

    private let config: BackendConfig
    private let auth: NeonAuthClient
    private let session: URLSession

    init(config: BackendConfig, auth: NeonAuthClient, session: URLSession = .shared) {
        self.config = config
        self.auth = auth
        self.session = session
    }

    func savedTracks() async throws -> [SavedTrack] {
        struct Response: Decodable { let tracks: [SavedTrack] }
        let data = try await request("v1/library/tracks", method: "GET")
        return try Self.decoder.decode(Response.self, from: data).tracks
    }

    func save(trackID: String) async throws {
        _ = try await request("v1/library/tracks/\(try Self.validated(trackID))", method: "PUT")
    }

    func remove(trackID: String) async throws {
        _ = try await request("v1/library/tracks/\(try Self.validated(trackID))", method: "DELETE")
    }

    // MARK: Internals

    /// Mirrors the server's rule (`^[a-z0-9][a-z0-9-]{0,79}$`) so a bad id never reaches the network.
    static func validated(_ trackID: String) throws -> String {
        guard trackID.range(of: "^[a-z0-9][a-z0-9-]{0,79}$", options: .regularExpression) != nil else {
            throw APIError.invalidTrackID
        }
        return trackID
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let raw = try decoder.singleValueContainer().decode(String.self)
            if let date = withFraction.date(from: raw) ?? ISO8601DateFormatter().date(from: raw) { return date }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "bad date \(raw)"))
        }
        return decoder
    }()

    private func request(_ path: String, method: String) async throws -> Data {
        var request = URLRequest(url: config.apiURL.appendingPathComponent(path))
        request.httpMethod = method
        request.timeoutInterval = 15
        request.setValue("Bearer \(try await auth.accessToken())", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse }
        switch http.statusCode {
        case 200: return data
        case 401: throw APIError.unauthorized
        case 400: throw APIError.invalidTrackID
        default: throw APIError.badStatus(http.statusCode)
        }
    }
}
