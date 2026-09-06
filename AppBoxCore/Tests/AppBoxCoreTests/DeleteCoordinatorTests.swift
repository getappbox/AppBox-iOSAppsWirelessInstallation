import XCTest
@testable import AppBoxCore

/// In-memory `StorageProvider` for delete tests — records deletes/downloads/uploads, serves a seeded `appinfo.json` on download (or `.notFound`), and can fail downloads a configurable number of times.
private final class DeleteFakeProvider: StorageProvider {
    let id: StorageProviderID = .dropbox
    var currentAccount: StorageAccount?

    var existingAppInfoJSON: Data?
    var failDownloadsBeforeSuccess = 0
    private var downloadFailures = 0

    private(set) var deletedPaths: [RemotePath] = []
    private(set) var downloadedPaths: [RemotePath] = []
    private(set) var uploads: [(path: RemotePath, data: Data)] = []

    func authenticate() async throws -> StorageAccount { StorageAccount(providerID: .dropbox, accountID: "x") }
    func signOut() throws {}

    func upload(fileAt localURL: URL, to remotePath: RemotePath, progress: ((Double) -> Void)?) async throws {
        let data = (try? Data(contentsOf: localURL)) ?? Data()
        uploads.append((remotePath, data))
        progress?(1.0)
    }

    func createShareableLink(for remotePath: RemotePath) async throws -> ShareableLink {
        ShareableLink(url: URL(string: "https://x")!, isDirectDownload: true)
    }
    func existingShareableLink(for remotePath: RemotePath) async throws -> ShareableLink? { nil }
    func listRevisions(for remotePath: RemotePath) async throws -> [RemoteRevision] { [] }
    func delete(at remotePath: RemotePath) async throws { deletedPaths.append(remotePath) }

    func download(from remotePath: RemotePath, to localURL: URL) async throws {
        if downloadFailures < failDownloadsBeforeSuccess {
            downloadFailures += 1
            throw StorageError.network("transient")
        }
        downloadedPaths.append(remotePath)
        guard let data = existingAppInfoJSON else { throw StorageError.notFound }
        try data.write(to: localURL)
    }

    var existingAppInfoRevision: String? = "rev-7"
    var conflictOnPreconditionedUpload = false
    private(set) var uploadPreconditions: [String?] = []

    func upload(fileAt localURL: URL, to remotePath: RemotePath,
                ifRevisionMatches precondition: String?, progress: ((Double) -> Void)?) async throws -> String? {
        uploadPreconditions.append(precondition)
        if conflictOnPreconditionedUpload, precondition != nil {
            throw StorageError.conflict("changed on the server")
        }
        try await upload(fileAt: localURL, to: remotePath, progress: progress)
        return "rev-new"
    }

    func downloadWithRevision(from remotePath: RemotePath, to localURL: URL) async throws -> String? {
        try await download(from: remotePath, to: localURL)
        return existingAppInfoRevision
    }
}

final class DeleteCoordinatorTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("DeleteCoordinatorTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let tempDir { try? FileManager.default.removeItem(at: tempDir) }
    }

    // MARK: Helpers

    private func entry(_ link: String) -> AppVersionEntry {
        AppInfoJSON.makeEntry(AppVersionInput(name: "App", version: "1", build: "1", identifier: "com.x",
                                              manifestLink: link, timestamp: 1, shareableIPALink: "ipa",
                                              includeIPALink: false, includeDetails: false))
    }

    private func appInfoData(versions: [AppVersionEntry], latest: AppVersionEntry?) -> Data {
        let file = AppInfoFile(latestVersion: latest, versions: versions,
                               uniqueLinkShared: "https://s/full", uniqueLinkShort: "https://s/abc")
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted]
        return try! encoder.encode(file)
    }

    private func decodeUploaded(_ data: Data) -> AppInfoFile { try! JSONDecoder().decode(AppInfoFile.self, from: data) }

    private func plan(keepSameLink: Bool, manifestToRemove: String = "m1") -> DeletePlan {
        DeletePlan(keepSameLink: keepSameLink,
                   appInfoRemotePath: RemotePath(path: "/app/appinfo.json"),
                   manifestLinkToRemove: manifestToRemove,
                   appFolderPath: RemotePath(path: "/app"),
                   buildFolderPath: RemotePath(path: "/app/1.0"),
                   workingDirectory: tempDir)
    }

    // MARK: Tests

    func testNonKeepSameLink_deletesBuildFolderOnly() async throws {
        let provider = DeleteFakeProvider()
        let outcome = try await DeleteCoordinator(provider: provider).run(plan(keepSameLink: false))

        XCTAssertEqual(outcome, .deletedFolder(RemotePath(path: "/app/1.0")))
        XCTAssertEqual(provider.deletedPaths.map(\.path), ["/app/1.0"])
        XCTAssertTrue(provider.downloadedPaths.isEmpty)
        XCTAssertTrue(provider.uploads.isEmpty)
    }

    func testKeepSameLink_removeNonLast_reuploadsAppInfoWithoutVersion() async throws {
        let provider = DeleteFakeProvider()
        provider.existingAppInfoJSON = appInfoData(versions: [entry("m1"), entry("m2")], latest: entry("m2"))
        let outcome = try await DeleteCoordinator(provider: provider).run(plan(keepSameLink: true, manifestToRemove: "m1"))

        XCTAssertEqual(outcome, .updatedAppInfo)
        XCTAssertTrue(provider.deletedPaths.isEmpty)
        XCTAssertEqual(provider.uploads.map(\.path.path), ["/app/appinfo.json"])
        let uploaded = decodeUploaded(provider.uploads[0].data)
        XCTAssertEqual(uploaded.versions.map(\.manifestLink), ["m2"])
        XCTAssertEqual(uploaded.latestVersion?.manifestLink, "m2")
        XCTAssertEqual(uploaded.uniqueLinkShort, "https://s/abc") // other top-level keys preserved
    }

    func testKeepSameLink_removeLatest_latestFollows() async throws {
        let provider = DeleteFakeProvider()
        provider.existingAppInfoJSON = appInfoData(versions: [entry("m1"), entry("m2")], latest: entry("m2"))
        let outcome = try await DeleteCoordinator(provider: provider).run(plan(keepSameLink: true, manifestToRemove: "m2"))

        XCTAssertEqual(outcome, .updatedAppInfo)
        let uploaded = decodeUploaded(provider.uploads[0].data)
        XCTAssertEqual(uploaded.versions.map(\.manifestLink), ["m1"])
        XCTAssertEqual(uploaded.latestVersion?.manifestLink, "m1") // latest fell back to the remaining entry
    }

    func testKeepSameLink_removeLastRemaining_deletesAppRootFolder() async throws {
        let provider = DeleteFakeProvider()
        provider.existingAppInfoJSON = appInfoData(versions: [entry("m1")], latest: entry("m1"))
        let outcome = try await DeleteCoordinator(provider: provider).run(plan(keepSameLink: true, manifestToRemove: "m1"))

        XCTAssertEqual(outcome, .deletedFolder(RemotePath(path: "/app")))
        XCTAssertEqual(provider.deletedPaths.map(\.path), ["/app"])
        XCTAssertTrue(provider.uploads.isEmpty)
    }

    func testKeepSameLink_appInfoMissing_isNoOp() async throws {
        let provider = DeleteFakeProvider()
        let outcome = try await DeleteCoordinator(provider: provider).run(plan(keepSameLink: true))

        XCTAssertEqual(outcome, .updatedAppInfo)
        XCTAssertTrue(provider.deletedPaths.isEmpty)
        XCTAssertTrue(provider.uploads.isEmpty)
    }

    func testTransientDownloadError_retriesThenSucceeds() async throws {
        let provider = DeleteFakeProvider()
        provider.existingAppInfoJSON = appInfoData(versions: [entry("m1"), entry("m2")], latest: entry("m2"))
        provider.failDownloadsBeforeSuccess = 1
        let outcome = try await DeleteCoordinator(provider: provider).run(plan(keepSameLink: true, manifestToRemove: "m1"))

        XCTAssertEqual(outcome, .updatedAppInfo)
        XCTAssertEqual(provider.uploads.count, 1)
    }

    func testKeepSameLink_reuploadPreconditionedOnDownloadedRevision() async throws {
        let provider = DeleteFakeProvider()
        provider.existingAppInfoJSON = appInfoData(versions: [entry("m1"), entry("m2")], latest: entry("m2"))
        provider.existingAppInfoRevision = "rev-7"
        _ = try await DeleteCoordinator(provider: provider).run(plan(keepSameLink: true, manifestToRemove: "m1"))

        XCTAssertEqual(provider.uploadPreconditions, ["rev-7"])
    }

    func testConcurrentWriterConflict_surfacesAsConflictError() async throws {
        let provider = DeleteFakeProvider()
        provider.existingAppInfoJSON = appInfoData(versions: [entry("m1"), entry("m2")], latest: entry("m2"))
        provider.conflictOnPreconditionedUpload = true

        do {
            _ = try await DeleteCoordinator(provider: provider).run(plan(keepSameLink: true, manifestToRemove: "m1"))
            XCTFail("expected a conflict when the shared appinfo.json changed under us")
        } catch let StorageError.conflict(message) {
            XCTAssertEqual(message, "changed on the server")
            XCTAssertTrue(provider.deletedPaths.isEmpty)
        }
    }

    func testNonRetryableDeleteError_propagates() async {
        final class FailingProvider: DeleteFakeProviderBase {
            override func delete(at remotePath: RemotePath) async throws { throw StorageError.notAuthenticated }
        }
        let provider = FailingProvider()
        do {
            _ = try await DeleteCoordinator(provider: provider).run(plan(keepSameLink: false))
            XCTFail("expected a non-retryable error to propagate")
        } catch let error as StorageError {
            XCTAssertEqual(error, .notAuthenticated)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }
}

/// Open base so a single test can override one method (Swift can't subclass a `private final` type).
class DeleteFakeProviderBase: StorageProvider {
    let id: StorageProviderID = .dropbox
    var currentAccount: StorageAccount?
    func authenticate() async throws -> StorageAccount { StorageAccount(providerID: .dropbox, accountID: "x") }
    func signOut() throws {}
    func upload(fileAt localURL: URL, to remotePath: RemotePath, progress: ((Double) -> Void)?) async throws {}
    func createShareableLink(for remotePath: RemotePath) async throws -> ShareableLink {
        ShareableLink(url: URL(string: "https://x")!, isDirectDownload: true)
    }
    func existingShareableLink(for remotePath: RemotePath) async throws -> ShareableLink? { nil }
    func listRevisions(for remotePath: RemotePath) async throws -> [RemoteRevision] { [] }
    func delete(at remotePath: RemotePath) async throws {}
    func download(from remotePath: RemotePath, to localURL: URL) async throws {}
}
