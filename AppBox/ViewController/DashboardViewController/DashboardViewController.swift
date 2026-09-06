//
//  DashboardViewController.swift
//  AppBox

import AppKit
import AppBoxCore

public final class DashboardViewController: NSViewController {

    private var uploadRecords: [ABUploadRecord] = []
    private var uploadManager: UploadManager?
    private var model: DashboardModel?

    public override func loadView() {
        let model = DashboardModel()
        self.model = model
		model.onCopyURL = { [weak self] index in
			self?.copyURL(at: index)
		}
		model.onOpenURL = { [weak self] index in
			self?.openURL(at: index)
		}
		model.onShowQR = { [weak self] index in
			self?.showQRCode(at: index)
		}
		model.onProvisioning = { [weak self] index in
			self?.showProvisioningDetails(at: index)
		}
		model.onShowInFinder = { [weak self] index in
			self?.showInFinder(at: index)
		}
		model.onShowInDropbox = { [weak self] index in
			self?.showInDropbox(at: index)
		}
		model.onDelete = { [weak self] index in
			self?.deleteBuild(at: index)
		}

        let host = DashboardHost.makeView(model: model)
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 940, height: 600))
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
        setupUploadManager()
    }

    public override func viewWillAppear() {
        super.viewWillAppear()
        loadData()
        NotificationCenter.default.addObserver(
			self,
			selector: #selector(loadData),
			name: .NSManagedObjectContextObjectsDidChange,
			object: nil)
    }

    public override func viewDidDisappear() {
        super.viewDidDisappear()
        NotificationCenter.default.removeObserver(
			self,
			name: .NSManagedObjectContextObjectsDidChange,
			object: nil)
    }

    private func setupUploadManager() {
        let manager = UploadManager()
        manager.currentViewController = self
        uploadManager = manager
        manager.completionBlock = { [weak self, weak manager] in
            guard let self else { return }
            ABHudViewController.hideAllHud(fromView: self.view, after: 0)
            if let record = manager?.uploadRecord {
                AppDelegate.appDelegate.managedObjectContext?.delete(record)
            }
            AppDelegate.appDelegate.saveCoreDataChanges()
            self.loadData()
        }
        manager.errorBlock = { [weak self] _, _ in
            guard let self else { return }
            ABHudViewController.hideAllHud(fromView: self.view, after: 0)
        }
    }

    public func revealBuild(shortURL: String) {
        loadData()
        model?.requestSelection(shortURL: shortURL)
    }

    @objc private func loadData() {
        let fetch = NSFetchRequest<ABUploadRecord>(entityName: "UploadRecord")
        fetch.sortDescriptors = [NSSortDescriptor(key: "datetime", ascending: false)]
        do {
            uploadRecords = try AppDelegate.appDelegate.managedObjectContext?.fetch(fetch) ?? []
        } catch {
            _ = Common.showAlert(withTitle: "Error", andMessage: error.localizedDescription)
            uploadRecords = []
        }
        let rows = uploadRecords.enumerated().map { buildRow(from: $0.element, index: $0.offset) }
        model?.setBuilds(rows)
    }

    // MARK: - Row mapping

    private func buildRow(from record: ABUploadRecord, index: Int) -> BuildRow {
        let name = record.project?.name ?? "N/A"
        let bundleId = record.project?.bundleIdentifier ?? "N/A"
        let version = record.version ?? "N/A"
        let build = record.build ?? "N/A"
        let versionBuild = "\(version) (\(build))"
        let shortURL = record.shortURL ?? "N/A"
        let date = (record.datetime as NSDate?)?.string ?? "N/A"
        let buildType = record.provisioningProfile?.buildType?.capitalized ?? "N/A"
        let team: String
        if let teamId = record.provisioningProfile?.teamId, let teamName = record.provisioningProfile?.teamName {
            team = "\(teamId) - \(teamName)"
        } else {
            team = "N/A"
        }
        return BuildRow(
			recordIndex: index,
			name: name,
			bundleId: bundleId,
			versionBuild: versionBuild,
			shortURL: shortURL,
			date: date,
			buildType: buildType,
			team: team)
    }

    private func record(at index: Int) -> ABUploadRecord? {
        guard index >= 0, index < uploadRecords.count else { return nil }
        return uploadRecords[index]
    }

    // MARK: - Build actions

    private func copyURL(at index: Int) {
        guard let record = record(at: index), let shortURL = record.shortURL else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(shortURL, forType: .string)
        ABHudViewController.showOnlyStatus("Copied!!", onView: view)
    }

    private func openURL(at index: Int) {
		guard let record = record(at: index), let shortURL = record.shortURL, let url = URL(string: shortURL) else {
			return
		}
        NSWorkspace.shared.open(url)
    }

    private func showQRCode(at index: Int) {
		guard let record = record(at: index) else {
			return
		}
        let qr = QRCodeViewController()
        qr.uploadRecord = record
        presentAsSheet(qr)
    }

    private func showProvisioningDetails(at index: Int) {
		guard let record = record(at: index) else {
			return
		}
        if record.provisioningProfile != nil {
            let vc = ProvisioningDetailsViewController()
            vc.uploadRecord = record
            presentAsSheet(vc)
        } else {
            _ = Common.showAlert(
				withTitle: "Information",
				andMessage: "Provisioning profiles details not available for this build.")
        }
    }

    private func showInFinder(at index: Int) {
		guard let record = record(at: index), let localBuildPath = record.localBuildPath else {
			return
		}
        if FileManager.default.fileExists(atPath: localBuildPath) {
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: localBuildPath)])
        } else {
            _ = Common.showAlert(withTitle: "Error", andMessage: "File not found.")
        }
    }

    private func showInDropbox(at index: Int) {
        guard let record = record(at: index) else { return }
        let base = "https://www.dropbox.com/home/Apps/AppBox%20-%20Build%2C%20Test%20and%20Distribute%20iOS%20Apps"
        if let url = URL(string: "\(base)\(record.dbDirectroy ?? "")") {
            NSWorkspace.shared.open(url)
        }
    }

    private func deleteBuild(at index: Int) {
        guard let record = record(at: index) else { return }
        let alert = NSAlert()
        alert.messageText = "Are you sure you want to delete this build?"
        alert.informativeText = "You're about to delete \"\(record.project?.name ?? "")-\(record.version ?? "")(\(record.build ?? ""))\". This is permanent!"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Delete from Dropbox and Dashboard")
        alert.addButton(withTitle: "Delete only from Dashboard")
        alert.addButton(withTitle: "Cancel")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            uploadManager?.uploadRecord = record
            uploadManager?.ipaUploadInfo = record.ipaUploadInfo
            uploadManager?.deleteBuildFromDropboxAndDashboard()
        case .alertSecondButtonReturn:
            uploadManager?.uploadRecord = record
            uploadManager?.ipaUploadInfo = record.ipaUploadInfo
            uploadManager?.deleteBuildFromDashboard()
        default:
            break
        }
    }
}
