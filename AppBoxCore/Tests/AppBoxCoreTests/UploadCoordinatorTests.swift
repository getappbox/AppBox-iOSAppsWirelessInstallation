import XCTest
@testable import AppBoxCore

final class UploadCoordinatorTests: XCTestCase {

    // MARK: - Fakes

    /// A StorageProvider that returns a distinct shareable link per remote path (so we can assert the IPA link is threaded into the manifest and the manifest link into appinfo.json), records upload order, can seed an existing appinfo.json for the keep-same-link path, and can fail a configurable number of uploads to exercise retry.
    final class LinkFakeProvider: StorageProvider {
        let id: StorageProviderID = .dropbox
        var currentAccount: StorageAccount?

        private(set) var uploads: [(file: String, path: String)] = []
        private(set) var downloadedPaths: [RemotePath] = []
        var existingAppInfoJSON: Data?
        var alwaysFailUploadsWith: StorageError?
        var failUploadsBeforeSuccess = 0
        private var uploadFailures = 0

        var existingAppInfoRevision: String? = "rev-1"
        var conflictOnPreconditionedUpload = false
        private(set) var uploadPreconditions: [String?] = []
        private var revisionCounter = 1

        func authenticate() async throws -> StorageAccount { StorageAccount(providerID: .dropbox, accountID: "x") }
        func signOut() throws {}

        func upload(fileAt localURL: URL, to remotePath: RemotePath, progress: ((Double) -> Void)?) async throws {
            if let error = alwaysFailUploadsWith { throw error }
            if uploadFailures < failUploadsBeforeSuccess {
                uploadFailures += 1
                throw StorageError.network("transient")
            }
            progress?(0.5)
            progress?(1.0)
            uploads.append((localURL.lastPathComponent, remotePath.path))
        }

        var appInfoShareURLOverride: String?

        func createShareableLink(for remotePath: RemotePath) async throws -> ShareableLink {
            if let appInfoShareURLOverride, remotePath.path.contains("appinfo.json") {
                return ShareableLink(url: URL(string: appInfoShareURLOverride)!, isDirectDownload: true)
            }
            return ShareableLink(url: URL(string: "https://links.test\(remotePath.path)")!, isDirectDownload: true)
        }
        func existingShareableLink(for remotePath: RemotePath) async throws -> ShareableLink? { nil }
        func listRevisions(for remotePath: RemotePath) async throws -> [RemoteRevision] { [] }
        func delete(at remotePath: RemotePath) async throws {}
        func download(from remotePath: RemotePath, to localURL: URL) async throws {
            downloadedPaths.append(remotePath)
            guard let data = existingAppInfoJSON else { throw StorageError.notFound }
            try data.write(to: localURL)
        }

        func upload(fileAt localURL: URL, to remotePath: RemotePath,
                    ifRevisionMatches precondition: String?, progress: ((Double) -> Void)?) async throws -> String? {
            uploadPreconditions.append(precondition)
            if conflictOnPreconditionedUpload, precondition != nil {
                throw StorageError.conflict("changed on the server")
            }
            try await upload(fileAt: localURL, to: remotePath, progress: progress)
            revisionCounter += 1
            return "rev-\(revisionCounter)"
        }

        func downloadWithRevision(from remotePath: RemotePath, to localURL: URL) async throws -> String? {
            try await download(from: remotePath, to: localURL)
            return existingAppInfoRevision
        }
    }

    final class FixedShortLinkService: ShortLinkService {
        let url: URL?
        private(set) var requests: [ShortLinkRequest] = []
        init(_ url: URL?) { self.url = url }
        func shortLink(for request: ShortLinkRequest) async -> URL? { requests.append(request); return url }
    }

    // MARK: - Helpers

    private var workingDir: URL!

    override func setUpWithError() throws {
        workingDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: workingDir, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: workingDir)
    }

    private func makePlan(keepSameLink: Bool = false, keepPreviousVersions: Bool = false) throws -> UploadPlan {
        let ipa = workingDir.appendingPathComponent("AppBoxTestApp.ipa")
        try Data("not-a-real-ipa".utf8).write(to: ipa)
        let entry = AppVersionInput(
            name: "AppBoxTestApp", version: "1.4", build: "1", identifier: "co.developerinsider.AppBoxTestApp",
            manifestLink: "", timestamp: 0, shareableIPALink: "",
            includeIPALink: true, includeDetails: true,
            minOSVersion: "15.4", supportedDevice: "iPhone and iPad", buildType: "development", ipaFileSizeMB: 263)
        return UploadPlan(
            ipaLocalURL: ipa, workingDirectory: workingDir,
            ipaRemotePath: RemotePath(path: "/app/1.4/AppBoxTestApp.ipa"),
            manifestRemotePath: RemotePath(path: "/app/1.4/manifest.plist"),
            appInfoRemotePath: RemotePath(path: keepSameLink ? "/app/appinfo.json" : "/app/1.4/appinfo.json"),
            name: "AppBoxTestApp", version: "1.4", build: "1", identifier: "co.developerinsider.AppBoxTestApp",
            entryInput: entry, keepSameLink: keepSameLink, keepPreviousVersions: keepPreviousVersions)
    }

    private func readAppInfo() throws -> AppInfoFile {
        let url = workingDir.appendingPathComponent(UploadCoordinator.appInfoFilename)
        return try JSONDecoder().decode(AppInfoFile.self, from: Data(contentsOf: url))
    }

    // MARK: - Tests

    func testHappyPath_uploadsInOrderAndThreadsLinks() async throws {
        let provider = LinkFakeProvider()
        let progress = RecordingProgressReporter()
        let coordinator = UploadCoordinator(provider: provider, progress: progress,
                                            dateProvider: FixedDateProvider(Date(timeIntervalSince1970: 1_000)),
                                            shortLinkService: FixedShortLinkService(URL(string: "https://appbox.me/abc")!))
        let result = try await coordinator.run(try makePlan())

        XCTAssertEqual(provider.uploads.map(\.path), [
            "/app/1.4/AppBoxTestApp.ipa",
            "/app/1.4/manifest.plist",
            "/app/1.4/appinfo.json",
            "/app/1.4/appinfo.json",
        ])

        XCTAssertEqual(result.ipaLink.absoluteString, "https://links.test/app/1.4/AppBoxTestApp.ipa")
        XCTAssertEqual(result.manifestLink.absoluteString, "https://links.test/app/1.4/manifest.plist")
        XCTAssertEqual(result.appInfoSharedLink.absoluteString, "https://links.test/app/1.4/appinfo.json")
        XCTAssertEqual(result.shortLink.absoluteString, "https://appbox.me/abc")

        let manifestData = try Data(contentsOf: workingDir.appendingPathComponent(UploadCoordinator.manifestFilename))
        let manifestText = String(decoding: manifestData, as: UTF8.self)
        XCTAssertTrue(manifestText.contains("https://links.test/app/1.4/AppBoxTestApp.ipa"))

        let appInfo = try readAppInfo()
        XCTAssertEqual(appInfo.latestVersion?.manifestLink, "https://links.test/app/1.4/manifest.plist")
        XCTAssertEqual(appInfo.latestVersion?.ipaFileLink, "https://links.test/app/1.4/AppBoxTestApp.ipa")
        XCTAssertEqual(appInfo.latestVersion?.timestamp, 1_000)
        XCTAssertEqual(appInfo.uniqueLinkShared, "https://links.test/app/1.4/appinfo.json")
        XCTAssertEqual(appInfo.uniqueLinkShort, "https://appbox.me/abc")
        XCTAssertEqual(appInfo.versions.count, 1)

        XCTAssertEqual(progress.stages.first, .preparing)
        XCTAssertEqual(progress.stages.last, .completed)
        XCTAssertTrue(progress.stages.contains(.uploading))
        XCTAssertTrue(progress.stages.contains(.creatingLink))
    }

    func testNoShortLinkService_fallsBackToLongLink() async throws {
        let provider = LinkFakeProvider()
        let coordinator = UploadCoordinator(provider: provider, shortLinkService: nil)
        let result = try await coordinator.run(try makePlan())

        XCTAssertEqual(result.shortLink, result.appInfoSharedLink)
        XCTAssertEqual(try readAppInfo().uniqueLinkShort, "https://links.test/app/1.4/appinfo.json")
    }

    func testServiceReturningNil_fallsBackToLongLink() async throws {
        let provider = LinkFakeProvider()
        let coordinator = UploadCoordinator(provider: provider, shortLinkService: FixedShortLinkService(nil))
        let result = try await coordinator.run(try makePlan())
        XCTAssertEqual(result.shortLink, result.appInfoSharedLink)
    }

    func testShortenerUnavailable_fallsBackToInstallPageURL_notRawDropboxURL() async throws {
        let provider = LinkFakeProvider()
        provider.appInfoShareURLOverride = "https://www.dropbox.com/scl/fi/abc/appinfo.json?rlkey=xyz"
        let coordinator = UploadCoordinator(provider: provider, shortLinkService: FixedShortLinkService(nil))
        let result = try await coordinator.run(try makePlan())

        let expectedInstall = "https://web.getappbox.com?url=/scl/fi/abc/appinfo.json?rlkey=xyz"
        XCTAssertEqual(result.installLink.absoluteString, expectedInstall)
        XCTAssertEqual(result.shortLink, result.installLink)
        XCTAssertNotEqual(result.shortLink.absoluteString, "https://www.dropbox.com/scl/fi/abc/appinfo.json?rlkey=xyz")
        XCTAssertEqual(try readAppInfo().uniqueLinkShort, expectedInstall)
        XCTAssertEqual(try readAppInfo().uniqueLinkShared, "https://www.dropbox.com/scl/fi/abc/appinfo.json?rlkey=xyz")
    }

    func testShortenerSucceeds_shortLinkDiffersFromInstallLink() async throws {
        let provider = LinkFakeProvider()
        provider.appInfoShareURLOverride = "https://www.dropbox.com/scl/fi/abc/appinfo.json?rlkey=xyz"
        let coordinator = UploadCoordinator(provider: provider,
                                            shortLinkService: FixedShortLinkService(URL(string: "https://appbox.me/abc")!))
        let result = try await coordinator.run(try makePlan())
        XCTAssertEqual(result.shortLink.absoluteString, "https://appbox.me/abc")
        XCTAssertEqual(result.installLink.absoluteString, "https://web.getappbox.com?url=/scl/fi/abc/appinfo.json?rlkey=xyz")
        XCTAssertNotEqual(result.shortLink, result.installLink) // success → ShowLink shows no "unavailable" hint
    }

    func testKeepSameLink_loadsAndAppendsExistingHistory() async throws {
        let provider = LinkFakeProvider()
        let prior = AppVersionEntry(name: "AppBoxTestApp", version: "1.0", build: "1",
                                    identifier: "co.developerinsider.AppBoxTestApp",
                                    manifestLink: "https://old/manifest", timestamp: 1)
        provider.existingAppInfoJSON = try JSONEncoder().encode(AppInfoFile(latestVersion: prior, versions: [prior]))

        let coordinator = UploadCoordinator(provider: provider)
        _ = try await coordinator.run(try makePlan(keepSameLink: true, keepPreviousVersions: true))

        XCTAssertEqual(provider.downloadedPaths.map(\.path), ["/app/appinfo.json"])
        let appInfo = try readAppInfo()
        XCTAssertEqual(appInfo.versions.count, 2)
        XCTAssertEqual(appInfo.versions.first?.version, "1.0")
        XCTAssertEqual(appInfo.versions.last?.version, "1.4")
    }

    func testKeepSameLink_resetsHistoryWhenNotKeepingPreviousVersions() async throws {
        let provider = LinkFakeProvider()
        let prior = AppVersionEntry(name: "x", version: "1.0", build: "1", identifier: "id",
                                    manifestLink: "m", timestamp: 1)
        provider.existingAppInfoJSON = try JSONEncoder().encode(AppInfoFile(latestVersion: prior, versions: [prior]))

        let coordinator = UploadCoordinator(provider: provider)
        _ = try await coordinator.run(try makePlan(keepSameLink: true, keepPreviousVersions: false))

        let appInfo = try readAppInfo()
        XCTAssertEqual(appInfo.versions.count, 1)
        XCTAssertEqual(appInfo.versions.first?.version, "1.4")
    }

    func testKeepSameLink_preconditionsAppInfoUploadsOnItsRevisions() async throws {
        let provider = LinkFakeProvider()
        let prior = AppVersionEntry(name: "x", version: "1.0", build: "1", identifier: "id",
                                    manifestLink: "m", timestamp: 1)
        provider.existingAppInfoJSON = try JSONEncoder().encode(AppInfoFile(latestVersion: prior, versions: [prior]))
        provider.existingAppInfoRevision = "rev-1"

        let coordinator = UploadCoordinator(provider: provider)
        _ = try await coordinator.run(try makePlan(keepSameLink: true, keepPreviousVersions: true))

        XCTAssertEqual(provider.uploadPreconditions.count, 4)
        XCTAssertNil(provider.uploadPreconditions[0])
        XCTAssertNil(provider.uploadPreconditions[1])
        XCTAssertEqual(provider.uploadPreconditions[2], "rev-1")
        XCTAssertEqual(provider.uploadPreconditions[3], "rev-4")
    }

    func testFreshUpload_secondAppInfoUploadPreconditionedOnFirst() async throws {
        let provider = LinkFakeProvider()
        let coordinator = UploadCoordinator(provider: provider)
        _ = try await coordinator.run(try makePlan())

        XCTAssertEqual(provider.uploadPreconditions.count, 4)
        XCTAssertNil(provider.uploadPreconditions[2])
        XCTAssertNotNil(provider.uploadPreconditions[3])
    }

    func testConcurrentWriterConflict_surfacesAsConflictError() async throws {
        let provider = LinkFakeProvider()
        let prior = AppVersionEntry(name: "x", version: "1.0", build: "1", identifier: "id",
                                    manifestLink: "m", timestamp: 1)
        provider.existingAppInfoJSON = try JSONEncoder().encode(AppInfoFile(latestVersion: prior, versions: [prior]))
        provider.conflictOnPreconditionedUpload = true

        let coordinator = UploadCoordinator(provider: provider)
        do {
            _ = try await coordinator.run(try makePlan(keepSameLink: true, keepPreviousVersions: true))
            XCTFail("expected a conflict when the shared appinfo.json changed under us")
        } catch let StorageError.conflict(message) {
            XCTAssertEqual(message, "changed on the server")
            XCTAssertEqual(provider.uploadPreconditions.filter { $0 != nil }.count, 1)
        }
    }

    func testRetriesTransientUploadThenSucceeds() async throws {
        let provider = LinkFakeProvider()
        provider.failUploadsBeforeSuccess = 2
        let coordinator = UploadCoordinator(provider: provider)
        let result = try await coordinator.run(try makePlan())
        XCTAssertEqual(result.ipaLink.absoluteString, "https://links.test/app/1.4/AppBoxTestApp.ipa")
        XCTAssertEqual(provider.uploads.count, 4)
    }

    func testExhaustedRetriesThrows() async throws {
        let provider = LinkFakeProvider()
        provider.failUploadsBeforeSuccess = 99
        let coordinator = UploadCoordinator(provider: provider, maxRetries: 3)
        do {
            _ = try await coordinator.run(try makePlan())
            XCTFail("expected the upload to fail after exhausting retries")
        } catch let error as StorageError {
            XCTAssertEqual(error, .network("transient"))
        }
    }

    func testNonRetryableErrorPropagatesImmediately() async throws {
        let provider = LinkFakeProvider()
        provider.alwaysFailUploadsWith = .notAuthenticated
        let coordinator = UploadCoordinator(provider: provider)
        do {
            _ = try await coordinator.run(try makePlan())
            XCTFail("expected a non-retryable error to propagate")
        } catch let error as StorageError {
            XCTAssertEqual(error, .notAuthenticated)
            XCTAssertEqual(provider.uploads.count, 0)
        }
    }
}
