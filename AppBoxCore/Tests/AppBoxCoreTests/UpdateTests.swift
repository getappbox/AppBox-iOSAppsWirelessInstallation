import XCTest
@testable import AppBoxCore

final class VersionCompareTests: XCTestCase {

    func testExtractVersion_plainAndPrefixed() {
        XCTAssertEqual(VersionCompare.extractVersion(from: "1.2.3"), "1.2.3")
        XCTAssertEqual(VersionCompare.extractVersion(from: "v2.5.1"), "2.5.1")
        XCTAssertEqual(VersionCompare.extractVersion(from: "release-3.0.0"), "3.0.0")
        XCTAssertEqual(VersionCompare.extractVersion(from: "AppBox v4.1.2"), "4.1.2")
        XCTAssertEqual(VersionCompare.extractVersion(from: "version1.0.0"), "1.0.0")
    }

    func testExtractVersion_shapesAndEdges() {
        XCTAssertEqual(VersionCompare.extractVersion(from: "5"), "5")
        XCTAssertEqual(VersionCompare.extractVersion(from: "1.0"), "1.0")
        XCTAssertEqual(VersionCompare.extractVersion(from: "1.2.3.4"), "1.2.3.4")
        XCTAssertEqual(VersionCompare.extractVersion(from: "1.2."), "1.2")
        XCTAssertEqual(VersionCompare.extractVersion(from: "v2.0-beta.1"), "2.0")
        XCTAssertEqual(VersionCompare.extractVersion(from: ".1.2"), "1.2")
        XCTAssertEqual(VersionCompare.extractVersion(from: "123.456.789"), "123.456.789")
    }

    func testExtractVersion_stopsAtAPreReleaseSuffix() {
        XCTAssertEqual(VersionCompare.extractVersion(from: "4.0.0-rc1"), "4.0.0")
        XCTAssertEqual(VersionCompare.extractVersion(from: "1.2.3-beta4"), "1.2.3")
        XCTAssertEqual(VersionCompare.extractVersion(from: "3.7.0 (build 42)"), "3.7.0")
    }

    func testIsUpdateAvailable_fromAPreReleaseBuild() {
        XCTAssertTrue(VersionCompare.isUpdateAvailable(latest: "4.0.1", current: "4.0.0-rc1"))
        XCTAssertTrue(VersionCompare.isUpdateAvailable(latest: "1.2.4", current: "1.2.3-beta4"))
        XCTAssertFalse(VersionCompare.isUpdateAvailable(latest: "4.0.0", current: "4.0.0-rc1"))
    }

    func testExtractVersion_noDigitsReturnsZero() {
        XCTAssertEqual(VersionCompare.extractVersion(from: nil), "0")
        XCTAssertEqual(VersionCompare.extractVersion(from: ""), "0")
        XCTAssertEqual(VersionCompare.extractVersion(from: "abc"), "0")
        XCTAssertEqual(VersionCompare.extractVersion(from: "..."), "0")
    }

    func testIsUpdateAvailable() {
        XCTAssertTrue(VersionCompare.isUpdateAvailable(latest: "v2.0.0", current: "1.9.9"))
        XCTAssertTrue(VersionCompare.isUpdateAvailable(latest: "v1.0.1", current: "1.0.0"))
        XCTAssertTrue(VersionCompare.isUpdateAvailable(latest: "v2.0.0", current: "1.99.99"))

        XCTAssertFalse(VersionCompare.isUpdateAvailable(latest: "v1.5.0", current: "1.5.0"))
        XCTAssertFalse(VersionCompare.isUpdateAvailable(latest: "v1.0.0", current: "2.0.0"))
    }
}

final class HomebrewDetectorTests: XCTestCase {

    func testNotInstalledWhenNoCaskPathExists() {
        let detector = HomebrewDetector(fileSystem: InMemoryFileSystem())
        XCTAssertFalse(detector.isInstalled)
    }

    func testInstalledWhenAppleSiliconCaskExists() throws {
        let fs = InMemoryFileSystem()
        try fs.createDirectory(at: URL(fileURLWithPath: "/opt/homebrew/Caskroom/appbox"), permissions: nil)
        XCTAssertTrue(HomebrewDetector(fileSystem: fs).isInstalled)
    }

    func testInstalledWhenIntelCaskExists() throws {
        let fs = InMemoryFileSystem()
        try fs.createDirectory(at: URL(fileURLWithPath: "/usr/local/Caskroom/appbox"), permissions: nil)
        XCTAssertTrue(HomebrewDetector(fileSystem: fs).isInstalled)
    }
}
