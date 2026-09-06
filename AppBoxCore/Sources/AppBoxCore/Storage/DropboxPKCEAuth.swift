import Foundation
import CryptoKit

/// The OAuth 2.0 Authorization-Code-with-PKCE pieces a headless client (the CLI) needs to log in to Dropbox without an app context: generate the PKCE pair, build the authorization URL, and exchange the returned code for tokens.
public enum DropboxPKCEAuth {

    public static let authorizeEndpoint = URL(string: "https://www.dropbox.com/oauth2/authorize")!
    public static let tokenEndpoint = URL(string: "https://api.dropboxapi.com/oauth2/token")!

    /// Scopes AppBox needs (mirrors the GUI's `ABDropboxLogin`).
    public static let defaultScopes = [
        "account_info.read",
        "files.content.write",
        "files.content.read",
        "sharing.write",
        "sharing.read",
    ]

    // MARK: PKCE

    /// A PKCE verifier/challenge pair (RFC 7636, S256).
    public struct PKCE: Equatable {
        public let verifier: String
        public let challenge: String
    }

    /// Generate a PKCE pair: a high-entropy `code_verifier` and its `S256` `code_challenge`.
    public static func generatePKCE() -> PKCE {
        let verifier = base64URLEncode(randomData(count: 64))
        let challenge = base64URLEncode(Data(SHA256.hash(data: Data(verifier.utf8))))
        return PKCE(verifier: verifier, challenge: challenge)
    }

    /// A random URL-safe value for the OAuth `state` (CSRF protection).
    public static func randomState() -> String {
        base64URLEncode(randomData(count: 32))
    }

    // MARK: Authorize URL

    /// Build the authorization URL the user opens in a browser.
    public static func authorizeURL(appKey: String, redirectURI: String? = nil, codeChallenge: String,
                                    state: String? = nil, scopes: [String] = defaultScopes) -> URL {
        var items = [
            URLQueryItem(name: "client_id", value: appKey),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "token_access_type", value: "offline"),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
        ]
        if let redirectURI { items.append(URLQueryItem(name: "redirect_uri", value: redirectURI)) }
        if let state { items.append(URLQueryItem(name: "state", value: state)) }
        var components = URLComponents(url: authorizeEndpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = items
        return components.url!
    }

    // MARK: Token exchange

    /// The token endpoint's response.
    public struct TokenResponse: Equatable {
        public let accessToken: String
        public let refreshToken: String?
        public let uid: String
        public let expiresIn: TimeInterval?
    }

    /// Exchange the authorization `code` for access/refresh tokens.
    public static func exchangeCode(_ code: String, appKey: String, codeVerifier: String,
                                    redirectURI: String? = nil, httpClient: HTTPClient) async throws -> TokenResponse {
        var form: [String: String] = [
            "code": code,
            "grant_type": "authorization_code",
            "client_id": appKey,
            "code_verifier": codeVerifier,
        ]
        if let redirectURI { form["redirect_uri"] = redirectURI }
        let request = HTTPRequest(
            url: tokenEndpoint, method: .post,
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            body: Data(formURLEncode(form).utf8))
        let response = try await httpClient.send(request)
        guard response.isSuccess else {
            throw StorageError.authenticationFailed("Token exchange failed (HTTP \(response.statusCode)): \(String(decoding: response.data, as: UTF8.self))")
        }
        return try parseTokenResponse(response.data)
    }

    /// Parse the token endpoint's JSON.
    public static func parseTokenResponse(_ data: Data) throws -> TokenResponse {
        guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            throw StorageError.authenticationFailed("Malformed token response")
        }
        let uid = (json["uid"] as? String) ?? (json["account_id"] as? String) ?? ""
        let refreshToken = json["refresh_token"] as? String
        let expiresIn = (json["expires_in"] as? NSNumber)?.doubleValue
        return TokenResponse(accessToken: accessToken, refreshToken: refreshToken, uid: uid, expiresIn: expiresIn)
    }

    // MARK: Helpers

    static func randomData(count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        if SecRandomCopyBytes(kSecRandomDefault, count, &bytes) != errSecSuccess {
            bytes = (0..<count).map { _ in UInt8.random(in: UInt8.min...UInt8.max) }
        }
        return Data(bytes)
    }

    /// Base64URL without padding (RFC 4648 §5).
    static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func formURLEncode(_ params: [String: String]) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return params.map { key, value in
            let k = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
            let v = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
            return "\(k)=\(v)"
        }.joined(separator: "&")
    }
}
