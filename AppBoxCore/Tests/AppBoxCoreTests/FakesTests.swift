import XCTest
@testable import AppBoxCore

final class FakesTests: XCTestCase {

    func testInMemoryKeyValueStore_roundTripAndDefaults() {
        let store = InMemoryKeyValueStore()
        store.set("v", forKey: "k")
        XCTAssertEqual(store.string(forKey: "k"), "v")

        store.set(nil, forKey: "k")
        XCTAssertNil(store.string(forKey: "k"))
        XCTAssertEqual(store.integer(forKey: "missing"), 0)
        XCTAssertFalse(store.bool(forKey: "missing"))
    }

    func testInMemorySecureStore_roundTripAccountsAndRemoval() throws {
        let store = InMemorySecureStore()
        try store.setString("token-a", forAccount: "alice", service: "dropbox")
        try store.setString("token-b", forAccount: "bob", service: "dropbox")

        XCTAssertEqual(try store.string(forAccount: "alice", service: "dropbox"), "token-a")
        XCTAssertEqual(Set(try store.accounts(forService: "dropbox")), ["alice", "bob"])

        try store.removeItem(forAccount: "alice", service: "dropbox")
        XCTAssertNil(try store.data(forAccount: "alice", service: "dropbox"))

        try store.removeAllItems(forService: "dropbox")
        XCTAssertEqual(try store.accounts(forService: "dropbox"), [])
    }

    func testStubHTTPClient_recordsRequestsAndReturnsCannedResponse() async throws {
        let stub = StubHTTPClient { _ in HTTPResponse(statusCode: 201, data: Data("ok".utf8)) }
        let response = try await stub.send(HTTPRequest(url: URL(string: "https://x.test")!, method: .post))

        XCTAssertEqual(response.statusCode, 201)
        XCTAssertTrue(response.isSuccess)
        XCTAssertEqual(stub.sentRequests.count, 1)
        XCTAssertEqual(stub.sentRequests.first?.method, .post)
    }

    func testInMemoryFileSystem_writeReadRemoveAndChunk() throws {
        let fs = InMemoryFileSystem()
        let dir = try fs.createUniqueDirectory(permissions: 0o700)
        XCTAssertEqual(try fs.attributes(of: dir).posixPermissions, 0o700)

        let file = dir.appendingPathComponent("f.bin")
        try fs.write(Data([1, 2, 3, 4, 5]), to: file)
        XCTAssertTrue(fs.fileExists(at: file))
        XCTAssertEqual(try fs.attributes(of: file).size, 5)

        let handle = try fs.openForReading(file)
        XCTAssertEqual(Array(try handle.read(upToCount: 2)), [1, 2])
        try handle.seek(toOffset: 4)
        XCTAssertEqual(Array(try handle.read(upToCount: 10)), [5])

        try fs.removeItem(at: file)
        XCTAssertFalse(fs.fileExists(at: file))
    }

    func testInMemoryFileSystem_uniqueDirectoriesDiffer() throws {
        let fs = InMemoryFileSystem()
        XCTAssertNotEqual(try fs.createUniqueDirectory(), try fs.createUniqueDirectory())
    }

    func testFixedDateProvider_returnsFixedTime() {
        let date = Date(timeIntervalSince1970: 1000)
        XCTAssertEqual(FixedDateProvider(date).now(), date)
    }

    func testRecordingProgressReporter_recordsStages() {
        let reporter = RecordingProgressReporter()
        reporter.report(stage: .uploading, message: "m", fractionCompleted: 0.5)
        reporter.report(stage: .completed, message: nil, fractionCompleted: 1)

        XCTAssertEqual(reporter.stages, [.uploading, .completed])
        XCTAssertEqual(reporter.entries.first?.fraction, 0.5)
    }

    func testNullProgressReporter_doesNotCrash() {
        NullProgressReporter().report(stage: .preparing, message: nil, fractionCompleted: nil)
    }

    func testFakeStorageProvider_authenticateUploadAndLink() async throws {
        let provider = FakeStorageProvider()
        XCTAssertNil(provider.currentAccount)

        let account = try await provider.authenticate()
        XCTAssertEqual(provider.currentAccount, account)

        let path = RemotePath(["com.acme.app", "1.0", "app.ipa"])
        var reported = 0.0
        try await provider.upload(fileAt: URL(fileURLWithPath: "/tmp/app.ipa"), to: path) { reported = $0 }

        XCTAssertEqual(reported, 1.0)
        XCTAssertEqual(provider.uploadedFiles.count, 1)
        XCTAssertEqual(provider.uploadedFiles.first?.remote, path)

        let link = try await provider.createShareableLink(for: path)
        XCTAssertTrue(link.isDirectDownload)
    }

    func testFakeStorageProvider_uploadPropagatesError() async {
        let provider = FakeStorageProvider()
        provider.uploadError = StorageError.network("down")
        do {
            try await provider.upload(fileAt: URL(fileURLWithPath: "/tmp/x"), to: RemotePath(["x"]), progress: nil)
            XCTFail("expected upload to throw")
        } catch {
            XCTAssertEqual(error as? StorageError, .network("down"))
        }
    }
}
