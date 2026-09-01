//
//  UserDataTests.swift
//  AppBoxTests

import XCTest
@testable import AppBox

final class UserDataTests: XCTestCase {

    private var savedEmail = ""; private var savedMessage = ""
    private var savedDownloadIPA = false; private var savedMoreDetails = false; private var savedShowPrevious = false
    private var savedChunkSize = 0; private var savedDebugLog = false; private var savedUpdateAlert = false
    private var savedCLIVersion = ""
    private var savedLaunchedVersion = ""
    private var savedUsedSpace = NSNumber(value: 0); private var savedAvailableSpace = NSNumber(value: 0)
    private var savedLoggedInEmail = ""; private var savedLoggedInName = ""

    override func setUp() {
        super.setUp()
        savedEmail = UserData.userEmail(); savedMessage = UserData.userMessage()
        savedDownloadIPA = UserData.downloadIPAEnable(); savedMoreDetails = UserData.moreDetailsEnable()
        savedShowPrevious = UserData.showPreviousVersions(); savedChunkSize = UserData.uploadChunkSize()
        savedDebugLog = UserData.debugLog(); savedUpdateAlert = UserData.updateAlertEnable()
        savedCLIVersion = UserData.cliVersion()
        savedLaunchedVersion = UserData.lastLaunchedVersion()
        savedUsedSpace = UserData.dropboxUsedSpace(); savedAvailableSpace = UserData.dropboxAvailableSpace()
        savedLoggedInEmail = UserData.loggedInUserEmail(); savedLoggedInName = UserData.loggedInUserDisplayName()
    }

    override func tearDown() {
        UserData.setUserEmail(savedEmail); UserData.setUserMessage(savedMessage)
        UserData.setDownloadIPAEnable(savedDownloadIPA); UserData.setMoreDetailsEnable(savedMoreDetails)
        UserData.setShowPreviousVersions(savedShowPrevious); UserData.setUploadChunkSize(savedChunkSize)
        UserData.setEnableDebugLog(savedDebugLog); UserData.setUpdateAlertEnable(savedUpdateAlert)
        UserData.setCLIVersion(savedCLIVersion)
        Self.storeLaunchedVersion(savedLaunchedVersion)
        UserData.setDropboxUsedSpace(savedUsedSpace); UserData.setDropboxAvailableSpace(savedAvailableSpace)
        UserData.setLoggedInUserEmail(savedLoggedInEmail); UserData.setLoggedInUserDisplayName(savedLoggedInName)
        super.tearDown()
    }

    func testSetAndGetUserEmail() {
        UserData.setUserEmail("test-unit@appbox.io")
        XCTAssertEqual(UserData.userEmail(), "test-unit@appbox.io")
        UserData.setUserEmail("")
    }

    func testUserEmail_WhenNil_ReturnsEmptyString() {
        UserData.setUserEmail(nil)
        XCTAssertEqual(UserData.userEmail(), "")
    }

    func testSetAndGetUserMessage() {
        UserData.setUserMessage("Test build ready for QA")
        XCTAssertEqual(UserData.userMessage(), "Test build ready for QA")
        UserData.setUserMessage("")
    }

    func testUserMessage_WhenNil_ReturnsEmptyString() {
        UserData.setUserMessage(nil)
        XCTAssertEqual(UserData.userMessage(), "")
    }

    func testSetAndGetDownloadIPAEnable() {
        UserData.setDownloadIPAEnable(true);  XCTAssertTrue(UserData.downloadIPAEnable())
        UserData.setDownloadIPAEnable(false); XCTAssertFalse(UserData.downloadIPAEnable())
    }

    func testSetAndGetMoreDetailsEnable() {
        UserData.setMoreDetailsEnable(true);  XCTAssertTrue(UserData.moreDetailsEnable())
        UserData.setMoreDetailsEnable(false); XCTAssertFalse(UserData.moreDetailsEnable())
    }

    func testSetAndGetShowPreviousVersions() {
        UserData.setShowPreviousVersions(true);  XCTAssertTrue(UserData.showPreviousVersions())
        UserData.setShowPreviousVersions(false); XCTAssertFalse(UserData.showPreviousVersions())
    }

    func testUploadChunkSize_Default_Returns100() {
        UserData.setUploadChunkSize(0)
        XCTAssertEqual(UserData.uploadChunkSize(), 100)
    }

    func testSetAndGetUploadChunkSize() {
        UserData.setUploadChunkSize(50)
        XCTAssertEqual(UserData.uploadChunkSize(), 50)
        UserData.setUploadChunkSize(100)
    }

    func testUploadChunkSize_NegativeValue_ReturnsDefault() {
        UserData.setUploadChunkSize(-1)
        XCTAssertEqual(UserData.uploadChunkSize(), 100)
    }

    func testSetAndGetDebugLog() {
        UserData.setEnableDebugLog(true);  XCTAssertTrue(UserData.debugLog())
        UserData.setEnableDebugLog(false); XCTAssertFalse(UserData.debugLog())
    }

    func testSetAndGetUpdateAlertEnable() {
        UserData.setUpdateAlertEnable(true);  XCTAssertTrue(UserData.updateAlertEnable())
        UserData.setUpdateAlertEnable(false); XCTAssertFalse(UserData.updateAlertEnable())
    }

    func testSetAndGetCLIVersion() {
        UserData.setCLIVersion("2.5.1")
        XCTAssertEqual(UserData.cliVersion(), "2.5.1")
        UserData.setCLIVersion("")
    }

    func testCLIVersion_WhenNil_ReturnsEmptyString() {
        UserData.setCLIVersion(nil)
        XCTAssertEqual(UserData.cliVersion(), "")
    }

    func testSetAndGetDropboxUsedSpace() {
        UserData.setDropboxUsedSpace(1024)
        XCTAssertEqual(UserData.dropboxUsedSpace(), 1024)
        UserData.setDropboxUsedSpace(0)
    }

    func testSetAndGetDropboxAvailableSpace() {
        UserData.setDropboxAvailableSpace(2048)
        XCTAssertEqual(UserData.dropboxAvailableSpace(), 2048)
        UserData.setDropboxAvailableSpace(0)
    }

    func testSetAndGetLoggedInUserEmail() {
        UserData.setLoggedInUserEmail("user@appbox-test.com")
        XCTAssertEqual(UserData.loggedInUserEmail(), "user@appbox-test.com")
        UserData.setLoggedInUserEmail("")
    }

    func testLoggedInUserEmail_WhenNil_ReturnsEmptyString() {
        UserData.setLoggedInUserEmail(nil)
        XCTAssertEqual(UserData.loggedInUserEmail(), "")
    }

    func testSetAndGetLoggedInUserDisplayName() {
        UserData.setLoggedInUserDisplayName("Test User")
        XCTAssertEqual(UserData.loggedInUserDisplayName(), "Test User")
        UserData.setLoggedInUserDisplayName("")
    }

    // MARK: - First launch after an update

    private static let launchedVersionKey = "AppBoxLastLaunchedVersion"

    private static func storeLaunchedVersion(_ version: String) {
        UserDefaults.standard.set(version, forKey: launchedVersionKey)
    }

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    func testIsFirstTimeAfterUpdate_WithOlderStoredVersion_ReturnsTrue() {
        Self.storeLaunchedVersion("0.0.1")
        XCTAssertTrue(UserData.isFirstTimeAfterUpdate())
    }

    func testIsFirstTimeAfterUpdate_WithSameStoredVersion_ReturnsFalse() {
        Self.storeLaunchedVersion(currentVersion)
        XCTAssertFalse(UserData.isFirstTimeAfterUpdate())
    }

    func testIsFirstTimeAfterUpdate_WithNewerStoredVersion_ReturnsFalse() {
        Self.storeLaunchedVersion("9999.0.0")
        XCTAssertFalse(UserData.isFirstTimeAfterUpdate())
    }

    func testIsFirstTimeAfterUpdate_OnFreshInstall_ReturnsFalse() {
        Self.storeLaunchedVersion("")
        XCTAssertFalse(UserData.isFirstTimeAfterUpdate())
    }

    func testRecordLaunchedVersion_StoresCurrentAndClearsTheUpdateFlag() {
        Self.storeLaunchedVersion("0.0.1")
        XCTAssertTrue(UserData.isFirstTimeAfterUpdate())

        UserData.recordLaunchedVersion()
        XCTAssertEqual(UserData.lastLaunchedVersion(), currentVersion)
        XCTAssertFalse(UserData.isFirstTimeAfterUpdate())
    }
}
