//
//  CLISupportHelper.swift
//  AppBox

import Foundation
import AppKit

public final class CLISupportHelper: NSObject {

    private static let cliPath = "/usr/local/bin/appboxcli"
    private static let cliHelpURL = "https://docs.getappbox.com/CommandLineInterface/"

    /// The CLI binary shipped inside the app bundle that the /usr/local/bin symlink points to.
    private static var toolPath: String {
        guard let support = Bundle.main.sharedSupportPath else { return "" }
        return (support as NSString).appendingPathComponent("appboxcli")
    }

    @discardableResult
    public class func install() -> Bool {
        switch installSymlink() {
        case .cancelled:
            return false
        case .failed(let reason):
            showFailure(installing: true, reason: reason)
            return false
        case .succeeded:
            break
        }
        UserData.setCLIVersion(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)
        let alert = NSAlert()
        alert.messageText = "Success"
        alert.informativeText = "AppBox CLI tool installed successfully.\n\nYou can use it from terminal using the command \"appboxcli\"."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Learn More")
        if alert.runModal() == .alertSecondButtonReturn, let url = URL(string: cliHelpURL) {
            NSWorkspace.shared.open(url)
        }
        return true
    }

    @discardableResult
    public class func uninstall() -> Bool {
        let alert = NSAlert()
        alert.messageText = "Are you sure?"
        alert.informativeText = "Do you want to uninstall AppBox CLI tool?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        guard alert.runModal() == .alertFirstButtonReturn else { return false }
        switch uninstallSymlink() {
        case .succeeded:
            UserData.setCLIVersion(nil)
            Common.showAlert(withTitle: "Success", andMessage: "AppBox CLI tool uninstalled successfully.")
            return true
        case .cancelled:
            return false
        case .failed(let reason):
            showFailure(installing: false, reason: reason)
            return false
        }
    }

    @discardableResult
    public class func installPromptAfterLogin() -> Bool {
        let alert = NSAlert()
        alert.messageText = "Install CLI Tool"
        alert.informativeText = "Do you want to install AppBox CLI tool to use AppBox from terminal?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Install")
        alert.addButton(withTitle: "Not Now")
        if alert.runModal() == .alertFirstButtonReturn {
            return install()
        }
        let later = NSAlert()
        later.messageText = "You can install AppBox CLI tool later from the \"CLI\" menu bar option."
        later.alertStyle = .informational
        later.addButton(withTitle: "OK")
        later.runModal()
        return false
    }

    @discardableResult
    public class func updatePromptAfterVersionUpdate() -> Bool {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let cliVersion = UserData.cliVersion()
        if appVersion == cliVersion || cliVersion.isEmpty { return false }
        guard FileManager.default.fileExists(atPath: cliPath) else { return false }

        let alert = NSAlert()
        alert.messageText = "Update CLI Tool"
        alert.informativeText = "A newer version of AppBox CLI tool is available. You must update it to use with the latest version of AppBox."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Update")
        alert.addButton(withTitle: "Uninstall")
        if alert.runModal() == .alertFirstButtonReturn {
            switch installSymlink() {
            case .succeeded:
                UserData.setCLIVersion(appVersion)
                Common.showAlert(withTitle: "Success", andMessage: "AppBox CLI tool updated successfully.")
                return true
            case .cancelled:
                return false
            case .failed(let reason):
                showFailure(installing: true, reason: reason)
                return false
            }
        }
        return uninstall()
    }

    // MARK: - Symlink management

    /// The outcome of an install or uninstall attempt, including an explicit user-cancelled case.
    private enum SymlinkOutcome {
        case succeeded
        case cancelled
        case failed(String)
    }

    private static var installDirectory: String { (cliPath as NSString).deletingLastPathComponent }

    /// Links the CLI as the user, escalating behind the system authentication prompt when the destination isn't writable.
    private class func installSymlink() -> SymlinkOutcome {
        if createSymlink() { return .succeeded }
        let command = "/bin/mkdir -p \(shellQuoted(installDirectory))"
            + " && /bin/ln -sfn \(shellQuoted(toolPath)) \(shellQuoted(cliPath))"
        return runPrivileged(command)
    }

    /// Removes the link as the user, escalating behind the system authentication prompt when the destination isn't writable.
    private class func uninstallSymlink() -> SymlinkOutcome {
        if removeSymlink() { return .succeeded }
        return runPrivileged("/bin/rm -f \(shellQuoted(cliPath))")
    }

    /// Runs one shell command as root; macOS presents its own administrator password prompt.
    private class func runPrivileged(_ command: String) -> SymlinkOutcome {
        let source = "do shell script \"\(appleScriptEscaped(command))\" with administrator privileges"
        guard let script = NSAppleScript(source: source) else {
            return .failed("AppBox couldn't prepare the installation command.")
        }
        var errorInfo: NSDictionary?
        script.executeAndReturnError(&errorInfo)
        guard let errorInfo else { return .succeeded }
        if errorInfo[NSAppleScript.errorNumber] as? Int == userCancelledErrorNumber { return .cancelled }
        return .failed(errorInfo[NSAppleScript.errorMessage] as? String ?? "Unknown error.")
    }

    /// `errAEWaitCanceled` — returned when the user dismisses the authentication prompt.
    private static let userCancelledErrorNumber = -128

    class func shellQuoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    class func appleScriptEscaped(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private class func createSymlink() -> Bool {
        let fm = FileManager.default
        if !fm.fileExists(atPath: installDirectory) {
            do { try fm.createDirectory(atPath: installDirectory, withIntermediateDirectories: true) }
            catch { return false }
        }
        try? fm.removeItem(atPath: cliPath)
        do {
            try fm.createSymbolicLink(atPath: cliPath, withDestinationPath: toolPath)
            return true
        } catch { return false }
    }

    private class func removeSymlink() -> Bool {
        do {
            try FileManager.default.removeItem(atPath: cliPath)
            return true
        } catch let error as NSError {
            return error.domain == NSCocoaErrorDomain && error.code == NSFileNoSuchFileError
        }
    }

    private class func showFailure(installing: Bool, reason: String) {
        let alert = NSAlert()
        alert.messageText = installing ? "Couldn't install the CLI tool" : "Couldn't uninstall the CLI tool"
        alert.informativeText = "AppBox couldn't \(installing ? "write to" : "remove the link from") \(installDirectory).\n\n\(reason)"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
