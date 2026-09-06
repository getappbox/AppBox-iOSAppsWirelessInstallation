import Foundation
import SwiftyDropbox

/// Headless Dropbox login for the CLI: the paste-code Authorization-Code-with-PKCE flow.
public final class DropboxCLIAuth {

    /// An in-flight authorization.
    public struct AuthorizationRequest {
        public let authorizeURL: URL
        let verifier: String
    }

    private let appKey: String
    private let scopes: [String]
    private let httpClient: HTTPClient
    private let secureStorage: SecureStorageAccess

    /// `secureStorage` defaults to a CLI-safe Keychain store — SwiftyDropbox's default impl `fatalError`s in a non-`.app` (command-line) process.
    public init(appKey: String, scopes: [String] = DropboxPKCEAuth.defaultScopes,
                httpClient: HTTPClient = URLSessionHTTPClient(),
                secureStorage: SecureStorageAccess = CLISecureStorageAccess(service: "com.developerinsider.AppBox.dropbox.authv2")) {
        self.appKey = appKey
        self.scopes = scopes
        self.httpClient = httpClient
        self.secureStorage = secureStorage
    }

    /// True if a Dropbox token is already stored (no login needed).
    public var isAuthorized: Bool {
        DropboxOAuthManager(appKey: appKey, secureStorageAccess: secureStorage)
            .getFirstAccessToken() != nil
    }

    /// Begin a login: generate a PKCE pair and the authorize URL (no `redirect_uri`, so Dropbox shows the code).
    public func beginAuthorization() -> AuthorizationRequest {
        let pkce = DropboxPKCEAuth.generatePKCE()
        let url = DropboxPKCEAuth.authorizeURL(appKey: appKey, codeChallenge: pkce.challenge, scopes: scopes)
        return AuthorizationRequest(authorizeURL: url, verifier: pkce.verifier)
    }

    /// Exchange the pasted `code` for tokens and store them.
    public func completeLogin(_ request: AuthorizationRequest, code: String) async throws {
        let token = try await DropboxPKCEAuth.exchangeCode(code, appKey: appKey,
                                                           codeVerifier: request.verifier,
                                                           httpClient: httpClient)
        let expiration = token.expiresIn.map { Date().timeIntervalSince1970 + $0 }
        let dbToken = DropboxAccessToken(accessToken: token.accessToken,
                                         uid: token.uid.isEmpty ? "dropbox" : token.uid,
                                         refreshToken: token.refreshToken,
                                         tokenExpirationTimestamp: expiration)
        let oauthManager = DropboxOAuthManager(appKey: appKey, secureStorageAccess: secureStorage)
        guard oauthManager.storeAccessToken(dbToken) else {
            throw StorageError.authenticationFailed("Could not store the Dropbox token in the keychain.")
        }
    }

    public func signOut() {
        _ = DropboxOAuthManager(appKey: appKey, secureStorageAccess: secureStorage)
            .clearStoredAccessTokens()
    }
}
