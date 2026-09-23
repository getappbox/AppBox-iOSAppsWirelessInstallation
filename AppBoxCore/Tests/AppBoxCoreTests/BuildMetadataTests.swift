import XCTest
@testable import AppBoxCore

final class BuildMetadataTests: XCTestCase {

    private let plist: [AnyHashable: Any] = [
        "CFBundleName": "My App",
        "CFBundleShortVersionString": "1.2",
        "CFBundleVersion": "345",
        "CFBundleIdentifier": "com.example.myapp",
        "MinimumOSVersion": "15.0",
        "UIDeviceFamily": [NSNumber(value: 1), NSNumber(value: 2)]
    ]

    func testParsesInfoPlistAndStripsSpacesFromName() {
        let metadata = BuildMetadata(infoPlist: plist)
        XCTAssertEqual(metadata?.name, "MyApp")
        XCTAssertEqual(metadata?.version, "1.2")
        XCTAssertEqual(metadata?.build, "345")
        XCTAssertEqual(metadata?.identifier, "com.example.myapp")
        XCTAssertEqual(metadata?.minimumOSVersion, "15.0")
        XCTAssertEqual(metadata?.supportedDevice, "iPhone and iPad")
    }

    func testReturnsNilWhenARequiredKeyIsMissing() {
        for key in ["CFBundleName", "CFBundleShortVersionString", "CFBundleVersion", "CFBundleIdentifier"] {
            var partial = plist
            partial.removeValue(forKey: key)
            XCTAssertNil(BuildMetadata(infoPlist: partial), "missing \(key) should fail validation")
        }
    }

    func testOptionalKeysMayBeAbsent() {
        var partial = plist
        partial.removeValue(forKey: "MinimumOSVersion")
        partial.removeValue(forKey: "UIDeviceFamily")
        let metadata = BuildMetadata(infoPlist: partial)
        XCTAssertNotNil(metadata)
        XCTAssertNil(metadata?.minimumOSVersion)
        XCTAssertEqual(metadata?.supportedDevice, "")
    }

    // MARK: - Remote paths (must stay byte-identical to the v3/GUI layout)

    private var metadata: BuildMetadata {
        BuildMetadata(name: "MyApp", version: "1.2", build: "345",
                      identifier: "com.example.myapp", minimumOSVersion: "15.0", supportedDevice: "iPhone")
    }

    func testDerivesTheBundleRelativeBuildLayout() {
        let paths = BuildRemotePaths(metadata: metadata, uuid: "ABC123", keepSameLink: false)
        XCTAssertEqual(paths.bundleDirectory, "/com.example.myapp")
        XCTAssertEqual(paths.buildDirectory, "/com.example.myapp/MyApp-ver1.2(345)-ABC123")
        XCTAssertEqual(paths.ipa.components, ["com.example.myapp", "MyApp-ver1.2(345)-ABC123", "MyApp.ipa"])
        XCTAssertEqual(paths.manifest.components, ["com.example.myapp", "MyApp-ver1.2(345)-ABC123", "manifest.plist"])
        XCTAssertEqual(paths.appInfo.components, ["com.example.myapp", "MyApp-ver1.2(345)-ABC123", "appinfo.json"])
    }

    func testKeepSameLinkHoistsAppInfoToTheBundleDirectory() {
        let paths = BuildRemotePaths(metadata: metadata, uuid: "ABC123", keepSameLink: true)
        XCTAssertEqual(paths.appInfo.components, ["com.example.myapp", "appinfo.json"])
        XCTAssertEqual(paths.ipa.components, ["com.example.myapp", "MyApp-ver1.2(345)-ABC123", "MyApp.ipa"])
    }

    func testExplicitBundleDirectoryOverridesTheIdentifier() {
        let paths = BuildRemotePaths(metadata: metadata, uuid: "ABC123",
                                     bundleDirectory: "/CustomFolder", keepSameLink: false)
        XCTAssertEqual(paths.bundleDirectory, "/CustomFolder")
        XCTAssertEqual(paths.buildDirectory, "/CustomFolder/MyApp-ver1.2(345)-ABC123")
    }

    func testNameWithPathCharactersStaysOneSegment() {
        let awkward = BuildMetadata(name: "Is?My/App", version: "1.0", build: "1",
                                    identifier: "com.example.myapp",
                                    minimumOSVersion: nil, supportedDevice: "iPhone")
        let paths = BuildRemotePaths(metadata: awkward, uuid: "ABC123", keepSameLink: false)
        XCTAssertEqual(paths.buildDirectory, "/com.example.myapp/IsMyApp-ver1.0(1)-ABC123")
        XCTAssertEqual(paths.ipa.components, ["com.example.myapp", "IsMyApp-ver1.0(1)-ABC123", "IsMyApp.ipa"])
        XCTAssertEqual(URL(string: paths.buildDirectory)?.path, paths.buildDirectory)
    }

    func testEmptyBundleDirectoryFallsBackToTheIdentifier() {
        let paths = BuildRemotePaths(metadata: metadata, uuid: "ABC123",
                                     bundleDirectory: "", keepSameLink: false)
        XCTAssertEqual(paths.bundleDirectory, "/com.example.myapp")
    }

    func testResolvedBundleDirectoryMatchesTheUploadLayout() {
        XCTAssertEqual(BuildRemotePaths.resolvedBundleDirectory(requested: nil, identifier: "com.example.myapp"),
                       "/com.example.myapp")
        XCTAssertEqual(BuildRemotePaths.resolvedBundleDirectory(requested: "", identifier: "com.example.myapp"),
                       "/com.example.myapp")
        XCTAssertEqual(BuildRemotePaths.resolvedBundleDirectory(requested: "/Team/QA", identifier: "com.example.myapp"),
                       "/Team/QA")

        let paths = BuildRemotePaths(metadata: metadata, uuid: "ABC123", bundleDirectory: "/Team/QA", keepSameLink: true)
        XCTAssertEqual(paths.bundleDirectory,
                       BuildRemotePaths.resolvedBundleDirectory(requested: "/Team/QA", identifier: metadata.identifier))
    }

    // MARK: - App folder of a stored build

    func testAppFolderOfAKeptBuildComesFromItsAppInfoPath() {
        let folder = BuildRemotePaths.appFolder(keepSameLink: true,
                                                appInfoPath: "/Team/QA/appinfo.json",
                                                buildDirectory: "/Team/QA/MyApp-ver1.2(345)-ABC123",
                                                folderName: "/Team")
        XCTAssertEqual(folder?.relativePath, "Team/QA")
    }

    func testAppFolderOfAKeptBuildFallsBackToItsBuildDirectory() {
        let folder = BuildRemotePaths.appFolder(keepSameLink: true,
                                                appInfoPath: nil,
                                                buildDirectory: "/Team/QA/MyApp-ver1.2(345)-ABC123",
                                                folderName: "/Team")
        XCTAssertEqual(folder?.relativePath, "Team/QA")
    }

    func testAppFolderOfAnUnkeptBuildIsItsBuildDirectorysParent() {
        let folder = BuildRemotePaths.appFolder(keepSameLink: false,
                                                appInfoPath: "/com.example.myapp/MyApp-ver1.2(345)-ABC123/appinfo.json",
                                                buildDirectory: "/com.example.myapp/MyApp-ver1.2(345)-ABC123",
                                                folderName: "AppBoxMyApp-ver1.2(345)-ABC123")
        XCTAssertEqual(folder?.relativePath, "com.example.myapp")
    }

    func testAppFolderFallsBackToTheStoredFolderNameWithoutPaths() {
        let folder = BuildRemotePaths.appFolder(keepSameLink: true, appInfoPath: "", buildDirectory: nil,
                                                folderName: "/com.example.myapp")
        XCTAssertEqual(folder?.relativePath, "com.example.myapp")
    }

    func testAppFolderIsNilWhenItWouldBeTheStorageRoot() {
        XCTAssertNil(BuildRemotePaths.appFolder(keepSameLink: true,
                                                appInfoPath: "/appinfo.json",
                                                buildDirectory: "//MyApp-ver1.2(345)-ABC123",
                                                folderName: "/com.example.myapp"))
        XCTAssertNil(BuildRemotePaths.appFolder(keepSameLink: false, appInfoPath: nil, buildDirectory: nil, folderName: nil))
    }

    func testAppFolderIsNilForAFolderThatSanitizesToTheRoot() {
        let paths = BuildRemotePaths(metadata: metadata, uuid: "ABC123", bundleDirectory: "//", keepSameLink: true)
        XCTAssertNil(BuildRemotePaths.appFolder(keepSameLink: true, appInfoPath: paths.appInfo.path,
                                                buildDirectory: paths.buildDirectory, folderName: paths.bundleDirectory))
    }

    // MARK: - Share URL export

    func testWritesShareURLsAsJSON() throws {
        let directory = NSTemporaryDirectory() + UUID().uuidString
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: directory) }

        let wrote = ShareURLExport.write(shareURL: URL(string: "https://appbox.me/x1"),
                                         ipaURL: URL(string: "https://dl/ipa"),
                                         manifestURL: nil,
                                         toDirectory: directory)
        XCTAssertTrue(wrote)

        let path = (directory as NSString).appendingPathComponent(ShareURLExport.fileName)
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let values = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])
        XCTAssertEqual(values["APPBOX_SHARE_URL"], "https://appbox.me/x1")
        XCTAssertEqual(values["APPBOX_IPA_URL"], "https://dl/ipa")
        XCTAssertEqual(values["APPBOX_MANIFEST_URL"], "")
    }
}
