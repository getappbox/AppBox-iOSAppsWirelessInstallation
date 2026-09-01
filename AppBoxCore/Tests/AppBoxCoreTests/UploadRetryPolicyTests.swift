import XCTest
@testable import AppBoxCore

final class UploadRetryPolicyTests: XCTestCase {

    // MARK: decide

    func testConnectivityLossWhileOffline_pauses_evenAtMaxRetries() {
        XCTAssertEqual(
            UploadRetryPolicy.decide(failure: .connectivity, retryCount: 99, isConnected: false),
            .pauseUntilOnline)
    }

    func testConnectivityErrorWhileOnline_underCap_retries() {
        XCTAssertEqual(
            UploadRetryPolicy.decide(failure: .connectivity, retryCount: 0, isConnected: true),
            .retry)
    }

    func testConnectivityErrorWhileOnline_atCap_fails() {
        XCTAssertEqual(
            UploadRetryPolicy.decide(failure: .connectivity, retryCount: 3, isConnected: true),
            .fail)
    }

    func testRetryableServerWhileOnline_underCap_retries() {
        XCTAssertEqual(
            UploadRetryPolicy.decide(failure: .retryableServer, retryCount: 2, isConnected: true),
            .retry)
    }

    func testRetryableServerWhileOffline_fails() {
        XCTAssertEqual(
            UploadRetryPolicy.decide(failure: .retryableServer, retryCount: 0, isConnected: false),
            .fail)
    }

    func testOtherFailure_fails() {
        XCTAssertEqual(
            UploadRetryPolicy.decide(failure: .other, retryCount: 0, isConnected: true),
            .fail)
    }

    func testNoFailure_fails() {
        XCTAssertEqual(
            UploadRetryPolicy.decide(failure: nil, retryCount: 0, isConnected: true),
            .fail)
    }

    func testCustomMaxRetryCount() {
        XCTAssertEqual(
            UploadRetryPolicy.decide(failure: .retryableServer, retryCount: 1, isConnected: true, maxRetryCount: 1),
            .fail)
    }

    // MARK: isConnectivityError

    func testIsConnectivityError_trueForNetworkPathCodes() {
        for code in [NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost,
                     NSURLErrorTimedOut, NSURLErrorCannotFindHost, NSURLErrorDNSLookupFailed] {
            let error = NSError(domain: NSURLErrorDomain, code: code)
            XCTAssertTrue(UploadRetryPolicy.isConnectivityError(error), "code \(code)")
        }
    }

    func testIsConnectivityError_falseForOtherCodesAndDomains() {
        XCTAssertFalse(UploadRetryPolicy.isConnectivityError(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL)))
        XCTAssertFalse(UploadRetryPolicy.isConnectivityError(NSError(domain: "Other", code: NSURLErrorTimedOut)))
        XCTAssertFalse(UploadRetryPolicy.isConnectivityError(nil))
    }

    // MARK: StorageError mapping

    func testStorageErrorMapping() {
        XCTAssertEqual(UploadFailureKind(.network("x")), .connectivity)
        XCTAssertEqual(UploadFailureKind(.server("x")), .retryableServer)
        XCTAssertEqual(UploadFailureKind(.rateLimited(retryAfter: nil)), .retryableServer)
        XCTAssertEqual(UploadFailureKind(.notAuthenticated), .other)
        XCTAssertEqual(UploadFailureKind(.notFound), .other)
    }
}
