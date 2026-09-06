//
//  UpdateHandler.swift
//  AppBox

import Foundation
import AppKit
import AppBoxCore
import os

public final class UpdateHandler: NSObject {

    private static let log = Logger(subsystem: "com.developerinsider.AppBox", category: "UpdateHandler")
    private static let gitHubLatestReleaseURL = "https://github.com/getappbox/AppBox-iOSAppsWirelessInstallation/releases/latest"

    private static var currentVersion: String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    public class func isInstalledViaHomebrew() -> Bool {
        return ABHomebrewDetector.isInstalledViaHomebrew()
    }

    public class func showHomebrewUpdateAlert() {
        let command = "brew upgrade --cask appbox"
        let alert = NSAlert()
        alert.messageText = "New Version Available"
        alert.informativeText = "A newer version of \"AppBox\" is available.\n\nSince you installed AppBox via Homebrew, please run this command in Terminal:"
        alert.alertStyle = .informational
        alert.accessoryView = commandTextField(command, width: 250)
        alert.addButton(withTitle: "Copy & Close")
        alert.addButton(withTitle: "Release Notes")
        alert.addButton(withTitle: "Close")
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(command, forType: .string)
        case .alertSecondButtonReturn:
            if let url = URL(string: gitHubLatestReleaseURL) { NSWorkspace.shared.open(url) }
        default: break
        }
    }

    public class func showUpdateAlert(withUpdateURL url: URL?) {
        let command = "curl -s https://getappbox.com/install.sh | bash"
        let alert = NSAlert()
        alert.messageText = "New Version Available"
        alert.informativeText = "A newer version of \"AppBox\" is available.\n\nTo update, run this command in Terminal:"
        alert.alertStyle = .informational
        alert.accessoryView = commandTextField(command, width: 400)
        alert.addButton(withTitle: "Copy & Close")
        alert.addButton(withTitle: "Release Notes")
        alert.addButton(withTitle: "Close")
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(command, forType: .string)
        case .alertSecondButtonReturn:
            if let releaseURL = URL(string: gitHubLatestReleaseURL) { NSWorkspace.shared.open(releaseURL) }
        default: break
        }
    }

    public class func showAlreadyUptoDateAlert() {
        let version = currentVersion ?? ""
        Common.showAlert(withTitle: "You\u{2019}re up-to-date!",
                         andMessage: "AppBox \(version) is currently the newest version available.")
    }

    /// Reports whether a newer version exists and, for direct (non-Homebrew) installs, the release URL.
    public class func isNewVersionAvailable(completion: @escaping (Bool, URL?) -> Void) {
        log.debug("Checking for new version...")
        let installedViaHomebrew = isInstalledViaHomebrew()
        let current = currentVersion
        Task {
            do {
                let latest = try await AppServices.serviceClient.fetchLatestVersion()
                if installedViaHomebrew {
                    let available = ABVersionCompare.isUpdateAvailable(latest: latest.homebrewVersion ?? latest.version,
                                                                       current: current)
                    await MainActor.run { completion(available, nil) }
                } else {
                    let available = ABVersionCompare.isUpdateAvailable(latest: latest.version, current: current)
                    await MainActor.run { completion(available, available ? latest.downloadURL : nil) }
                }
            } catch {
                log.info("Update check failed: \(error.localizedDescription, privacy: .public)")
                await MainActor.run { completion(false, nil) }
            }
        }
    }

    private class func commandTextField(_ command: String, width: CGFloat) -> NSView {
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: width, height: 20))
        textField.stringValue = command
        textField.isEditable = false
        textField.isSelectable = true
        textField.isBordered = true
        textField.bezelStyle = .roundedBezel
        textField.font = NSFont.monospacedSystemFont(ofSize: 12.0, weight: .medium)
        textField.backgroundColor = .controlBackgroundColor
        textField.alignment = .center
        return textField
    }
}
