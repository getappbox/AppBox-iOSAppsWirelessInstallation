import XCTest
@testable import AppBoxCore

/// Locks the one behaviour the transport flip changes: how a Dropbox share URL is normalized for AppBox's dashboard.
final class DropboxTransportTests: XCTestCase {

    func testNormalizedShareURL_legacySharedLink() {
        XCTAssertEqual(
            DropboxTransport.normalizedShareURL("https://www.dropbox.com/s/abc123/App.ipa?dl=0"),
            "https://www.dropbox.com/s/abc123/App.ipa"
        )
        XCTAssertEqual(
            DropboxTransport.normalizedShareURL("https://www.dropbox.com/s/abc123/App.ipa?dl=1"),
            "https://www.dropbox.com/s/abc123/App.ipa"
        )
    }

    func testNormalizedShareURL_modernSCLLinkKeepsRlkey() {
        XCTAssertEqual(
            DropboxTransport.normalizedShareURL("https://www.dropbox.com/scl/fi/xyz/App.ipa?rlkey=secret&dl=0"),
            "https://www.dropbox.com/scl/fi/xyz/App.ipa?rlkey=secret"
        )
    }

    func testNormalizedShareURL_noDLParamUnchanged() {
        XCTAssertEqual(
            DropboxTransport.normalizedShareURL("https://www.dropbox.com/scl/fi/xyz/App.ipa?rlkey=secret"),
            "https://www.dropbox.com/scl/fi/xyz/App.ipa?rlkey=secret"
        )
    }

    func testFailureKindAndAuthFlagRoundTripThroughNSError() {
        let auth = DropboxTransport.nsError(message: "x", kind: .other, isAuth: true)
        XCTAssertTrue(DropboxTransport.isAuthError(auth))
        XCTAssertEqual(DropboxTransport.failureKind(for: auth), .other)

        let server = DropboxTransport.nsError(message: "y", kind: .retryableServer, isAuth: false)
        XCTAssertFalse(DropboxTransport.isAuthError(server))
        XCTAssertEqual(DropboxTransport.failureKind(for: server), .retryableServer)

        let foreign = NSError(domain: "other", code: 1)
        XCTAssertEqual(DropboxTransport.failureKind(for: foreign), ABUploadFailureKind.none)
        XCTAssertFalse(DropboxTransport.isAuthError(foreign))
    }
}
