import XCTest
import ZIPFoundation
@testable import AppBoxCore

final class BuildUploadServiceTests: XCTestCase {

    private var tmp: URL!

    override func setUpWithError() throws {
        tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmp)
    }

    /// Builds a real .ipa containing a real binary Info.plist.
    private func makeIPA(name: String = "My App", version: String = "1.2", build: String = "345",
                         identifier: String = "com.example.myapp") throws -> URL {
        let appDir = tmp.appendingPathComponent("Payload/MyApp.app", isDirectory: true)
        try FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        let plist: [String: Any] = [
            "CFBundleName": name,
            "CFBundleShortVersionString": version,
            "CFBundleVersion": build,
            "CFBundleIdentifier": identifier,
            "MinimumOSVersion": "15.0",
            "UIDeviceFamily": [1, 2]
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0)
        try data.write(to: appDir.appendingPathComponent("Info.plist"))

        let ipa = tmp.appendingPathComponent("app.ipa")
        try FileManager.default.zipItem(at: tmp.appendingPathComponent("Payload"), to: ipa)
        return ipa
    }

    func testUploadsIPAManifestAndAppInfoToTheDerivedPaths() async throws {
        let ipa = try makeIPA()
        let provider = FakeStorageProvider()
        let service = BuildUploadService(provider: provider)

        let outcome = try await service.run(BuildUploadRequest(ipaURL: ipa, uuid: "ABC123"))

        XCTAssertEqual(outcome.metadata.name, "MyApp")
        XCTAssertEqual(outcome.metadata.version, "1.2")
        XCTAssertEqual(outcome.metadata.build, "345")
        XCTAssertEqual(outcome.metadata.identifier, "com.example.myapp")
        XCTAssertEqual(outcome.paths.buildDirectory, "/com.example.myapp/MyApp-ver1.2(345)-ABC123")

        let uploaded = provider.uploadedFiles.map { $0.remote.components.joined(separator: "/") }
        XCTAssertTrue(uploaded.contains("com.example.myapp/MyApp-ver1.2(345)-ABC123/MyApp.ipa"), "got \(uploaded)")
        XCTAssertTrue(uploaded.contains { $0.hasSuffix("manifest.plist") }, "got \(uploaded)")
    }

    /// Keep-same-link re-reads the existing appinfo.json, so the provider has to serve one back.
    func testKeepSameLinkPutsAppInfoInTheBundleDirectoryAndPreservesHistory() async throws {
        let ipa = try makeIPA()
        let provider = UploadCoordinatorTests.LinkFakeProvider()
        let prior = AppVersionEntry(name: "MyApp", version: "1.0", build: "1",
                                    identifier: "com.example.myapp", manifestLink: "m", timestamp: 1)
        provider.existingAppInfoJSON = try JSONEncoder().encode(AppInfoFile(latestVersion: prior, versions: [prior]))

        let service = BuildUploadService(provider: provider)
        let outcome = try await service.run(
            BuildUploadRequest(ipaURL: ipa, keepSameLink: true, uuid: "ABC123"))

        XCTAssertEqual(outcome.paths.appInfo.components, ["com.example.myapp", "appinfo.json"])
        XCTAssertEqual(provider.downloadedPaths.map(\.path), ["/com.example.myapp/appinfo.json"])
    }

    func testMissingIPAFailsWithExit119() async throws {
        let service = BuildUploadService(provider: FakeStorageProvider())
        let missing = tmp.appendingPathComponent("nope.ipa")

        do {
            _ = try await service.run(BuildUploadRequest(ipaURL: missing))
            XCTFail("expected failure")
        } catch let error as BuildUploadError {
            XCTAssertEqual(error.exitCode, 119)
            guard case .ipaNotFound = error else { return XCTFail("wrong case: \(error)") }
        }
    }

    func testIPAWithoutAValidInfoPlistFailsWithExit120() async throws {
        let appDir = tmp.appendingPathComponent("Payload/MyApp.app", isDirectory: true)
        try FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        try Data("not a plist".utf8).write(to: appDir.appendingPathComponent("Info.plist"))
        let ipa = tmp.appendingPathComponent("bad.ipa")
        try FileManager.default.zipItem(at: tmp.appendingPathComponent("Payload"), to: ipa)

        let service = BuildUploadService(provider: FakeStorageProvider())
        do {
            _ = try await service.run(BuildUploadRequest(ipaURL: ipa))
            XCTFail("expected failure")
        } catch let error as BuildUploadError {
            XCTAssertEqual(error.exitCode, 120)
            guard case .invalidInfoPlist = error else { return XCTFail("wrong case: \(error)") }
        }
    }

    func testNonIPAArchiveFailsWithExit121() async throws {
        let junk = tmp.appendingPathComponent("junk", isDirectory: true)
        try FileManager.default.createDirectory(at: junk, withIntermediateDirectories: true)
        try Data("x".utf8).write(to: junk.appendingPathComponent("readme.txt"))
        let zip = tmp.appendingPathComponent("junk.ipa")
        try FileManager.default.zipItem(at: junk, to: zip)

        let service = BuildUploadService(provider: FakeStorageProvider())
        do {
            _ = try await service.run(BuildUploadRequest(ipaURL: zip))
            XCTFail("expected failure")
        } catch let error as BuildUploadError {
            XCTAssertEqual(error.exitCode, 121)
        }
    }

    func testUploadFailureFailsWithExit124() async throws {
        let ipa = try makeIPA()
        let provider = FakeStorageProvider()
        provider.uploadError = StorageError.network("offline")
        let service = BuildUploadService(provider: provider)

        do {
            _ = try await service.run(BuildUploadRequest(ipaURL: ipa))
            XCTFail("expected failure")
        } catch let error as BuildUploadError {
            XCTAssertEqual(error.exitCode, 124)
        }
    }

    func testCleansUpItsWorkingDirectory() async throws {
        let ipa = try makeIPA()
        let before = try FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory()).count
        _ = try await BuildUploadService(provider: FakeStorageProvider())
            .run(BuildUploadRequest(ipaURL: ipa))
        let after = try FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory()).count
        XCTAssertEqual(before, after, "the extraction working directory should not be left behind")
    }
}
