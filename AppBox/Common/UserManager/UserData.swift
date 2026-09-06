//
//  UserData.swift
//  AppBox

import Foundation
import AppBoxCore

public final class UserData: NSObject {

    private static var defaults: UserDefaults { .standard }

    // MARK: - Logged In User

	public class func isLoggedIn() -> Bool {
		DropboxSession.isAuthorized
	}

	public class func loggedInUserEmail() -> String {
		defaults.string(forKey: "LoggedInUserEmail") ?? ""
	}

	public class func setLoggedInUserEmail(_ value: String?) {
		defaults.set(value, forKey: "LoggedInUserEmail")
	}

	public class func loggedInUserDisplayName() -> String {
		defaults.string(forKey: "LoggedInUserDisplayName") ?? ""
	}

	public class func setLoggedInUserDisplayName(_ value: String?) {
		defaults.set(value, forKey: "LoggedInUserDisplayName")
	}

    // MARK: - Dropbox space

	public class func dropboxUsedSpace() -> NSNumber {
		NSNumber(value: defaults.double(forKey: "DropboxUsedSpace"))
	}

	public class func setDropboxUsedSpace(_ usedSpace: NSNumber) {
		defaults.set(usedSpace.intValue, forKey: "DropboxUsedSpace")
	}

	public class func dropboxAvailableSpace() -> NSNumber {
		NSNumber(value: defaults.double(forKey: "DropboxAvailableSpace"))
	}

	public class func setDropboxAvailableSpace(_ availableSpace: NSNumber) {
		defaults.set(availableSpace.intValue, forKey: "DropboxAvailableSpace")
	}

    // MARK: - Email / message

	public class func userEmail() -> String {
		defaults.string(forKey: "UserEmail") ?? ""
	}

	public class func setUserEmail(_ value: String?) {
		defaults.set(value, forKey: "UserEmail")
	}

	public class func userMessage() -> String {
		defaults.string(forKey: "UserMessage") ?? ""
	}

	public class func setUserMessage(_ value: String?) {
		defaults.set(value, forKey: "UserMessage")
	}

    // MARK: - Webhooks (secrets -> Keychain via Core WebhookSecrets; S3)

	public class func userSlackChannel() -> String {
		WebhookSecrets.shared.slackWebhook ?? ""
	}

	public class func setUserSlackChannel(_ slackChannel: String?) {
		WebhookSecrets.shared.slackWebhook = slackChannel
	}

	public class func userMicrosoftTeamWebHook() -> String {
		WebhookSecrets.shared.teamsWebhook ?? ""
	}

	public class func setUserMicrosoftTeamWebHook(_ value: String?) {
		WebhookSecrets.shared.teamsWebhook = value
	}

    // MARK: - Install-page settings

	public class func downloadIPAEnable() -> Bool {
		defaults.bool(forKey: "DonwloadIPAEnable")
	}

	public class func setDownloadIPAEnable(_ downloadIPA: Bool) {
		defaults.set(downloadIPA, forKey: "DonwloadIPAEnable")
	}

	public class func moreDetailsEnable() -> Bool {
		defaults.bool(forKey: "MoreDetailsEnable")
	}

	public class func setMoreDetailsEnable(_ moreDetails: Bool) {
		defaults.set(moreDetails, forKey: "MoreDetailsEnable")
	}

	public class func showPreviousVersions() -> Bool {
		defaults.bool(forKey: "ShowPreviousVersions")
	}

	public class func setShowPreviousVersions(_ previousVersion: Bool) {
		defaults.set(previousVersion, forKey: "ShowPreviousVersions")
	}

    // MARK: - App user check

	public class func isFirstTime() -> Bool {
		!defaults.bool(forKey: "AppSettingIsFirstTime")
	}

	public class func setIsFirstTime(_ isFirstTime: Bool) {
		defaults.set(isFirstTime, forKey: "AppSettingIsFirstTime")
	}

    private static var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

	public class func lastLaunchedVersion() -> String {
		defaults.string(forKey: "AppBoxLastLaunchedVersion") ?? ""
	}

	public class func isFirstTimeAfterUpdate() -> Bool {
		let previous = lastLaunchedVersion()
		guard !previous.isEmpty else {
			return false
		}
		return VersionCompare.isUpdateAvailable(latest: currentAppVersion, current: previous)
	}

	public class func recordLaunchedVersion() {
		defaults.set(currentAppVersion, forKey: "AppBoxLastLaunchedVersion")
	}

    // MARK: - Chunk size

    public class func uploadChunkSize() -> Int {
        let chunkSize = defaults.integer(forKey: "UploadChunkSize")
        return chunkSize > 0 ? chunkSize : 100
    }

	public class func setUploadChunkSize(_ chunkSize: Int) {
		defaults.set(chunkSize, forKey: "UploadChunkSize")
	}

    // MARK: - General settings

	public class func debugLog() -> Bool {
		defaults.bool(forKey: "DebugLogEnable")
	}

	public class func setEnableDebugLog(_ debugLog: Bool) {
		defaults.set(debugLog, forKey: "DebugLogEnable")
	}

	public class func updateAlertEnable() -> Bool {
		defaults.bool(forKey: "UpdateAlertEnable")
	}

	public class func setUpdateAlertEnable(_ updateAlert: Bool) {
		defaults.set(updateAlert, forKey: "UpdateAlertEnable")
	}

    // MARK: - CLI

	public class func cliVersion() -> String {
		defaults.string(forKey: "CLIVersion") ?? ""
	}

	public class func setCLIVersion(_ cliVersion: String?) {
		defaults.set(cliVersion, forKey: "CLIVersion")
	}
}
