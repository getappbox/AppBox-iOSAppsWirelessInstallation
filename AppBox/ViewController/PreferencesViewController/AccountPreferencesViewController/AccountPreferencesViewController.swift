//
//  AccountPreferencesViewController.swift
//  AppBox

import AppKit
import AppBoxCore

public final class AccountPreferencesViewController: NSViewController {

    private var model: AccountsModel?

    public override func loadView() {
        let model = AccountsModel()
        self.model = model
		model.onConnect = { [weak self] in
			self?.connectDropbox()
		}
		model.onDisconnect = { [weak self] in
			self?.disconnectDropbox()
		}
        view = AccountsHost.makeView(model: model)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
			self,
			selector: #selector(refreshAccount),
			name: Notification.Name("DropBoxLoggedInNotification"),
			object: nil)
        NotificationCenter.default.addObserver(
			self,
			selector: #selector(refreshAccount),
			name: Notification.Name("DropBoxLoggedOutNotification"),
			object: nil)
    }

    public override func viewWillAppear() {
        super.viewWillAppear()
        refreshAccount()
    }

    // MARK: - Account data
    private func pushModel() {
        DispatchQueue.main.async { [weak self] in
            self?.applyModel()
        }
    }

    private func applyModel() {
        model?.update(
			connected: DropboxSession.isAuthorized,
			displayName: UserData.loggedInUserDisplayName(),
			email: UserData.loggedInUserEmail(),
			usedSpaceMB: UserData.dropboxUsedSpace().intValue,
			totalSpaceMB: UserData.dropboxAvailableSpace().intValue)
    }

    @objc private func refreshAccount() {
        pushModel()
        guard DropboxSession.isAuthorized else { return }

        DropboxTransport.shared.currentAccount { [weak self] email, displayName, _ in
            DispatchQueue.main.async {
                if let email {
                    UserData.setLoggedInUserEmail(email)
                    UserData.setLoggedInUserDisplayName(displayName)
                }
                self?.pushModel()
            }
        }
        DropboxTransport.shared.spaceUsage { [weak self] usedMB, allocatedMB, error in
            DispatchQueue.main.async {
                if error == nil {
                    UserData.setDropboxUsedSpace(NSNumber(value: usedMB))
                    UserData.setDropboxAvailableSpace(NSNumber(value: allocatedMB))
                }
                self?.pushModel()
            }
        }
    }

    // MARK: - Actions (invoked by the SwiftUI view's callbacks)

    private func connectDropbox() {
        presentAsSheet(DropboxViewController())
    }

    private func disconnectDropbox() {
        NotificationCenter.default.post(name: Notification.Name("DropBoxLoggedOutNotification"), object: self)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
