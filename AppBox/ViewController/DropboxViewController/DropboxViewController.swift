//
//  DropboxViewController.swift
//  AppBox

import AppKit
import AppBoxCore

public final class DropboxViewController: NSViewController {

    public override func loadView() {
        let quitTitle = UserData.isLoggedIn() ? "Cancel" : "Quit"
        view = DropboxLoginHost.makeView(
			quitTitle: quitTitle,
			onConnect: { [weak self] in
				self?.connectDropbox()
			},
			onQuit: { [weak self] in
				self?.quitTapped()
			})
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
			self,
			selector: #selector(handleLoggedInNotification(_:)),
			name: Notification.Name("DropBoxLoggedInNotification"),
			object: nil)
    }

    private func connectDropbox() {
        DropboxLogin.present(from: self)
    }

    private func quitTapped() {
        dismiss(self)
        if !UserData.isLoggedIn() {
            NSApp.terminate(self)
        }
    }

    @objc private func handleLoggedInNotification(_ notification: Notification) {
        NSApp.updateAccountsMenu()
        dismiss(self)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
