//
//  Common.swift
//  AppBox

import Foundation
import AppKit
import UserNotifications
import Security
import os
import AppBoxCore

public final class Common: NSObject {

    private static let log = Logger(subsystem: "com.developerinsider.AppBox", category: "Common")

    public class func generateUUID() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            log.error("Error generating random bytes (status \(status, privacy: .public)).")
            return UUID().uuidString
        }
        return Data(bytes).base64EncodedString().replacingOccurrences(of: "/", with: "")
    }

    public class func getFileDirectory(forFilePath filePath: URL?) -> URL? {
        guard let filePath else { return nil }
        let components = (filePath.relativePath as NSString).pathComponents
        guard !components.isEmpty else { return nil }
        let directory = NSString.path(withComponents: Array(components.dropLast()))
        guard let encoded = directory.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return nil
        }
        return URL(string: encoded)
    }

    public class func error(withDesc desc: String?, andCode code: Int) -> NSError {
        var userInfo: [String: Any]? = nil
        if let desc { userInfo = [NSLocalizedDescriptionKey: desc] }
        return NSError(domain: NSCocoaErrorDomain, code: code, userInfo: userInfo)
    }

    // MARK: - Notifications


    @discardableResult
    public class func showAlert(withTitle title: String?, andMessage message: String?) -> Int {
        log.info("ALERT - Title: \(title ?? "", privacy: .public) Message: \(message ?? "", privacy: .public)")
        let alert = NSAlert()
        alert.messageText = title ?? "Error"
        alert.informativeText = message ?? ""
        alert.alertStyle = .warning
        return alert.runModal().rawValue
    }

    public class func showUploadNotification(withName name: String, andURL url: URL) {
        let content = UNMutableNotificationContent()
        content.title = "\(name) Uploaded."
        content.body = "Share URL - \(url.absoluteString)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                log.error("Failed to schedule notification: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

}
