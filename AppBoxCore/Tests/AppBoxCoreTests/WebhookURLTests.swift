import XCTest
@testable import AppBoxCore

final class WebhookURLTests: XCTestCase {

    func testAcceptsHTTPS() {
        XCTAssertTrue(WebhookURL.isValid("https://hooks.slack.com/services/T00/B00/xxxx"))
    }

    func testRejectsHTTP() {
        XCTAssertFalse(WebhookURL.isValid("http://example.com/webhook"))
    }

    func testRejectsEmptyString() {
        XCTAssertFalse(WebhookURL.isValid(""))
    }

    func testRejectsNil() {
        XCTAssertFalse(WebhookURL.isValid(nil))
    }

    func testRejectsMissingScheme() {
        XCTAssertFalse(WebhookURL.isValid("hooks.slack.com/services"))
    }

    func testRejectsNonHTTPSScheme() {
        XCTAssertFalse(WebhookURL.isValid("ftp://example.com/file"))
    }

    func testRejectsSchemeWithoutHost() {
        XCTAssertFalse(WebhookURL.isValid("https://"))
    }
}
