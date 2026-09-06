import XCTest
@testable import AppBoxCore

final class StorageErrorTextTests: XCTestCase {

    func testNotAuthenticatedPointsAtTheLoginCommand() {
        XCTAssertEqual(StorageErrorText.cliMessage(for: StorageError.notAuthenticated),
                       "Not logged in to Dropbox. Run `appboxcli login` first.")
    }

    func testMessageCarryingCasesSurfaceTheirDetail() {
        let cases: [StorageError] = [
            .authenticationFailed("auth detail"),
            .network("network detail"),
            .conflict("conflict detail"),
            .server("server detail"),
            .unknown("unknown detail")
        ]
        let expected = ["auth detail", "network detail", "conflict detail", "server detail", "unknown detail"]
        for (error, message) in zip(cases, expected) {
            XCTAssertEqual(StorageErrorText.cliMessage(for: error), message, "\(error)")
        }
    }

    func testCasesWithoutDetailGetFixedText() {
        XCTAssertEqual(StorageErrorText.cliMessage(for: StorageError.notFound), "Not found.")
        XCTAssertEqual(StorageErrorText.cliMessage(for: StorageError.cancelled), "Cancelled.")
        XCTAssertEqual(StorageErrorText.cliMessage(for: StorageError.rateLimited(retryAfter: nil)),
                       "Dropbox is rate-limiting requests. Please try again shortly.")
        XCTAssertEqual(StorageErrorText.cliMessage(for: StorageError.rateLimited(retryAfter: 30)),
                       "Dropbox is rate-limiting requests. Please try again shortly.")
    }

    func testNonStorageErrorsFallBackToTheirDescription() {
        let error = NSError(domain: "com.example", code: 7,
                            userInfo: [NSLocalizedDescriptionKey: "something else broke"])
        XCTAssertEqual(StorageErrorText.cliMessage(for: error), "something else broke")
    }

    func testEveryStorageErrorCaseProducesNonEmptyText() {
        let all: [StorageError] = [
            .notAuthenticated, .authenticationFailed("a"), .network("b"), .rateLimited(retryAfter: nil),
            .notFound, .conflict("c"), .server("d"), .cancelled, .unknown("e")
        ]
        for error in all {
            XCTAssertFalse(StorageErrorText.cliMessage(for: error).isEmpty, "\(error) produced no text")
        }
    }
}
