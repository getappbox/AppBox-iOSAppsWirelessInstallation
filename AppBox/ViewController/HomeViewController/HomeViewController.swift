//
//  HomeViewController.swift
//  AppBox

import AppKit
import Network
import os
import UniformTypeIdentifiers
import AppBoxCore

public final class HomeViewController: NSViewController, UploadAdvancedSettingViewDelegate {

    private static let log = Logger(subsystem: "com.developerinsider.AppBox", category: "Home")

    private var ipaUploadInfo = IPAUploadInfo()
    private var uploadManager: UploadManager?
    private var model: HomeModel?
    private var pathMonitor: NWPathMonitor?

    public override func loadView() {
        ipaUploadInfo = IPAUploadInfo()

        let model = HomeModel()
        self.model = model
        model.onChooseFile = { [weak self] in self?.chooseIPAFile() }
        model.onFileDropped = { path in AppDelegate.appDelegate.openFile(withPath: path) }
        model.onUpload = { [weak self] in self?.uploadTapped() }
        model.onAdvanced = { [weak self] in self?.advancedTapped() }
        model.onSameLinkHelp = {
			if let url = URL(string: "https://docs.getappbox.com/Features/keepsamelink/") {
				NSWorkspace.shared.open(url)
			}
        }

        let host = HomeHost.makeView(model: model)
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 780, height: 400))
        host.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(host)
        NSLayoutConstraint.activate([
            host.topAnchor.constraint(equalTo: container.topAnchor),
            host.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            host.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
        view = container
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        let center = NotificationCenter.default
        center.addObserver(
			self,
			selector: #selector(dropboxLogoutHandler(_:)),
			name: Notification.Name("DropBoxLoggedOutNotification"),
			object: nil)
        center.addObserver(
			self,
			selector: #selector(handleLoggedInNotification(_:)),
			name: Notification.Name("DropBoxLoggedInNotification"),
			object: nil)
        center.addObserver(
			self,
			selector: #selector(initOpenFilesProcess(_:)),
			name: Notification.Name("UseOpenFilesNotification"),
			object: nil)

        UploadManager.setupDBClientsManager()
        setupUploadManager()
        NSApp.updateAccountsMenu()

        let monitor = NWPathMonitor()
        pathMonitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let connected = (path.status == .satisfied)
            AppDelegate.appDelegate.isInternetConnected = connected
            if AppDelegate.appDelegate.processing {
                if !connected {
                    self.showStatus("Waiting for the Internet Connection.", showProgressBar: true, withProgress: -1)
                } else if let op = self.uploadManager?.lastfailedOperation {
                    op.start()
                    self.uploadManager?.lastfailedOperation = nil
                }
            }
        }
        monitor.start(queue: .main)
    }

    public override func viewWillAppear() {
        super.viewWillAppear()

        if !DropboxSession.isAuthorized {
            presentAsSheet(DropboxViewController())
        } else {
            DropboxTransport.shared.currentAccount { _, _, error in
                if DropboxTransport.isAuthError(error) {
                    NotificationCenter.default.post(name: Notification.Name("DropBoxLoggedOutNotification"), object: self)
                }
            }
        }
        AppDelegate.appDelegate.isReadyToUpload = true
        NotificationCenter.default.post(name: Notification.Name("AppBoxReadyToBuildNotification"), object: self)
    }

    public override func viewDidAppear() {
        super.viewDidAppear()
        CLISupportHelper.updatePromptAfterVersionUpdate()
    }

    // MARK: - Upload manager

    private func setupUploadManager() {
        let manager = UploadManager()
        manager.ipaUploadInfo = ipaUploadInfo
        manager.currentViewController = self
        uploadManager = manager

        manager.errorBlock = { [weak self] _, terminate in
            guard terminate else { return }
            self?.viewState(forProgressFinish: true)
        }

        manager.completionBlock = { [weak self] in
            guard let self else { return }
            self.showUploadCompleteNotification()
            self.shareURLOnSlackMSTeamChannel()
            self.shareURLOnEmail {
				DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                    self?.presentShareLink()
                }
            }
        }
    }

    // MARK: - Build Repo / Open Files notifications

    @objc private func initOpenFilesProcess(_ notification: Notification) {
        if let path = notification.object as? String, let fileURL = (path as NSString).ipaURL() {
            handleSelectedFileURL(fileURL)
        }
    }

    // MARK: - File selection

    private func chooseIPAFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "ipa") ?? .zip]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK, let url = panel.url {
            handleSelectedFileURL(url)
        }
    }

    private func handleSelectedFileURL(_ url: URL) {
        let fileURL = (url as NSURL).filePathURL ?? url
        if (fileURL as NSURL).isIPA() {
            viewState(forProgressFinish: true)
            ipaUploadInfo.ipaFullPath = fileURL
            model?.setFileName(fileURL.lastPathComponent)
            model?.emailsText = UserData.userEmail()
            model?.messageText = UserData.userMessage()
        }
    }

    // MARK: - Actions

    private func advancedTapped() {
        syncIPAUploadInfoFromModel()
        let advanced = UploadAdvancedSettingViewController()
        advanced.ipaUploadInfo = ipaUploadInfo
        advanced.delegate = self
        presentAsSheet(advanced)
    }

    private func syncIPAUploadInfoFromModel() {
        if let emails = model?.emailsText, !emails.isEmpty, MailHandler.isAllValidEmail(emails) {
            ipaUploadInfo.emails = emails
        }
        ipaUploadInfo.personalMessage = model?.messageText
        ipaUploadInfo.isKeepSameLinkEnabled = model?.keepSameLinkEnabled ?? false
    }

    private func uploadTapped() {
        let emails = (model?.emailsText ?? "").replacingOccurrences(of: " ", with: "")
        model?.emailsText = emails
        if !(emails.isEmpty || MailHandler.isAllValidEmail(emails)) {
            MailHandler.showInvalidEmailAddressAlert()
            return
        }
        if AppDelegate.appDelegate.processing {
            Self.log.info("A request already in progress.")
            return
        }

        syncIPAUploadInfoFromModel()
        AppDelegate.appDelegate.processing = true
        view.window?.makeFirstResponder(view)

        uploadManager?.uploadIPAFile(ipaUploadInfo.ipaFullPath ?? URL(fileURLWithPath: ""))
        viewState(forProgressFinish: !AppDelegate.appDelegate.processing)
    }

    // MARK: - Dropbox notifications

    @objc private func handleLoggedInNotification(_ notification: Notification) {
        viewState(forProgressFinish: true)
        promptCLIInstallIfNeeded()
    }

    @objc private func dropboxLogoutHandler(_ sender: Any?) {
        viewState(forProgressFinish: true)
        if !(presentedViewControllers?.contains(where: { $0 is DropboxViewController }) ?? false) {
            presentAsSheet(DropboxViewController())
        }
    }

    private func promptCLIInstallIfNeeded() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if !FileManager.default.fileExists(atPath: "/usr/local/bin/appboxcli") {
                CLISupportHelper.installPromptAfterLogin()
            }
        }
    }

    // MARK: - View state / HUD

    private func viewState(forProgressFinish finish: Bool) {
        AppDelegate.appDelegate.processing = !finish
        AppDelegate.appDelegate.isReadyToUpload = finish

        if finish {
            ipaUploadInfo = IPAUploadInfo()
            uploadManager?.ipaUploadInfo = ipaUploadInfo
            ABHudViewController.hud(for: view, hide: true)
            model?.setFileName(nil)
            model?.emailsText = ""
            model?.messageText = ""
            model?.keepSameLinkEnabled = false
        }
        model?.setProcessing(!finish)
    }

    private func showStatus(_ status: String, showProgressBar: Bool, withProgress progress: Double) {
        Self.log.info("\(status)")
        if progress == -1 {
			if showProgressBar {
				ABHudViewController.showStatus(status, onView: view)
			} else {
				ABHudViewController.showOnlyStatus(status, onView: view)
			}
        } else {
			if showProgressBar {
				ABHudViewController.showStatus(status, witProgress: progress, onView: view)
			} else {
				ABHudViewController.showOnlyStatus(status, onView: view)
			}
        }
    }

    // MARK: - UploadAdvancedSettingViewDelegate

    public func uploadAdvancedSettingSaveButtonTapped(_ sender: NSButton?) {}
    public func uploadAdvancedSettingCancelButtonTapped(_ sender: NSButton?) {}

    // MARK: - Share URL

    private func showUploadCompleteNotification() {
        guard let url = ipaUploadInfo.appShortShareableURL else { return }
        Common.showUploadNotification(withName: ipaUploadInfo.name ?? "", andURL: url)
    }

    private func shareURLOnSlackMSTeamChannel() {
        let slackWebhook = ipaUploadInfo.slackWebhook ?? UserData.userSlackChannel()
        if !slackWebhook.isEmpty {
            showStatus("Sending Message on Slack...", showProgressBar: true, withProgress: -1)
            SlackClient.sendMessage(ipaUploadInfo, webhook: slackWebhook) { _ in }
        }

        let msTeamWebhook = ipaUploadInfo.msTeamsWebhook ?? UserData.userMicrosoftTeamWebHook()
        if !msTeamWebhook.isEmpty {
            showStatus("Sending Message on Microsoft Team...", showProgressBar: true, withProgress: -1)
            MSTeamsClient.sendMessage(ipaUploadInfo, webhook: msTeamWebhook) { _ in }
        }
    }

    private func shareURLOnEmail(_ completion: @escaping () -> Void) {
        guard let emails = ipaUploadInfo.emails, !emails.isEmpty, MailHandler.isAllValidEmail(emails),
              let installURL = ipaUploadInfo.appShortShareableURL else {
            completion()
            return
        }
        showStatus("Sending Mail...", showProgressBar: true, withProgress: -1)

        let info = ipaUploadInfo
        let personalMessage = (info.personalMessage?.isEmpty == false) ? info.personalMessage : nil
        let request = BuildEmailRequest(
            name: info.name ?? "", version: info.version ?? "", build: info.build ?? "",
            to: emails.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty },
            installURL: installURL,
            personalMessage: personalMessage)

        Task { [weak self] in
            do {
                try await AppServices.serviceClient.sendBuildEmail(request)
                await MainActor.run {
                    guard let self else { return }
                    ABHudViewController.showStatus("Mail Sent", forSuccess: true, onView: self.view)
                    completion()
                }
            } catch {
                await MainActor.run {
                    guard let self else { return }
                    Self.log.error("Build-upload mail failed: \(error.localizedDescription)")
                    ABHudViewController.showStatus("Mail Failed", forSuccess: false, onView: self.view)
                    completion()
                }
            }
        }
    }

    private func presentShareLink() {
        let showLink = ShowLinkViewController()
        showLink.ipaUploadInfo = ipaUploadInfo
        viewState(forProgressFinish: true)
        presentAsSheet(showLink)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        pathMonitor?.cancel()
    }
}
