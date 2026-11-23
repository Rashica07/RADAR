import Foundation

/// Neon Auth (Managed Better Auth) over plain URLSession.
///
/// Flow, as verified against the live service (scripts/verify.mjs):
///   1. `POST {auth}/sign-up/email` or `/sign-in/email` with an `Origin` header → sets a session cookie.
///   2. `GET {auth}/token` WITH that cookie → a short-lived (15 min) EdDSA JWT.
///      (A bearer *session* token is rejected with 401; the cookie is required.)
///   3. The JWT goes to the RADAR API as `Authorization: Bearer …`.
///
/// The session cookie lives in this client's own cookie storage, not the shared one.
actor NeonAuthClient {
    struct User: Decodable, Equatable, Sendable {
        let id: String
        let email: String?
        let name: String?
    }

    enum AuthError: Error, Equatable {
        case invalidCredentials
        case rejected(status: Int, code: String?)
        case notSignedIn
        case badResponse
    }

    private let config: BackendConfig
    private let session: URLSession
    private var cachedToken: (value: String, expires: Date)?

    init(config: BackendConfig) {
        self.config = config
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = HTTPCookieStorage()   // private to this client
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        configuration.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: configuration)
    }

    // MARK: Sign up / in / out

    @discardableResult
    func signUp(email: String, password: String, name: String) async throws -> User {
        try await authenticate(path: "sign-up/email", body: ["email": email, "password": password, "name": name])
    }

    @discardableResult
    func signIn(email: String, password: String) async throws -> User {
        try await authenticate(path: "sign-in/email", body: ["email": email, "password": password])
    }

    func signOut() async {
        cachedToken = nil
        _ = try? await send(path: "sign-out", method: "POST", body: [:])
        if let cookies = session.configuration.httpCookieStorage?.cookies {
            for cookie in cookies { session.configuration.httpCookieStorage?.deleteCookie(cookie) }
        }
    }

    // MARK: Token for the RADAR API

    /// A valid JWT for the RADAR API, refreshed from the session cookie when it is about to expire.
    func accessToken() async throws -> String {
        if let cachedToken, cachedToken.expires.timeIntervalSinceNow > 60 { return cachedToken.value }
        let (data, status) = try await send(path: "token", method: "GET", body: nil)
        guard status == 200 else { throw status == 401 ? AuthError.notSignedIn : AuthError.rejected(status: status, code: Self.errorCode(data)) }
        struct TokenResponse: Decodable { let token: String }
        guard let token = (try? JSONDecoder().decode(TokenResponse.self, from: data))?.token else { throw AuthError.badResponse }
        cachedToken = (token, Self.expiry(of: token) ?? Date().addingTimeInterval(600))
        return token
    }

    // MARK: Internals

    private func authenticate(path: String, body: [String: String]) async throws -> User {
        let (data, status) = try await send(path: path, method: "POST", body: body)
        switch status {
        case 200:
            struct Envelope: Decodable { let user: User? }
            guard let user = (try? JSONDecoder().decode(Envelope.self, from: data))?.user else { throw AuthError.badResponse }
            cachedToken = nil
            return user
        case 401: throw AuthError.invalidCredentials
        default: throw AuthError.rejected(status: status, code: Self.errorCode(data))
        }
    }

    private func send(path: String, method: String, body: [String: String]?) async throws -> (Data, Int) {
        var request = URLRequest(url: config.authURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue(config.authOrigin, forHTTPHeaderField: "Origin")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.badResponse }
        return (data, http.statusCode)
    }

    private static func errorCode(_ data: Data) -> String? {
        (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["code"] as? String
    }

    /// Reads `exp` from a JWT payload. Used only to schedule a refresh; the server does the verifying.
    private static func expiry(of jwt: String) -> Date? {
        let parts = jwt.split(separator: ".")
        guard parts.count == 3 else { return nil }
        var base64 = String(parts[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }
        guard let data = Data(base64Encoded: base64),
              let claims = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = claims["exp"] as? TimeInterval else { return nil }
        return Date(timeIntervalSince1970: exp)
    }
}
