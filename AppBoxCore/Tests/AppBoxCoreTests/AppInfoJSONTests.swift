import XCTest
@testable import AppBoxCore

final class DeviceUDIDMaskerTests: XCTestCase {

    func testLongUDID_masksMiddle() {
        let udid = String(repeating: "A", count: 40)
        let masked = DeviceUDIDMasker.mask(udid)
        XCTAssertEqual(masked, String(repeating: "A", count: 10) + "....." + String(repeating: "A", count: 10))
    }

    func testMediumUDID_masksShorterMiddle() {
        let udid = String(repeating: "B", count: 25) // 21...30
        let masked = DeviceUDIDMasker.mask(udid)
        XCTAssertEqual(masked, String(repeating: "B", count: 8) + "....." + String(repeating: "B", count: 12))
    }

    func testShortUDID_dropped() {
        XCTAssertNil(DeviceUDIDMasker.mask(String(repeating: "C", count: 20)))
    }
}

final class AppInfoJSONTests: XCTestCase {

    private func baseInput(includeIPALink: Bool, includeDetails: Bool) -> AppVersionInput {
        AppVersionInput(name: "AppBox", version: "4.2.0", build: "200", identifier: "com.x.app",
                        manifestLink: "https://m/manifest.plist", timestamp: 1_700_000_000,
                        shareableIPALink: "https://m/app.ipa",
                        includeIPALink: includeIPALink, includeDetails: includeDetails,
                        minOSVersion: "14.0", supportedDevice: "iPhone and iPad", buildType: "ad-hoc",
                        ipaFileSizeMB: 42, teamId: "TEAM1", teamName: "Team",
                        provisioningUUID: "uuid-1",
                        provisionedDevices: [String(repeating: "D", count: 40), "short"])
    }

    func testMinimalEntry_flagsOff() {
        let entry = AppInfoJSON.makeEntry(baseInput(includeIPALink: false, includeDetails: false))
        XCTAssertEqual(entry.name, "AppBox")
        XCTAssertEqual(entry.manifestLink, "https://m/manifest.plist")
        XCTAssertNil(entry.ipaFileLink)
        XCTAssertNil(entry.minosversion)
        XCTAssertNil(entry.mobileprovision)
    }

    func testEntry_withIPALink() {
        let entry = AppInfoJSON.makeEntry(baseInput(includeIPALink: true, includeDetails: false))
        XCTAssertEqual(entry.ipaFileLink, "https://m/app.ipa")
        XCTAssertNil(entry.mobileprovision)
    }

    func testEntry_withDetails_includesProvisioningAndMaskedDevices() {
        let entry = AppInfoJSON.makeEntry(baseInput(includeIPALink: true, includeDetails: true))
        XCTAssertEqual(entry.minosversion, "14.0")
        XCTAssertEqual(entry.supporteddevice, "iPhone and iPad")
        XCTAssertEqual(entry.buildtype, "ad-hoc")
        XCTAssertEqual(entry.ipafilesize, 42)
        let provisioning = try? XCTUnwrap(entry.mobileprovision)
        XCTAssertEqual(provisioning?.teamid, "TEAM1")
        XCTAssertEqual(provisioning?.uuid, "uuid-1")
        XCTAssertEqual(provisioning?.devicesudid?.count, 1)
        XCTAssertTrue(provisioning?.devicesudid?.first?.contains(".....") ?? false)
    }

    func testEntry_encodesExpectedJSONKeys() throws {
        let entry = AppInfoJSON.makeEntry(baseInput(includeIPALink: true, includeDetails: true))
        let data = try JSONEncoder().encode(entry)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["manifestLink"] as? String, "https://m/manifest.plist")
        XCTAssertEqual(json["ipaFileLink"] as? String, "https://m/app.ipa")
        XCTAssertNotNil(json["mobileprovision"])
        XCTAssertNil(json["unexpectedKey"])
        let provisioning = try XCTUnwrap(json["mobileprovision"] as? [String: Any])
        XCTAssertNotNil(provisioning["expirationdata"] ?? provisioning["teamid"]) // legacy keys present
    }

    func testHistory_keepsPreviousVersions() {
        let a = AppInfoJSON.makeEntry(baseInput(includeIPALink: false, includeDetails: false))
        let b = AppInfoJSON.makeEntry(baseInput(includeIPALink: true, includeDetails: false))
        let history = AppInfoJSON.updatedHistory([a], adding: b, keepPreviousVersions: true)
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history.last?.ipaFileLink, "https://m/app.ipa")
    }

    func testHistory_resetsWhenNotKeepingPrevious() {
        let a = AppInfoJSON.makeEntry(baseInput(includeIPALink: false, includeDetails: false))
        let b = AppInfoJSON.makeEntry(baseInput(includeIPALink: true, includeDetails: false))
        let history = AppInfoJSON.updatedHistory([a], adding: b, keepPreviousVersions: false)
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.ipaFileLink, "https://m/app.ipa")
    }
}

/// The removal half (keep-same-link delete) — symmetric with the add tests above.
final class AppInfoJSONRemovalTests: XCTestCase {

    private func entry(_ link: String) -> AppVersionEntry {
        AppInfoJSON.makeEntry(AppVersionInput(name: "App", version: "1", build: "1", identifier: "com.x",
                                              manifestLink: link, timestamp: 1, shareableIPALink: "ipa",
                                              includeIPALink: false, includeDetails: false))
    }

    // MARK: Pure logic

    func testRemoveMiddle_keepsLatest() {
        let (v1, v2, v3) = (entry("m1"), entry("m2"), entry("m3"))
        let result = AppInfoJSON.removingVersion(withManifestLink: "m2", from: [v1, v2, v3], latestVersion: v3)
        XCTAssertEqual(result, .updated(versions: [v1, v3], latestVersion: v3))
    }

    func testRemoveLatest_latestFollowsToLastRemaining() {
        let (v1, v2, v3) = (entry("m1"), entry("m2"), entry("m3"))
        let result = AppInfoJSON.removingVersion(withManifestLink: "m3", from: [v1, v2, v3], latestVersion: v3)
        XCTAssertEqual(result, .updated(versions: [v1, v2], latestVersion: v2))
    }

    func testRemoveFirst_keepsLatest() {
        let (v1, v2, v3) = (entry("m1"), entry("m2"), entry("m3"))
        let result = AppInfoJSON.removingVersion(withManifestLink: "m1", from: [v1, v2, v3], latestVersion: v3)
        XCTAssertEqual(result, .updated(versions: [v2, v3], latestVersion: v3))
    }

    func testRemoveLastRemaining_emptiesHistory() {
        let v1 = entry("m1")
        XCTAssertEqual(AppInfoJSON.removingVersion(withManifestLink: "m1", from: [v1], latestVersion: v1),
                       .historyEmptied)
    }

    func testEmptyHistory_emptiesHistory() {
        XCTAssertEqual(AppInfoJSON.removingVersion(withManifestLink: "m1", from: [], latestVersion: nil),
                       .historyEmptied)
    }

    func testNilLatest_defaultsToLastRemaining() {
        let (v1, v2) = (entry("m1"), entry("m2"))
        let result = AppInfoJSON.removingVersion(withManifestLink: "m1", from: [v1, v2], latestVersion: nil)
        XCTAssertEqual(result, .updated(versions: [v2], latestVersion: v2))
    }

    func testLinkNotFound_leavesHistoryAndLatestUnchanged() {
        let (v1, v2) = (entry("m1"), entry("m2"))
        let result = AppInfoJSON.removingVersion(withManifestLink: "nope", from: [v1, v2], latestVersion: v2)
        XCTAssertEqual(result, .updated(versions: [v1, v2], latestVersion: v2))
    }
}
