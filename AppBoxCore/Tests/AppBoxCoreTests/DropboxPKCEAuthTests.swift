import XCTest
import CryptoKit
@testable import AppBoxCore

final class DropboxPKCEAuthTests: XCTestCase {

    // MARK: PKCE

    func testGeneratePKCE_challengeIsS256OfVerifier_andURLSafe() {
        let pkce = DropboxPKCEAuth.generatePKCE()

        let expected = DropboxPKCEAuth.base64URLEncode(Data(SHA256.hash(data: Data(pkce.verifier.utf8))))
        XCTAssertEqual(pkce.challenge, expected)

        for s in [pkce.verifier, pkce.challenge] {
            XCTAssertFalse(s.contains("+"))
            XCTAssertFalse(s.contains("/"))
            XCTAssertFalse(s.contains("="))
            XCTAssertFalse(s.isEmpty)
        }
        XCTAssertTrue((43...128).contains(pkce.verifier.count))
    }

    func testGeneratePKCE_isRandomEachTime() {
        XCTAssertNotEqual(DropboxPKCEAuth.generatePKCE().verifier, DropboxPKCEAuth.generatePKCE().verifier)
        XCTAssertNotEqual(DropboxPKCEAuth.randomState(), DropboxPKCEAuth.randomState())
    }

    // MARK: Authorize URL

    func testAuthorizeURL_withRedirect_containsRequiredParams() throws {
        let url = DropboxPKCEAuth.authorizeURL(appKey: "abc123", redirectURI: "http://127.0.0.1:54321",
                                               codeChallenge: "CHAL", state: "STATE")
        let items = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        func value(_ name: String) -> String? { items.first { $0.name == name }?.value }

        XCTAssertEqual(url.host, "www.dropbox.com")
        XCTAssertEqual(url.path, "/oauth2/authorize")
        XCTAssertEqual(value("client_id"), "abc123")
        XCTAssertEqual(value("response_type"), "code")
        XCTAssertEqual(value("code_challenge"), "CHAL")
        XCTAssertEqual(value("code_challenge_method"), "S256")
        XCTAssertEqual(value("token_access_type"), "offline")
        XCTAssertEqual(value("redirect_uri"), "http://127.0.0.1:54321")
        XCTAssertEqual(value("state"), "STATE")
        XCTAssertEqual(value("scope"), DropboxPKCEAuth.defaultScopes.joined(separator: " "))
    }

    /// The CLI's paste-code flow sends no `redirect_uri` (and no `state`).
    func testAuthorizeURL_pasteCode_omitsRedirectAndState() throws {
        let url = DropboxPKCEAuth.authorizeURL(appKey: "abc123", codeChallenge: "CHAL")
        let items = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        func value(_ name: String) -> String? { items.first { $0.name == name }?.value }

        XCTAssertNil(value("redirect_uri"))
        XCTAssertNil(value("state"))
        XCTAssertEqual(value("client_id"), "abc123")
        XCTAssertEqual(value("response_type"), "code")
        XCTAssertEqual(value("code_challenge"), "CHAL")
        XCTAssertEqual(value("token_access_type"), "offline")
    }

    // MARK: Token response parsing

    func testParseTokenResponse_fullAndUidFallback() throws {
        let full = Data(#"{"access_token":"sl.AAA","refresh_token":"rt.BBB","uid":"42","expires_in":14400,"token_type":"bearer"}"#.utf8)
        let token = try DropboxPKCEAuth.parseTokenResponse(full)
        XCTAssertEqual(token.accessToken, "sl.AAA")
        XCTAssertEqual(token.refreshToken, "rt.BBB")
        XCTAssertEqual(token.uid, "42")
        XCTAssertEqual(token.expiresIn, 14400)

        let fallback = Data(#"{"access_token":"x","account_id":"dbid:ZZZ"}"#.utf8)
        let token2 = try DropboxPKCEAuth.parseTokenResponse(fallback)
        XCTAssertEqual(token2.uid, "dbid:ZZZ")
        XCTAssertNil(token2.refreshToken)
        XCTAssertNil(token2.expiresIn)
    }

    func testParseTokenResponse_missingAccessTokenThrows() {
        XCTAssertThrowsError(try DropboxPKCEAuth.parseTokenResponse(Data(#"{"error":"invalid_grant"}"#.utf8)))
    }

    // MARK: Token exchange (over the HTTPClient seam)

    func testExchangeCode_postsCorrectRequestAndParsesToken() async throws {
        let stub = StubHTTPClient { _ in
            HTTPResponse(statusCode: 200,
                         data: Data(#"{"access_token":"sl.AAA","refresh_token":"rt.BBB","uid":"42","expires_in":14400}"#.utf8))
        }
        let token = try await DropboxPKCEAuth.exchangeCode("the-code", appKey: "abc123",
                                                           codeVerifier: "the-verifier",
                                                           redirectURI: "http://127.0.0.1:54321", httpClient: stub)
        XCTAssertEqual(token.accessToken, "sl.AAA")
        XCTAssertEqual(token.refreshToken, "rt.BBB")

        let request = try XCTUnwrap(stub.sentRequests.first)
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.url, DropboxPKCEAuth.tokenEndpoint)
        XCTAssertEqual(request.headers["Content-Type"], "application/x-www-form-urlencoded")
        let body = String(decoding: request.body ?? Data(), as: UTF8.self)
        XCTAssertTrue(body.contains("code=the-code"))
        XCTAssertTrue(body.contains("grant_type=authorization_code"))
        XCTAssertTrue(body.contains("code_verifier=the-verifier"))
        XCTAssertTrue(body.contains("client_id=abc123"))
    }

    func testExchangeCode_pasteCode_omitsRedirectURIFromBody() async throws {
        let stub = StubHTTPClient { _ in
            HTTPResponse(statusCode: 200, data: Data(#"{"access_token":"sl.AAA","uid":"42"}"#.utf8))
        }
        _ = try await DropboxPKCEAuth.exchangeCode("the-code", appKey: "abc123",
                                                   codeVerifier: "the-verifier", httpClient: stub)
        let body = String(decoding: try XCTUnwrap(stub.sentRequests.first?.body), as: UTF8.self)
        XCTAssertFalse(body.contains("redirect_uri="))
        XCTAssertTrue(body.contains("code_verifier=the-verifier"))
    }

    func testExchangeCode_httpErrorThrows() async {
        let stub = StubHTTPClient { _ in HTTPResponse(statusCode: 400, data: Data(#"{"error":"invalid_grant"}"#.utf8)) }
        do {
            _ = try await DropboxPKCEAuth.exchangeCode("bad", appKey: "k", codeVerifier: "v",
                                                       redirectURI: "http://127.0.0.1:1", httpClient: stub)
            XCTFail("expected token exchange to throw on HTTP 400")
        } catch let error as StorageError {
            if case .authenticationFailed = error { } else { XCTFail("expected .authenticationFailed, got \(error)") }
        } catch { XCTFail("unexpected error \(error)") }
    }
}
