//
//  PreferencesViewController.swift
//  AppBox

import AppKit

public final class PreferencesViewController: NSViewController {

    private static let cliPath = "/usr/local/bin/appboxcli"

    public override func loadView() {
        let chunkSizes = [10, 25, 50, 75, 100, 125, 150]
        let helpURLs = [
            "downloadIPA": "https://docs.getappbox.com/Features/downloadipa/",
            "moreDetails": "https://docs.getappbox.com/Features/moredetails/",
            "hidePreviousVersions": "https://docs.getappbox.com/Features/keepsamelink/#12-install-previous-versions:~:text=How%20to%20Create%20Two%20Different%20Links%20for%20the%20Same%20Build%20with%20the%20%22Keep%20Same%20Link%22%20Option%3F",
            "chunkSize": "https://docs.getappbox.com/Features/uploadchunksize/",
            "cli": "https://docs.getappbox.com/CommandLineInterface/",
        ]
        let cliInstalled = FileManager.default.fileExists(atPath: Self.cliPath)

        view = GeneralPreferencesHost.makeView(
            chunkSize: UserData.uploadChunkSize(),
            chunkSizes: chunkSizes,
            downloadIPA: UserData.downloadIPAEnable(),
            moreDetails: UserData.moreDetailsEnable(),
            hidePreviousVersions: !UserData.showPreviousVersions(),
            updateAlert: !UserData.updateAlertEnable(),
            limitedLog: !UserData.debugLog(),
            isDefaultHandler: DefaultAppHandler.isDefaultIPAHandler(),
            cliInstalled: cliInstalled,
            helpURLs: helpURLs,
            onChunkSize: { UserData.setUploadChunkSize($0) },
            onBoolChange: { key, isOn in
                switch key {
                case "downloadIPA":
					UserData.setDownloadIPAEnable(isOn)
                case "moreDetails":
					UserData.setMoreDetailsEnable(isOn)
                case "hidePreviousVersions":
					UserData.setShowPreviousVersions(!isOn)
				case "updateAlert":
					UserData.setUpdateAlertEnable(!isOn)
                case "limitedLog":
					UserData.setEnableDebugLog(!isOn)
                default:
					break
                }
            },
            onSetDefaultHandler: { isOn in
                if isOn { DefaultAppHandler.setAsDefaultIPAHandler() }
                else { DefaultAppHandler.removeAsDefaultIPAHandler() }
            },
            onToggleCLI: {
                if FileManager.default.fileExists(atPath: Self.cliPath) {
                    _ = CLISupportHelper.uninstall()
                } else {
                    _ = CLISupportHelper.install()
                }
                return FileManager.default.fileExists(atPath: Self.cliPath)
            })
    }
}
