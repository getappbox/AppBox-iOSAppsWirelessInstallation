//
//  NSApplication+MenuHandler.swift
//  AppBox

import AppKit
import os
import AppBoxCore

extension NSApplication {

    private static let log = Logger(subsystem: "com.developerinsider.AppBox", category: "MenuHandler")

    // MARK: - AppBox

    func checkForUpdateTapped(_ sender: NSMenuItem?) {
        UpdateHandler.isNewVersionAvailable { available, url in
            if available {
                if url == nil && UpdateHandler.isInstalledViaHomebrew() {
                    UpdateHandler.showHomebrewUpdateAlert()
                } else {
                    UpdateHandler.showUpdateAlert(withUpdateURL: url)
                }
            } else {
                UpdateHandler.showAlreadyUptoDateAlert()
            }
        }
    }


    // MARK: - Dropbox account (refresh identity + space usage into UserData; surfaced in the Accounts pane)

    public func updateAccountsMenu() {
        DropboxTransport.shared.currentAccount { email, displayName, _ in
            DispatchQueue.main.async {
                if let email {
                    UserData.setLoggedInUserEmail(email)
                    UserData.setLoggedInUserDisplayName(displayName)
                }
            }
        }

        DropboxTransport.shared.spaceUsage { usedMB, allocatedMB, error in
            DispatchQueue.main.async {
                guard error == nil else { return }
                UserData.setDropboxUsedSpace(NSNumber(value: usedMB))
                UserData.setDropboxAvailableSpace(NSNumber(value: allocatedMB))
                Self.log.info("DropBox Used Space : \(usedMB)MB")
                Self.log.info("DropBox Available Space : \(allocatedMB)MB")

                if (allocatedMB - usedMB) < 150 {
                    _ = Common.showAlert(withTitle: "Warning",
                                         andMessage: "You're running out of Dropbox space\n\n \(usedMB)MB of \(allocatedMB)MB used.")
                }
            }
        }
    }

    // MARK: - Help

    func helpButtonTapped(_ sender: NSMenuItem?) {
        if let url = URL(string: "https://docs.getappbox.com") { NSWorkspace.shared.open(url) }
    }

    func releaseNotesTapped(_ sender: NSMenuItem?) {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        if let url = URL(string: "https://github.com/getappbox/AppBox-iOSAppsWirelessInstallation/releases/tag/\(version)") {
            NSWorkspace.shared.open(url)
        }
    }

    func licenseTapped(_ sender: NSMenuItem?) {
        if let url = URL(string: "https://github.com/getappbox/AppBox-iOSAppsWirelessInstallation/blob/master/LICENSE.md") {
            NSWorkspace.shared.open(url)
        }
    }
}
