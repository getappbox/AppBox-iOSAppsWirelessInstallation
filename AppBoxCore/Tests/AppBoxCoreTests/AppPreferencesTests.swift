import XCTest
@testable import AppBoxCore

final class AppPreferencesTests: XCTestCase {

    private func makeDefaults() throws -> (UserDefaults, String) {
        let suiteName = "AppBoxCoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        return (defaults, suiteName)
    }

    func testUploadSettings_readsTheAppsPreferences() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(true, forKey: AppPreferences.Key.moreDetails)
        defaults.set(true, forKey: AppPreferences.Key.downloadIPA)
        defaults.set(false, forKey: AppPreferences.Key.showPreviousVersions)
        defaults.set(50, forKey: AppPreferences.Key.chunkSize)

        let settings = AppPreferences.uploadSettings(from: defaults)
        XCTAssertTrue(settings.includeDetails)
        XCTAssertTrue(settings.includeIPALink)
        XCTAssertFalse(settings.keepPreviousVersions)
        XCTAssertEqual(settings.chunkSizeMB, 50)
    }

    func testUploadSettings_honoursAnExplicitFalse() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(false, forKey: AppPreferences.Key.moreDetails)
        defaults.set(false, forKey: AppPreferences.Key.showPreviousVersions)

        let settings = AppPreferences.uploadSettings(from: defaults)
        XCTAssertFalse(settings.includeDetails)
        XCTAssertFalse(settings.keepPreviousVersions)
    }

    func testUploadSettings_unwrittenKeysUseTheFirstRunDefaults() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppPreferences.uploadSettings(from: defaults)
        XCTAssertTrue(settings.includeDetails, "a fresh app enables more details")
        XCTAssertTrue(settings.keepPreviousVersions)
        XCTAssertFalse(settings.includeIPALink)
        XCTAssertEqual(settings.chunkSizeMB, UploadSettings.defaultChunkSizeMB)
    }

    func testUploadSettings_nonPositiveChunkSizeFallsBack() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(0, forKey: AppPreferences.Key.chunkSize)
        XCTAssertEqual(AppPreferences.uploadSettings(from: defaults).chunkSizeMB, UploadSettings.defaultChunkSizeMB)

        defaults.set(-5, forKey: AppPreferences.Key.chunkSize)
        XCTAssertEqual(AppPreferences.uploadSettings(from: defaults).chunkSizeMB, UploadSettings.defaultChunkSizeMB)
    }

    // MARK: - Per-invocation overrides

    func testUploadSettings_overridesBeatStoredPreferences() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(true, forKey: AppPreferences.Key.moreDetails)
        defaults.set(false, forKey: AppPreferences.Key.downloadIPA)
        defaults.set(100, forKey: AppPreferences.Key.chunkSize)

        let settings = AppPreferences.uploadSettings(
            from: defaults,
            applying: UploadSettingsOverrides(
				chunkSizeMB: 25,
				includeIPALink: true,
				includeDetails: false))
        XCTAssertFalse(settings.includeDetails, "an override of false must beat a stored true")
        XCTAssertTrue(settings.includeIPALink)
        XCTAssertEqual(settings.chunkSizeMB, 25)
    }

    func testUploadSettings_nilOverridesLeaveStoredValuesAlone() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(true, forKey: AppPreferences.Key.moreDetails)
        defaults.set(true, forKey: AppPreferences.Key.downloadIPA)
        defaults.set(75, forKey: AppPreferences.Key.chunkSize)

        let settings = AppPreferences.uploadSettings(
            from: defaults,
            applying: UploadSettingsOverrides(includeDetails: nil))
        XCTAssertTrue(settings.includeDetails)
        XCTAssertTrue(settings.includeIPALink)
        XCTAssertEqual(settings.chunkSizeMB, 75)
    }

    func testUploadSettings_overridesApplyWithNoStoredPreferences() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppPreferences.uploadSettings(
            from: defaults,
            applying: UploadSettingsOverrides(includeIPALink: true, includeDetails: false))
        XCTAssertFalse(settings.includeDetails)
        XCTAssertTrue(settings.includeIPALink)
    }

    func testOverrides_isEmpty() {
        XCTAssertTrue(UploadSettingsOverrides().isEmpty)
        XCTAssertFalse(UploadSettingsOverrides(includeDetails: false).isEmpty)
        XCTAssertFalse(UploadSettingsOverrides(chunkSizeMB: 10).isEmpty)
    }

    func testDefaultLadder_flagBeatsPreferenceBeatsBuiltIn() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertTrue(AppPreferences.uploadSettings(from: defaults).includeDetails)

        defaults.set(false, forKey: AppPreferences.Key.moreDetails)
        XCTAssertFalse(AppPreferences.uploadSettings(from: defaults).includeDetails)

        XCTAssertTrue(AppPreferences.uploadSettings(
            from: defaults,
            applying: UploadSettingsOverrides(includeDetails: true)).includeDetails)
    }

    func testBuiltInDefaults_matchTheGUIsFirstInstallValues() {
        XCTAssertTrue(AppPreferences.FirstRun.moreDetails)
        XCTAssertFalse(AppPreferences.FirstRun.downloadIPA)
        XCTAssertTrue(AppPreferences.FirstRun.showPreviousVersions)
        XCTAssertEqual(UploadSettings.defaultChunkSizeMB, 100)
    }

    func testKeys_matchWhatTheGUIWrites() {
        XCTAssertEqual(AppPreferences.Key.downloadIPA, "DonwloadIPAEnable")
        XCTAssertEqual(AppPreferences.Key.moreDetails, "MoreDetailsEnable")
        XCTAssertEqual(AppPreferences.Key.showPreviousVersions, "ShowPreviousVersions")
        XCTAssertEqual(AppPreferences.Key.chunkSize, "UploadChunkSize")
        XCTAssertEqual(AppPreferences.suiteName, "com.developerinsider.AppBox")
    }
}
