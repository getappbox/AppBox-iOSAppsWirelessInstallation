import XCTest
@testable import AppBoxCore

final class DropboxCLIAuthTests: XCTestCase {

    /// `beginAuthorization` must build a paste-code authorize URL: a real PKCE challenge, the app key, and crucially NO `redirect_uri` (Dropbox rejects any unregistered redirect, so we send none and let it display the code).
    func testBeginAuthorization_buildsNoRedirectPasteCodeURL() throws {
        let auth = DropboxCLIAuth(appKey: "abc123")
        let request = auth.beginAuthorization()

        let items = try XCTUnwrap(URLComponents(url: request.authorizeURL, resolvingAgainstBaseURL: false)?.queryItems)
        func value(_ name: String) -> String? { items.first { $0.name == name }?.value }

        XCTAssertEqual(request.authorizeURL.host, "www.dropbox.com")
        XCTAssertEqual(request.authorizeURL.path, "/oauth2/authorize")
        XCTAssertEqual(value("client_id"), "abc123")
        XCTAssertEqual(value("response_type"), "code")
        XCTAssertEqual(value("code_challenge_method"), "S256")
        XCTAssertNil(value("redirect_uri"))
        XCTAssertNil(value("state"))

        let challenge = try XCTUnwrap(value("code_challenge"))
        XCTAssertFalse(challenge.isEmpty)
        XCTAssertFalse(request.verifier.isEmpty)
    }

    // MARK: SpaceUsage derived values

    func testSpaceUsage_individual_allocatedAndAvailable() {
        let usage = DropboxCLISession.SpaceUsage(usedBytes: 30, allocation: .individual(allocated: 100))
        XCTAssertEqual(usage.allocatedBytes, 100)
        XCTAssertEqual(usage.availableBytes, 70)
    }

    func testSpaceUsage_team_withPerUserQuota_usesUserAllocationNotTeamTotal() {
        let usage = DropboxCLISession.SpaceUsage(
            usedBytes: 40,
            allocation: .team(used: 250, allocated: 1000, userAllocated: 100, userUsed: 40))
        XCTAssertEqual(usage.allocatedBytes, 100)
        XCTAssertEqual(usage.availableBytes, 60)
    }

    func testSpaceUsage_team_unrestrictedMember_hasNoPersonalTotal() {
        let usage = DropboxCLISession.SpaceUsage(
            usedBytes: 40,
            allocation: .team(used: 250, allocated: 1000, userAllocated: 0, userUsed: 40))
        XCTAssertNil(usage.allocatedBytes)
        XCTAssertNil(usage.availableBytes)
    }

    func testSpaceUsage_availableClampsAtZeroWhenOverAllocated() {
        let usage = DropboxCLISession.SpaceUsage(usedBytes: 120, allocation: .individual(allocated: 100))
        XCTAssertEqual(usage.availableBytes, 0)
    }

    func testSpaceUsage_otherAllocation_hasNoKnownTotal() {
        let usage = DropboxCLISession.SpaceUsage(usedBytes: 10, allocation: .other)
        XCTAssertNil(usage.allocatedBytes)
        XCTAssertNil(usage.availableBytes)
    }
}
