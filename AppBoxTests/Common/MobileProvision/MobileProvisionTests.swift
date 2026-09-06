//
//  MobileProvisionTests.swift
//  AppBoxTests

import XCTest
@testable import AppBox

final class MobileProvisionTests: XCTestCase {

    private var tempDir = ""

    override func setUp() {
        super.setUp()
        tempDir = (NSTemporaryDirectory() as NSString).appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: tempDir)
        super.tearDown()
    }

    private func makeProvisionFile(_ plist: [String: Any]) -> String {
        let data = try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        let plistString = String(data: data, encoding: .utf8) ?? ""
        let content = "BINARY_HEADER_DATA\(plistString)BINARY_FOOTER_DATA"
        let filePath = (tempDir as NSString).appendingPathComponent("test.mobileprovision")
        try? content.write(toFile: filePath, atomically: true, encoding: .isoLatin1)
        return filePath
    }

    // MARK: - Build type detection

    func testBuildType_Enterprise_WhenProvisionsAllDevices() {
        let p = MobileProvision(path: makeProvisionFile([
            "ProvisionsAllDevices": true, "TeamIdentifier": ["ABC123"], "TeamName": "Enterprise Corp", "UUID": "test-uuid-enterprise"]))
        XCTAssertTrue(p.isValid)
        XCTAssertEqual(p.buildType, "enterprise")
    }

    func testBuildType_Development_WhenHasDevicesAndGetTaskAllow() {
        let p = MobileProvision(path: makeProvisionFile([
            "ProvisionedDevices": ["UDID-1", "UDID-2"], "Entitlements": ["get-task-allow": true],
            "TeamIdentifier": ["DEV123"], "TeamName": "Dev Team", "UUID": "test-uuid-dev"]))
        XCTAssertTrue(p.isValid)
        XCTAssertEqual(p.buildType, "development")
    }

    func testBuildType_AdHoc_WhenHasDevicesButNoGetTaskAllow() {
        let p = MobileProvision(path: makeProvisionFile([
            "ProvisionedDevices": ["UDID-1", "UDID-2"], "Entitlements": ["get-task-allow": false],
            "TeamIdentifier": ["ADHOC123"], "TeamName": "AdHoc Team", "UUID": "test-uuid-adhoc"]))
        XCTAssertTrue(p.isValid)
        XCTAssertEqual(p.buildType, "ad-hoc")
    }

    func testBuildType_AppStore_WhenNoDevices() {
        let p = MobileProvision(path: makeProvisionFile([
            "TeamIdentifier": ["STORE123"], "TeamName": "AppStore Team", "UUID": "test-uuid-appstore"]))
        XCTAssertTrue(p.isValid)
        XCTAssertEqual(p.buildType, "app-store")
    }

    // MARK: - Property extraction

    func testExtractsTeamId() {
        let p = MobileProvision(path: makeProvisionFile(["TeamIdentifier": ["TEAM999"], "TeamName": "My Team", "UUID": "uuid-123"]))
        XCTAssertEqual(p.teamId, "TEAM999")
    }

    func testExtractsTeamName() {
        let p = MobileProvision(path: makeProvisionFile(["TeamIdentifier": ["T1"], "TeamName": "Awesome Team", "UUID": "uuid-456"]))
        XCTAssertEqual(p.teamName, "Awesome Team")
    }

    func testExtractsUUID() {
        let p = MobileProvision(path: makeProvisionFile(["TeamIdentifier": ["T1"], "TeamName": "Team", "UUID": "unique-profile-uuid"]))
        XCTAssertEqual(p.uuid, "unique-profile-uuid")
    }

    func testExtractsProvisionedDevices() {
        let devices = ["AAA-BBB-CCC", "DDD-EEE-FFF"]
        let p = MobileProvision(path: makeProvisionFile([
            "ProvisionedDevices": devices, "Entitlements": ["get-task-allow": true],
            "TeamIdentifier": ["T1"], "TeamName": "Team", "UUID": "uuid"]))
        XCTAssertEqual(p.provisionedDevices, devices)
    }

    func testExtractsCreationDate() {
        let createDate = Date(timeIntervalSince1970: 1700000000)
        let p = MobileProvision(path: makeProvisionFile(["TeamIdentifier": ["T1"], "TeamName": "Team", "UUID": "uuid", "CreationDate": createDate]))
        XCTAssertEqual(p.createDate, createDate)
    }

    func testExtractsExpirationDate() {
        let expDate = Date(timeIntervalSince1970: 1800000000)
        let p = MobileProvision(path: makeProvisionFile(["TeamIdentifier": ["T1"], "TeamName": "Team", "UUID": "uuid", "ExpirationDate": expDate]))
        XCTAssertEqual(p.expirationDate, expDate)
    }

    // MARK: - Invalid input

    func testInvalidPath_IsNotValid() {
        XCTAssertFalse(MobileProvision(path: "/nonexistent/path.mobileprovision").isValid)
    }

    func testFileWithNoPlist_IsNotValid() {
        let filePath = (tempDir as NSString).appendingPathComponent("garbage.mobileprovision")
        try? "this is not a valid mobileprovision file".write(toFile: filePath, atomically: true, encoding: .utf8)
        XCTAssertFalse(MobileProvision(path: filePath).isValid)
    }

    func testEmptyPlist_BuildType_DeveloperId() {
        let p = MobileProvision(path: makeProvisionFile([:]))
        XCTAssertTrue(p.isValid)
        XCTAssertEqual(p.buildType, "developer-id")
    }
}
