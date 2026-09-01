import Foundation
import os

/// Where the AppBox backend (install-helper's `/api/v1`) lives and how the client identifies itself.
public struct AppBoxServiceConfiguration: Sendable {
    public var baseURL: URL
    /// Static shared secret sent as `X-AppBox-Client-Token`.
    public var clientToken: String

    public init(baseURL: URL, clientToken: String) {
        self.baseURL = baseURL
        self.clientToken = clientToken
    }

    /// The deployed backend (`api.getappbox.com` → install-helper).
    public static func production(clientToken: String) -> AppBoxServiceConfiguration {
        AppBoxServiceConfiguration(baseURL: URL(string: "https://api.getappbox.com/api/v1")!,
                                   clientToken: clientToken)
    }
}

/// Supplies the logged-in user's Dropbox access token (refreshed if near expiry) — the backend verifies it to ensure only real AppBox users can send mail / mint short links.
public protocol DropboxAccessTokenProviding: AnyObject {
    func currentAccessToken() async -> String?
}

/// Production token source: the live SwiftyDropbox session (GUI and CLI both configure it).
public final class DropboxSessionTokenProvider: DropboxAccessTokenProviding {
    public init() {}
    public func currentAccessToken() async -> String? {
        await DropboxSession.currentAccessToken()
    }
}

public enum AppBoxServiceError: Error {
    /// No Dropbox login, or the backend rejected the token (401).
    case notAuthenticated
    /// The backend answered with a non-success status; `message` is its error envelope text.
    case invalidResponse(status: Int, message: String?)
    case network(Error)
}

/// The latest AppBox version, as reported by the backend (`GET /latest-version`).
public struct LatestVersion: Decodable, Sendable {
    public let version: String
    public let downloadURL: URL?
    public let homebrewVersion: String?
}

/// An incoming-webhook target for `POST /notify`.
public enum NotificationService: String, Sendable {
    case slack
    case teams
}

/// The build-notification email, ready to send; the backend wraps `personalMessage` in the HTML shell under "Message from the developer".
public struct BuildEmailRequest: Equatable, Sendable {
    public var name: String
    public var version: String
    public var build: String
    public var to: [String]
    public var installURL: URL
    public var personalMessage: String?

    public init(name: String, version: String, build: String, to: [String],
                installURL: URL, personalMessage: String? = nil) {
        self.name = name
        self.version = version
        self.build = build
        self.to = to
        self.installURL = installURL
        self.personalMessage = personalMessage
    }
}

/// Client for the AppBox backend — replaces the retired ABPrivate SDK's direct Mailgun/YOURLS calls (the provider credentials now live only on the server).
public final class AppBoxServiceClient {

    private static let log = Logger(subsystem: "com.developerinsider.AppBox.core", category: "AppBoxService")

    private let configuration: AppBoxServiceConfiguration
    private let httpClient: HTTPClient
    private let tokenProvider: DropboxAccessTokenProviding

    public init(configuration: AppBoxServiceConfiguration,
                httpClient: HTTPClient,
                tokenProvider: DropboxAccessTokenProviding) {
        self.configuration = configuration
        self.httpClient = httpClient
        self.tokenProvider = tokenProvider
    }

    // MARK: - GET /config

    public func fetchDropboxAppKey() async throws -> String {
        struct ConfigResponse: Decodable { let dropboxAppKey: String }
        let response = try await send(.get, path: "config", body: nil, dropboxToken: nil)
        guard response.isSuccess else { throw error(from: response) }
        return try JSONDecoder().decode(ConfigResponse.self, from: response.data).dropboxAppKey
    }

    // MARK: - GET /latest-version

    /// The latest version (client token only — the update check runs before any Dropbox login).
    public func fetchLatestVersion() async throws -> LatestVersion {
        let response = try await send(.get, path: "latest-version", body: nil, dropboxToken: nil)
        guard response.isSuccess else { throw error(from: response) }
        return try JSONDecoder().decode(LatestVersion.self, from: response.data)
    }

    // MARK: - POST /notify

    /// Relay an upload notification to a Slack/Teams incoming webhook.
    public func sendNotification(service: NotificationService, webhookURL: String, text: String) async throws {
        guard let token = await tokenProvider.currentAccessToken() else {
            throw AppBoxServiceError.notAuthenticated
        }
        struct Payload: Encodable { let service, webhookURL, text: String }
        let payload = Payload(service: service.rawValue, webhookURL: webhookURL, text: text)
        let response = try await send(.post, path: "notify",
                                      body: try JSONEncoder().encode(payload), dropboxToken: token)
        guard response.isSuccess else { throw error(from: response) }
    }

    // MARK: - POST /mail/send

    public func sendBuildEmail(_ request: BuildEmailRequest) async throws {
        guard let token = await tokenProvider.currentAccessToken() else {
            throw AppBoxServiceError.notAuthenticated
        }
        struct Payload: Encodable {
            let name, version, build: String
            let to: [String]
            let installURL: String
            let personalMessage: String?
        }
        let payload = Payload(name: request.name, version: request.version, build: request.build,
                              to: request.to, installURL: request.installURL.absoluteString,
                              personalMessage: request.personalMessage)
        let response = try await send(.post, path: "mail/send",
                                      body: try JSONEncoder().encode(payload), dropboxToken: token)
        guard response.isSuccess else { throw error(from: response) }
    }

    // MARK: - Helpers

    private func send(_ method: HTTPMethod, path: String, body: Data?, dropboxToken: String?) async throws -> HTTPResponse {
        var headers = ["X-AppBox-Client-Token": configuration.clientToken]
        if body != nil { headers["Content-Type"] = "application/json" }
        if let dropboxToken { headers["Authorization"] = "Bearer \(dropboxToken)" }
        let url = configuration.baseURL.appendingPathComponent(path)
        do {
            return try await httpClient.send(HTTPRequest(url: url, method: method, headers: headers, body: body))
        } catch {
            throw AppBoxServiceError.network(error)
        }
    }

    private func error(from response: HTTPResponse) -> AppBoxServiceError {
        struct Envelope: Decodable {
            struct Detail: Decodable { let code: String; let message: String }
            let error: Detail
        }
        let message = (try? JSONDecoder().decode(Envelope.self, from: response.data))?.error.message
        if response.statusCode == 401 { return .notAuthenticated }
        return .invalidResponse(status: response.statusCode, message: message)
    }
}

// MARK: - ShortLinkService

extension AppBoxServiceClient: ShortLinkService {
    /// POST /shorten.
    public func shortLink(for request: ShortLinkRequest) async -> URL? {
        guard let token = await tokenProvider.currentAccessToken() else {
            Self.log.info("Short-link skipped: no Dropbox session.")
            return nil
        }
        struct Payload: Encodable { let url, name, version, build, identifier: String }
        struct ShortenResponse: Decodable { let shortURL: String }
        do {
            let payload = Payload(url: request.longURL.absoluteString, name: request.name,
                                  version: request.version, build: request.build,
                                  identifier: request.identifier)
            let response = try await send(.post, path: "shorten",
                                          body: try JSONEncoder().encode(payload), dropboxToken: token)
            guard response.isSuccess else {
                Self.log.info("Short-link failed (HTTP \(response.statusCode)); using the long URL.")
                return nil
            }
            return URL(string: try JSONDecoder().decode(ShortenResponse.self, from: response.data).shortURL)
        } catch {
            Self.log.info("Short-link failed (\(error.localizedDescription)); using the long URL.")
            return nil
        }
    }
}
