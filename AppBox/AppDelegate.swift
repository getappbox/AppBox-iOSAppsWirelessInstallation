//
//  AppDelegate.swift
//  AppBox

import AppKit
import os
import UserNotifications
import AppBoxCore

public final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    private static let log = Logger(subsystem: "com.developerinsider.AppBox", category: "AppDelegate")

    var processing = false
    var isReadyToUpload = false

    private let connectivityLock = NSLock()
    private var _isInternetConnected = false
    var isInternetConnected: Bool {
        get { connectivityLock.lock(); defer { connectivityLock.unlock() }; return _isInternetConnected }
        set { connectivityLock.lock(); defer { connectivityLock.unlock() }; _isInternetConnected = newValue }
    }

    private var openFileObserver: NSObjectProtocol?

    public private(set) static var appDelegate: AppDelegate!

    public override init() {
        super.init()
        AppDelegate.appDelegate = self
    }

    // MARK: - Lifecycle

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(self,
            andSelector: #selector(handleGetURL(withEvent:andReply:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL))
        Self.log.info("AppBox Started.")

        UploadManager.setupDBClientsManager()

        Task { await AppServices.appKeyProvider.refresh(using: AppServices.serviceClient) }

        NotificationCenter.default.addObserver(self, selector: #selector(handleDropboxLoggedOut(_:)),
                                               name: Notification.Name("DropBoxLoggedOutNotification"), object: nil)

        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error { Self.log.error("Notification authorization error: \(error.localizedDescription)") }
        }

        DefaultSettings.setFirstTimeSettings()
        DefaultSettings.setEveryStartupSettings()

        WebhookSecrets.shared.migrateFromUserDefaultsIfNeeded()

        UpdateHandler.isNewVersionAvailable { available, url in
            if available && !UserData.updateAlertEnable() {
                if url == nil && UpdateHandler.isInstalledViaHomebrew() {
                    UpdateHandler.showHomebrewUpdateAlert()
                } else {
                    UpdateHandler.showUpdateAlert(withUpdateURL: url)
                }
            }
        }

    }

    public func applicationWillTerminate(_ notification: Notification) {
        Self.log.info("AppBox Terminated.")
        if let openFileObserver { NotificationCenter.default.removeObserver(openFileObserver) }
        openFileObserver = nil
        saveCoreDataChanges()
        deleteTemporaryFiles()
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    public func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        if processing { return true }
        openFile(withPath: filename)
        return true
    }

    func openFile(withPath filePath: String) {
        if isReadyToUpload {
            NotificationCenter.default.post(name: Notification.Name("UseOpenFilesNotification"), object: filePath)
        } else {
            if let openFileObserver { NotificationCenter.default.removeObserver(openFileObserver) }
            openFileObserver = NotificationCenter.default.addObserver(
                forName: Notification.Name("AppBoxReadyToBuildNotification"), object: nil, queue: .main) { _ in
                NotificationCenter.default.post(name: Notification.Name("UseOpenFilesNotification"), object: filePath)
            }
        }
    }

    // MARK: - Helpers

    @objc private func handleDropboxLoggedOut(_ notification: Notification) {
        guard DropboxSession.isAuthorized else { return }
        DropboxSession.signOut()
        UserData.setDropboxUsedSpace(0)
        UserData.setDropboxAvailableSpace(0)
        UserData.setLoggedInUserEmail("")
        UserData.setLoggedInUserDisplayName("")
        NSApp.updateAccountsMenu()
    }

    @objc private func handleGetURL(withEvent event: NSAppleEventDescriptor, andReply reply: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              !urlString.isEmpty else {
            Self.log.warning("Received empty URL event")
            return
        }
        guard let url = URL(string: urlString) else {
            Self.log.warning("Failed to parse URL: \(urlString)")
            return
        }
        Self.log.info("Handling URL = \(url)")

        _ = DropboxSession.handleRedirect(url) { success, errorMessage in
            if success {
                Self.log.info("Success! User is logged into Dropbox.")
                NotificationCenter.default.post(name: Notification.Name("DropBoxLoggedInNotification"), object: nil)
            } else {
                Self.log.info("Dropbox authorization failed/cancelled: \(errorMessage ?? "")")
                _ = Common.showAlert(withTitle: "Authorization Canceled.", andMessage: "")
            }
        }
    }

    // MARK: - UNUserNotificationCenter delegate

    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        center.removeDeliveredNotifications(withIdentifiers: [response.notification.request.identifier])
        completionHandler()
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner, .sound])
    }

    // MARK: - Core Data stack (forwards to AppBoxCore's CoreDataStack)

    var managedObjectContext: NSManagedObjectContext? {
        do {
            return try CoreDataStack.shared.loadViewContext()
        } catch {
            NSApplication.shared.presentError(error)
            return nil
        }
    }

    func saveCoreDataChanges() {
        if managedObjectContext?.commitEditing() == false {
            Self.log.info("unable to commit editing before saving")
        }
        do { try CoreDataStack.shared.saveChanges() }
        catch { NSApplication.shared.presentError(error) }
    }

    public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let context = CoreDataStack.shared.existingViewContext else { return .terminateNow }
        if !context.commitEditing() {
            Self.log.info("unable to commit editing to terminate")
            return .terminateCancel
        }
        if !context.hasChanges { return .terminateNow }

        do {
            try context.save()
        } catch {
            if sender.presentError(error) { return .terminateCancel }
            let alert = NSAlert()
            alert.messageText = "Could not save changes while quitting. Quit anyway?"
            alert.informativeText = "Quitting now will lose any changes you have made since the last successful save"
            alert.addButton(withTitle: "Quit anyway")
            alert.addButton(withTitle: "Cancel")
            if alert.runModal() == .alertSecondButtonReturn { return .terminateCancel }
        }
        return .terminateNow
    }

    // MARK: - Temp cleanup

    private func deleteTemporaryFiles() {
        let root = ABStorePaths.temporaryDirectoryURL
        guard FileManager.default.fileExists(atPath: root.path) else { return }
        do {
            try FileManager.default.removeItem(at: root)
        } catch {
            Self.log.error("Failed to clear the AppBox temporary directory: \(error.localizedDescription)")
        }
    }
}
