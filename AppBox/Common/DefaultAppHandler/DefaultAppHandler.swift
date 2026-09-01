//
//  DefaultAppHandler.swift
//  AppBox

import Foundation
import CoreServices
import os

public final class DefaultAppHandler: NSObject {

    /// Posted (on the main thread) when the default-.ipa-handler state may have changed.
    public static let didChangeNotificationName = "ABDefaultIPAHandlerDidChangeNotification"

    private static let log = Logger(subsystem: "com.developerinsider.AppBox", category: "DefaultAppHandler")
    private static let ipaContentType = "com.apple.itunes.ipa" as CFString

    public class func isDefaultIPAHandler() -> Bool {
        guard let bundleId = Bundle.main.bundleIdentifier else { return false }
        guard let handler = LSCopyDefaultRoleHandlerForContentType(ipaContentType, .all)?.takeRetainedValue() else {
            return false
        }
        return (handler as String) == bundleId
    }

    public class func setAsDefaultIPAHandler() {
        guard let bundleId = Bundle.main.bundleIdentifier else { return }
        let wasPreviouslyDefault = isDefaultIPAHandler()
        let status = LSSetDefaultRoleHandlerForContentType(ipaContentType, .all, bundleId as CFString)
        if status != noErr {
            log.error("Failed to set AppBox as default IPA handler (error \(status, privacy: .public)).")
        } else {
            log.info("AppBox set as default application for .ipa files.")
        }
        observeAppActivation(wasPreviouslyDefault: wasPreviouslyDefault)
    }

    public class func removeAsDefaultIPAHandler() {
        guard let appBoxBundleId = Bundle.main.bundleIdentifier else { return }
        let wasPreviouslyDefault = isDefaultIPAHandler()

        if let handlers = LSCopyAllRoleHandlersForContentType(ipaContentType, .all)?.takeRetainedValue() as? [String] {
            for handler in handlers where handler != appBoxBundleId {
                if LSSetDefaultRoleHandlerForContentType(ipaContentType, .all, handler as CFString) == noErr {
                    log.info("Default IPA handler change requested to: \(handler, privacy: .public)")
                    break
                }
            }
        } else {
            if LSSetDefaultRoleHandlerForContentType(ipaContentType, .all, "com.apple.archiveutility" as CFString) == noErr {
                log.info("Default IPA handler change requested to Archive Utility.")
            } else {
                log.error("Failed to remove AppBox as default IPA handler.")
            }
        }
        observeAppActivation(wasPreviouslyDefault: wasPreviouslyDefault)
    }

    // MARK: - Private

    /// After a change, macOS shows a confirmation popup we can't observe directly, so we wait then poll the real state (a 2s delay, then every 0.5s up to ~30s).
    private static func observeAppActivation(wasPreviouslyDefault: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let isNowDefault = isDefaultIPAHandler()
            post(isDefault: isNowDefault)

            var attempts = 0
            var lastKnownState = isNowDefault
            let timer = Timer(timeInterval: 0.5, repeats: true) { t in
                attempts += 1
                let currentState = isDefaultIPAHandler()
                if currentState != lastKnownState {
                    lastKnownState = currentState
                    post(isDefault: currentState)
                }
                if currentState != wasPreviouslyDefault || attempts >= 60 {
                    t.invalidate()
                    log.info("IPA handler state resolved: was=\(wasPreviouslyDefault, privacy: .public), now=\(currentState, privacy: .public) (attempts=\(attempts, privacy: .public))")
                }
            }
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private static func post(isDefault: Bool) {
        NotificationCenter.default.post(
			name: Notification.Name(didChangeNotificationName),
			object: nil,
			userInfo: ["isDefault": isDefault])
    }
}
