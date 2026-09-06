import XCTest
@testable import AppBoxCore

final class StorageTests: XCTestCase {

    func testRemotePath_pathStringAndComponents() {
        XCTAssertEqual(RemotePath(["a", "b", "c"]).path, "/a/b/c")
        XCTAssertEqual(RemotePath(path: "/a/b/c").components, ["a", "b", "c"])
        XCTAssertEqual(RemotePath(["a"]).appending("b").components, ["a", "b"])
    }

    func testStorageError_isRetryable() {
        XCTAssertTrue(StorageError.network("x").isRetryable)
        XCTAssertTrue(StorageError.server("x").isRetryable)
        XCTAssertTrue(StorageError.rateLimited(retryAfter: 1).isRetryable)

        XCTAssertFalse(StorageError.notAuthenticated.isRetryable)
        XCTAssertFalse(StorageError.authenticationFailed("x").isRetryable)
        XCTAssertFalse(StorageError.notFound.isRetryable)
        XCTAssertFalse(StorageError.conflict("x").isRetryable)
        XCTAssertFalse(StorageError.cancelled.isRetryable)
        XCTAssertFalse(StorageError.unknown("x").isRetryable)
    }

    func testStorageProviderRegistry_registerMakeAndList() {
        let registry = StorageProviderRegistry()
        XCTAssertNil(registry.makeProvider(.dropbox))

        registry.register(.dropbox) { FakeStorageProvider(id: .dropbox) }
        XCTAssertEqual(registry.makeProvider(.dropbox)?.id, .dropbox)
        XCTAssertEqual(registry.registeredProviders, [.dropbox])
    }

    func testStorageProviderRegistry_makeBuildsFreshInstances() {
        let registry = StorageProviderRegistry()
        registry.register(.dropbox) { FakeStorageProvider() }
        let first = registry.makeProvider(.dropbox)
        let second = registry.makeProvider(.dropbox)
        XCTAssertNotNil(first)
        XCTAssertNotNil(second)
        XCTAssertFalse(first === second)
    }
}
