//
//  IPAUploadInfoTests.swift
//  AppBoxTests

import XCTest
@testable import AppBox

private let uniqueJSON = "appinfo.json"

final class IPAUploadInfoTests: XCTestCase {

    private func plist(_ extra: [AnyHashable: Any] = [:]) -> [AnyHashable: Any] {
        var base: [AnyHashable: Any] = [
            "CFBundleName": "TestApp",
            "CFBundleVersion": "1",
            "CFBundleIdentifier": "com.test.app",
            "CFBundleShortVersionString": "1.0",
        ]
        for (k, v) in extra { base[k] = v }
        return base
    }

    // MARK: - init (empty)

    func testInitEmpty_SetsKeepSameLinkToZero() { XCTAssertEqual(IPAUploadInfo().keepSameLink, NSNumber(value: 0)) }
    func testInitEmpty_SetsEmptyEmails() { XCTAssertEqual(IPAUploadInfo().emails, "") }
    func testInitEmpty_SetsEmptyBuildType() { XCTAssertEqual(IPAUploadInfo().buildType, "") }
    func testInitEmpty_SetsEmptyPersonalMessage() { XCTAssertEqual(IPAUploadInfo().personalMessage, "") }

    // MARK: - setName

    func testSetName_RemovesSpaces() {
        let info = IPAUploadInfo(); info.name = "My App Name"
        XCTAssertEqual(info.name, "MyAppName")
    }

    func testSetName_WithNoSpaces_RemainsUnchanged() {
        let info = IPAUploadInfo(); info.name = "MyApp"
        XCTAssertEqual(info.name, "MyApp")
    }

    func testSetName_WithMultipleSpaces_RemovesAll() {
        let info = IPAUploadInfo(); info.name = "  My  App  "
        XCTAssertEqual(info.name, "MyApp")
    }

    // MARK: - isValidInfoPlist

    func testIsValidInfoPlist_WithAllFields_ReturnsYES() {
        let info = IPAUploadInfo(); info.ipaInfoPlist = plist()
        XCTAssertTrue(info.isValidInfoPlist())
    }

    func testIsValidInfoPlist_WithNilPlist_ReturnsNO() {
        XCTAssertFalse(IPAUploadInfo().isValidInfoPlist())
    }

    func testIsValidInfoPlist_WithMissingName_ReturnsNO() {
        let info = IPAUploadInfo()
        info.ipaInfoPlist = ["CFBundleVersion": "1", "CFBundleIdentifier": "com.test.app", "CFBundleShortVersionString": "1.0"]
        XCTAssertFalse(info.isValidInfoPlist())
    }

    func testIsValidInfoPlist_WithMissingVersion_ReturnsNO() {
        let info = IPAUploadInfo()
        info.ipaInfoPlist = ["CFBundleName": "TestApp", "CFBundleVersion": "1", "CFBundleIdentifier": "com.test.app"]
        XCTAssertFalse(info.isValidInfoPlist())
    }

    func testIsValidInfoPlist_WithMissingBuild_ReturnsNO() {
        let info = IPAUploadInfo()
        info.ipaInfoPlist = ["CFBundleName": "TestApp", "CFBundleIdentifier": "com.test.app", "CFBundleShortVersionString": "1.0"]
        XCTAssertFalse(info.isValidInfoPlist())
    }

    func testIsValidInfoPlist_WithMissingIdentifier_ReturnsNO() {
        let info = IPAUploadInfo()
        info.ipaInfoPlist = ["CFBundleName": "TestApp", "CFBundleVersion": "1", "CFBundleShortVersionString": "1.0"]
        XCTAssertFalse(info.isValidInfoPlist())
    }

    // MARK: - setIpaInfoPlist extraction

    func testSetIpaInfoPlist_ExtractsBundleVersion() {
        let info = IPAUploadInfo(); info.ipaInfoPlist = plist(["CFBundleVersion": "42"])
        XCTAssertEqual(info.build, "42")
    }

    func testSetIpaInfoPlist_ExtractsVersion() {
        let info = IPAUploadInfo(); info.ipaInfoPlist = plist(["CFBundleShortVersionString": "3.5.2"])
        XCTAssertEqual(info.version, "3.5.2")
    }

    func testSetIpaInfoPlist_ExtractsIdentifier() {
        let info = IPAUploadInfo(); info.ipaInfoPlist = plist(["CFBundleIdentifier": "com.example.myapp"])
        XCTAssertEqual(info.identifer, "com.example.myapp")
    }

    func testSetIpaInfoPlist_ExtractsMinOS() {
        let info = IPAUploadInfo(); info.ipaInfoPlist = plist(["MinimumOSVersion": "15.0"])
        XCTAssertEqual(info.miniOSVersion, "15.0")
    }

    func testSetIpaInfoPlist_SupportedDevice_iPhone() {
        let info = IPAUploadInfo(); info.ipaInfoPlist = plist(["UIDeviceFamily": [1]])
        XCTAssertEqual(info.supportedDevice, "iPhone")
    }

    func testSetIpaInfoPlist_SupportedDevice_iPad() {
        let info = IPAUploadInfo(); info.ipaInfoPlist = plist(["UIDeviceFamily": [2]])
        XCTAssertEqual(info.supportedDevice, "iPad")
    }

    func testSetIpaInfoPlist_SupportedDevice_Universal() {
        let info = IPAUploadInfo(); info.ipaInfoPlist = plist(["UIDeviceFamily": [1, 2]])
        XCTAssertEqual(info.supportedDevice, "iPhone and iPad")
    }

    func testSetIpaInfoPlist_GeneratesUUID() {
        let info = IPAUploadInfo(); info.ipaInfoPlist = plist()
        XCTAssertFalse((info.uuid ?? "").isEmpty)
    }

    func testSetIpaInfoPlist_NameStripsSpaces() {
        let info = IPAUploadInfo(); info.ipaInfoPlist = plist(["CFBundleName": "My Cool App"])
        XCTAssertEqual(info.name, "MyCoolApp")
    }

    // MARK: - validURLString

    func testValidURLString_WithNormalString_ReturnsSameString() {
        XCTAssertEqual(IPAUploadInfo().validURLString("MyApp"), "MyApp")
    }

    func testValidURLString_WithEmptyString_ReturnsAppBox() {
        XCTAssertEqual(IPAUploadInfo().validURLString(""), "AppBox")
    }

    func testValidURLString_WithNilString_ReturnsAppBox() {
        XCTAssertEqual(IPAUploadInfo().validURLString(nil), "AppBox")
    }

    func testValidURLString_StripsInvalidURLCharacters() {
        let result = IPAUploadInfo().validURLString("My App")
        XCTAssertFalse(result.isEmpty)
    }

    func testValidURLString_WithSpecialCharacters_RemovesDisallowedChars() {
        let input = "App\u{01}Box"
        XCTAssertEqual(IPAUploadInfo().validURLString(input), "AppBox")
    }

    func testValidURLString_WithVersion_PreservesDotsAndNumbers() {
        XCTAssertEqual(IPAUploadInfo().validURLString("1.2.3"), "1.2.3")
    }

    func testValidURLString_WithSlashes_PreservesSlashes() {
        XCTAssertEqual(IPAUploadInfo().validURLString("/com.example.app"), "/com.example.app")
    }

    // MARK: - upadteDbDirectoryByBundleDirectory (driven via setIpaInfoPlist)

    func testUpdateDbDirectory_SetsDbDirectory() {
        let info = IPAUploadInfo(); info.ipaInfoPlist = plist(["CFBundleVersion": "5", "CFBundleIdentifier": "com.test.myapp", "CFBundleShortVersionString": "2.0"])
        let dbDir = info.dbDirectory?.absoluteString ?? ""
        XCTAssertTrue(dbDir.contains("TestApp"))
        XCTAssertTrue(dbDir.contains("ver2.0"))
        XCTAssertTrue(dbDir.contains("(5)"))
    }

    func testUpdateDbDirectory_SetsDbIPAFullPath() {
        let info = IPAUploadInfo(); info.ipaInfoPlist = plist()
        let path = info.dbIPAFullPath?.absoluteString ?? ""
        XCTAssertTrue(path.hasSuffix(".ipa"))
        XCTAssertTrue(path.contains("TestApp"))
    }

    func testUpdateDbDirectory_SetsManifestPath() {
        let info = IPAUploadInfo(); info.ipaInfoPlist = plist()
        XCTAssertTrue((info.dbManifestFullPath?.absoluteString ?? "").hasSuffix("manifest.plist"))
    }

    func testUpdateDbDirectory_SetsAppInfoJSONPath() {
        let info = IPAUploadInfo(); info.ipaInfoPlist = plist()
        XCTAssertTrue((info.dbAppInfoJSONFullPath?.absoluteString ?? "").contains(uniqueJSON))
    }

    func testUpdateDbDirectory_WithKeepSameLink_JSONInBundleDir() {
        let info = IPAUploadInfo(); info.isKeepSameLinkEnabled = true; info.ipaInfoPlist = plist()
        let jsonPath = info.dbAppInfoJSONFullPath?.absoluteString ?? ""
        XCTAssertFalse(jsonPath.contains("ver1.0"))
        XCTAssertTrue(jsonPath.contains(uniqueJSON))
    }

}
