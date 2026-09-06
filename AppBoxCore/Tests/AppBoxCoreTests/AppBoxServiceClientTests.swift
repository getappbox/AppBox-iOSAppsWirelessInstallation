import XCTest
@testable import AppBoxCore

final class AppBoxServiceClientTests: XCTestCase {

    private let configuration = AppBoxServiceConfiguration(
        baseURL: URL(string: "https://api.test.local/api/v1")!,
        clientToken: "test-token")

    private func makeClient(responder: @escaping (HTTPRequest) throws -> HTTPResponse,
                            token: String? = "dropbox-token") -> (AppBoxServiceClient, StubHTTPClient) {
        let http = StubHTTPClient(responder: responder)
        let client = AppBoxServiceClient(configuration: configuration, httpClient: http,
                                         tokenProvider: StubTokenProvider(token: token))
        return (client, http)
    }

    private func json(_ string: String, status: Int = 200) -> HTTPResponse {
        HTTPResponse(statusCode: status, data: Data(string.utf8))
    }

    // MARK: - fetchDropboxAppKey

    func testFetchDropboxAppKey_sendsClientTokenAndDecodesKey() async throws {
        let (client, http) = makeClient(responder: { _ in self.json(#"{"dropboxAppKey":"key123"}"#) })
        let key = try await client.fetchDropboxAppKey()

        XCTAssertEqual(key, "key123")
        let request = try XCTUnwrap(http.sentRequests.first)
        XCTAssertEqual(request.url.absoluteString, "https://api.test.local/api/v1/config")
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.headers["X-AppBox-Client-Token"], "test-token")
        XCTAssertNil(request.headers["Authorization"])
    }

    func testFetchDropboxAppKey_401ThrowsNotAuthenticated() async {
        let (client, _) = makeClient(responder: { _ in
            self.json(#"{"error":{"code":"invalid_client_token","message":"nope"}}"#, status: 401)
        })
        do {
            _ = try await client.fetchDropboxAppKey()
            XCTFail("expected notAuthenticated")
        } catch AppBoxServiceError.notAuthenticated {
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    // MARK: - shortLink (ShortLinkService)

    private var shortLinkRequest: ShortLinkRequest {
        ShortLinkRequest(name: "App", version: "1.0", build: "7", identifier: "com.x.y",
                         longURL: URL(string: "https://www.dropbox.com/scl/fi/x/appinfo.json?rlkey=1")!)
    }

    func testShortLink_sendsBothAuthHeadersAndFieldNames() async throws {
        let (client, http) = makeClient(responder: { _ in self.json(#"{"shortURL":"https://appbox.me/x1"}"#) })
        let url = await client.shortLink(for: shortLinkRequest)

        XCTAssertEqual(url?.absoluteString, "https://appbox.me/x1")
        let request = try XCTUnwrap(http.sentRequests.first)
        XCTAssertEqual(request.url.absoluteString, "https://api.test.local/api/v1/shorten")
        XCTAssertEqual(request.headers["X-AppBox-Client-Token"], "test-token")
        XCTAssertEqual(request.headers["Authorization"], "Bearer dropbox-token")
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
        let body = try JSONSerialization.jsonObject(with: XCTUnwrap(request.body)) as? [String: Any]
        XCTAssertEqual(body?["url"] as? String, "https://www.dropbox.com/scl/fi/x/appinfo.json?rlkey=1")
        XCTAssertEqual(body?["identifier"] as? String, "com.x.y")
        XCTAssertEqual(Set((body ?? [:]).keys), ["url", "name", "version", "build", "identifier"])
    }

    func testShortLink_failuresFallBackToNil() async {
        let (failing, _) = makeClient(responder: { _ in self.json(#"{"error":{"code":"shortener_unavailable","message":"x"}}"#, status: 502) })
        let failed = await failing.shortLink(for: shortLinkRequest)
        XCTAssertNil(failed)

        struct Boom: Error {}
        let (throwing, _) = makeClient(responder: { _ in throw Boom() })
        let thrown = await throwing.shortLink(for: shortLinkRequest)
        XCTAssertNil(thrown)

        let (loggedOut, http) = makeClient(responder: { _ in self.json("{}") }, token: nil)
        let skipped = await loggedOut.shortLink(for: shortLinkRequest)
        XCTAssertNil(skipped)
        XCTAssertTrue(http.sentRequests.isEmpty)
    }

    // MARK: - sendBuildEmail

    private var email: BuildEmailRequest {
        BuildEmailRequest(name: "App", version: "1.0", build: "7", to: ["a@b.com", "c@d.io"],
                          installURL: URL(string: "https://appbox.me/x1")!, personalMessage: "Hi QA")
    }

    func testSendBuildEmail_sendsPayloadAndSucceeds() async throws {
        let (client, http) = makeClient(responder: { _ in self.json(#"{"id":"<msg>"}"#) })
        try await client.sendBuildEmail(email)

        let request = try XCTUnwrap(http.sentRequests.first)
        XCTAssertEqual(request.url.absoluteString, "https://api.test.local/api/v1/mail/send")
        XCTAssertEqual(request.headers["Authorization"], "Bearer dropbox-token")
        let body = try JSONSerialization.jsonObject(with: XCTUnwrap(request.body)) as? [String: Any]
        XCTAssertEqual(body?["to"] as? [String], ["a@b.com", "c@d.io"])
        XCTAssertEqual(body?["installURL"] as? String, "https://appbox.me/x1")
        XCTAssertEqual(body?["personalMessage"] as? String, "Hi QA")
    }

    func testSendBuildEmail_loggedOutThrowsNotAuthenticated() async {
        let (client, http) = makeClient(responder: { _ in self.json("{}") }, token: nil)
        do {
            try await client.sendBuildEmail(email)
            XCTFail("expected notAuthenticated")
        } catch AppBoxServiceError.notAuthenticated {
            XCTAssertTrue(http.sentRequests.isEmpty)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    // MARK: - fetchLatestVersion

    func testFetchLatestVersion_clientTokenOnlyAndDecodes() async throws {
        let (client, http) = makeClient(responder: { _ in
            self.json(#"{"version":"3.8.0","downloadURL":"https://github.com/x/releases/tag/3.8.0","homebrewVersion":"3.7.9"}"#)
        })
        let latest = try await client.fetchLatestVersion()

        XCTAssertEqual(latest.version, "3.8.0")
        XCTAssertEqual(latest.downloadURL?.absoluteString, "https://github.com/x/releases/tag/3.8.0")
        XCTAssertEqual(latest.homebrewVersion, "3.7.9")
        let request = try XCTUnwrap(http.sentRequests.first)
        XCTAssertEqual(request.url.absoluteString, "https://api.test.local/api/v1/latest-version")
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.headers["X-AppBox-Client-Token"], "test-token")
        XCTAssertNil(request.headers["Authorization"])
    }

    func testFetchLatestVersion_serverErrorThrows() async {
        let (client, _) = makeClient(responder: { _ in
            self.json(#"{"error":{"code":"update_check_unavailable","message":"down"}}"#, status: 502)
        })
        do {
            _ = try await client.fetchLatestVersion()
            XCTFail("expected invalidResponse")
        } catch AppBoxServiceError.invalidResponse(let status, _) {
            XCTAssertEqual(status, 502)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    // MARK: - sendNotification

    func testSendNotification_sendsServiceWebhookAndText() async throws {
        let (client, http) = makeClient(responder: { _ in self.json("{}") })
        try await client.sendNotification(service: .slack,
                                          webhookURL: "https://hooks.slack.com/services/x", text: "hello")

        let request = try XCTUnwrap(http.sentRequests.first)
        XCTAssertEqual(request.url.absoluteString, "https://api.test.local/api/v1/notify")
        XCTAssertEqual(request.headers["Authorization"], "Bearer dropbox-token")
        let body = try JSONSerialization.jsonObject(with: XCTUnwrap(request.body)) as? [String: Any]
        XCTAssertEqual(body?["service"] as? String, "slack")
        XCTAssertEqual(body?["webhookURL"] as? String, "https://hooks.slack.com/services/x")
        XCTAssertEqual(body?["text"] as? String, "hello")
    }

    func testSendNotification_loggedOutThrowsWithoutRequest() async {
        let (client, http) = makeClient(responder: { _ in self.json("{}") }, token: nil)
        do {
            try await client.sendNotification(service: .teams, webhookURL: "https://acme.webhook.office.com/x", text: "hi")
            XCTFail("expected notAuthenticated")
        } catch AppBoxServiceError.notAuthenticated {
            XCTAssertTrue(http.sentRequests.isEmpty)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testSendNotification_serverFailureThrows() async {
        let (client, _) = makeClient(responder: { _ in
            self.json(#"{"error":{"code":"notify_failed","message":"down"}}"#, status: 502)
        })
        do {
            try await client.sendNotification(service: .slack, webhookURL: "https://hooks.slack.com/services/x", text: "x")
            XCTFail("expected invalidResponse")
        } catch AppBoxServiceError.invalidResponse(let status, _) {
            XCTAssertEqual(status, 502)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testSendBuildEmail_providerFailureSurfacesStatusAndMessage() async {
        let (client, _) = makeClient(responder: { _ in
            self.json(#"{"error":{"code":"mail_provider_error","message":"Mail provider responded 500."}}"#, status: 502)
        })
        do {
            try await client.sendBuildEmail(email)
            XCTFail("expected invalidResponse")
        } catch let AppBoxServiceError.invalidResponse(status, message) {
            XCTAssertEqual(status, 502)
            XCTAssertEqual(message, "Mail provider responded 500.")
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }
}
