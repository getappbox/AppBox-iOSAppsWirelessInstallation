import XCTest
@testable import AppBoxCore

final class MobileProvisionParserTests: XCTestCase {

    /// Builds bytes shaped like a real .mobileprovision: an XML plist embedded between binary header/footer markers (mirrors the ObjC test fixture).
    private func provisionData(plist: [String: Any]) -> Data {
        let plistData = try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        var data = Data("BINARY_HEADER_DATA".utf8)
        data.append(plistData)
        data.append(Data("BINARY_FOOTER_DATA".utf8))
        return data
    }

    private func parse(_ plist: [String: Any]) -> MobileProvisionInfo {
        MobileProvisionParser.parse(data: provisionData(plist: plist))
    }

    // MARK: build type

    func testBuildType_enterprise() {
        let info = parse(["ProvisionsAllDevices": true, "TeamIdentifier": ["ABC123"], "UUID": "u"])
        XCTAssertTrue(info.isValid)
        XCTAssertEqual(info.buildType, BuildType.enterprise)
    }

    func testBuildType_development() {
        let info = parse(["ProvisionedDevices": ["UDID-1"], "Entitlements": ["get-task-allow": true]])
        XCTAssertEqual(info.buildType, BuildType.development)
    }

    func testBuildType_adHoc() {
        let info = parse(["ProvisionedDevices": ["UDID-1"], "Entitlements": ["get-task-allow": false]])
        XCTAssertEqual(info.buildType, BuildType.adHoc)
    }

    func testBuildType_appStore() {
        let info = parse(["TeamIdentifier": ["STORE123"], "UUID": "u"])
        XCTAssertEqual(info.buildType, BuildType.appStore)
    }

    func testBuildType_developerId_forEmptyPlist() {
        let info = parse([:])
        XCTAssertTrue(info.isValid)
        XCTAssertEqual(info.buildType, BuildType.developerId)
    }

    // MARK: field extraction

    func testExtractsFields() {
        let created = Date(timeIntervalSince1970: 1_700_000_000)
        let expires = Date(timeIntervalSince1970: 1_800_000_000)
        let info = parse([
            "ProvisionedDevices": ["AAA", "BBB"],
            "Entitlements": ["get-task-allow": true],
            "TeamIdentifier": ["TEAM999"],
            "TeamName": "My Team",
            "UUID": "unique-uuid",
            "CreationDate": created,
            "ExpirationDate": expires
        ])
        XCTAssertEqual(info.teamId, "TEAM999")
        XCTAssertEqual(info.teamName, "My Team")
        XCTAssertEqual(info.uuid, "unique-uuid")
        XCTAssertEqual(info.provisionedDevices, ["AAA", "BBB"])
        XCTAssertEqual(info.createDate, created)
        XCTAssertEqual(info.expirationDate, expires)
    }

    // MARK: invalid input

    func testGarbageData_isNotValid() {
        let info = MobileProvisionParser.parse(data: Data("not a provisioning profile".utf8))
        XCTAssertFalse(info.isValid)
    }

    func testFileSystem_missingFile_isNotValid() {
        let info = MobileProvisionParser.parse(contentsOf: URL(fileURLWithPath: "/nope/x.mobileprovision"),
                                               fileSystem: InMemoryFileSystem())
        XCTAssertFalse(info.isValid)
    }

    func testFileSystem_readsAndParses() throws {
        let fs = InMemoryFileSystem()
        let url = URL(fileURLWithPath: "/tmp/test.mobileprovision")
        try fs.write(provisionData(plist: ["TeamIdentifier": ["T1"], "UUID": "abc"]), to: url)
        let info = MobileProvisionParser.parse(contentsOf: url, fileSystem: fs)
        XCTAssertTrue(info.isValid)
        XCTAssertEqual(info.uuid, "abc")
        XCTAssertEqual(info.buildType, BuildType.appStore)
    }
}
