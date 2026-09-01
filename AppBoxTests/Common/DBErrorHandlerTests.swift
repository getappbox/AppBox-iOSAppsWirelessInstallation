import XCTest
import AppBoxCore
@testable import AppBox

/// Covers the classification half of `DBErrorHandler`; `handleStorageError` itself shows an `NSAlert`, so only `payload` is exercised here.
final class DBErrorHandlerTests: XCTestCase {

    func testAuthErrorsRequestReLogin() {
        for error in [StorageError.notAuthenticated, .authenticationFailed("expired")] {
            let (message, isAuth) = DBErrorHandler.payload(for: error)
            XCTAssertTrue(isAuth, "\(error) should trigger re-login")
            XCTAssertEqual(message, "You're not signed in to Dropbox. Please log in again.")
        }
    }

    func testNonAuthErrorsDoNotRequestReLogin() {
        let errors: [StorageError] = [
            .network("offline"), .server("500"), .rateLimited(retryAfter: nil),
            .conflict("clash"), .notFound, .cancelled, .unknown("?")
        ]
        for error in errors {
            XCTAssertFalse(DBErrorHandler.payload(for: error).isAuth, "\(error) should not trigger re-login")
        }
    }

    func testNetworkAndServerErrorsGetTheirOwnAdvice() {
        XCTAssertEqual(DBErrorHandler.payload(for: StorageError.network("x")).message,
                       "No internet connection. Please check your connection and try again.")
        XCTAssertEqual(DBErrorHandler.payload(for: StorageError.server("x")).message,
                       "Dropbox had a temporary problem. Please try again.")
        XCTAssertEqual(DBErrorHandler.payload(for: StorageError.rateLimited(retryAfter: 5)).message,
                       "Dropbox had a temporary problem. Please try again.")
    }

    func testConflictExplainsNothingWasOverwritten() {
        let detailed = DBErrorHandler.payload(for: StorageError.conflict("another machine won")).message
        XCTAssertTrue(detailed.hasPrefix("another machine won"))
        XCTAssertTrue(detailed.contains("Nothing was overwritten"))

        let empty = DBErrorHandler.payload(for: StorageError.conflict("")).message
        XCTAssertTrue(empty.contains("changed by another AppBox"))
        XCTAssertTrue(empty.contains("Nothing was overwritten"))
    }

    func testNonStorageErrorsFallBackToTheirDescription() {
        let error = NSError(domain: "com.example", code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "disk on fire"])
        let (message, isAuth) = DBErrorHandler.payload(for: error)
        XCTAssertEqual(message, "disk on fire")
        XCTAssertFalse(isAuth)
    }

    func testEveryCaseProducesNonEmptyText() {
        let errors: [StorageError] = [
            .notAuthenticated, .authenticationFailed("a"), .network("b"), .rateLimited(retryAfter: nil),
            .notFound, .conflict("c"), .server("d"), .cancelled, .unknown("e")
        ]
        for error in errors {
            XCTAssertFalse(DBErrorHandler.payload(for: error).message.isEmpty, "\(error) produced no text")
        }
    }
}
