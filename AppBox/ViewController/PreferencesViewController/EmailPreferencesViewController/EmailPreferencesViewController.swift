//
//  EmailPreferencesViewController.swift
//  AppBox

import AppKit
import AppBoxCore
import os

public final class EmailPreferencesViewController: NSViewController {

    private static let log = Logger(subsystem: "com.developerinsider.AppBox", category: "EmailPreferences")
    private var model: EmailModel?

    public override func loadView() {
        let model = EmailModel(emails: UserData.userEmail(), message: UserData.userMessage())
        self.model = model
		model.onSave = { [weak self] in
			self?.saveTapped()
		}
		model.onSendTest = { [weak self] in
			self?.sendTestTapped()
		}
        view = EmailPreferencesHost.makeView(model: model)
    }

    // MARK: - Actions (invoked by the SwiftUI form's callbacks)

    private func isValidEmails(_ emails: String) -> Bool {
        if !emails.isEmpty, MailHandler.isAllValidEmail(emails) {
            return true
        }
        MailHandler.showInvalidEmailAddressAlert()
        return false
    }

    private func saveTapped() {
        guard let model else { return }
        let emails = model.emailsText
        let message = model.messageText
        let emailsEmpty = emails.trimmingCharacters(in: .whitespaces).isEmpty
        let messageEmpty = message.trimmingCharacters(in: .whitespaces).isEmpty
        if emailsEmpty && messageEmpty {
            UserData.setUserEmail(emails)
            UserData.setUserMessage(message)
            Common.showAlert(withTitle: "Saved", andMessage: "Email settings cleared.")
        } else if isValidEmails(emails) {
            UserData.setUserEmail(emails)
            UserData.setUserMessage(message)
            Common.showAlert(withTitle: "Saved", andMessage: "Email settings saved.")
        }
    }

    private func sendTestTapped() {
        guard let model else { return }
        let emails = model.emailsText
        let message = model.messageText
        guard isValidEmails(emails) else { return }
        guard DropboxSession.isAuthorized else {
            Common.showAlert(
				withTitle: "Connect Dropbox",
				andMessage: "Connect your Dropbox account first to send a test email.")
            return
        }

        var personalMessage: String?
        if !message.trimmingCharacters(in: .whitespaces).isEmpty {
            personalMessage = message
        }
        let request = BuildEmailRequest(
            name: "TestApp",
			version: "1.0",
			build: "1",
            to: emails.components(separatedBy: ",")
				.map { $0.trimmingCharacters(in: .whitespaces) }
				.filter { !$0.isEmpty },
            installURL: URL(string: "https://getappbox.com")!,
            personalMessage: personalMessage)

        model.setSendingTest(true)
        Task { [weak self] in
            do {
                try await AppServices.serviceClient.sendBuildEmail(request)
                await MainActor.run {
                    self?.model?.setSendingTest(false)
                    Common.showAlert(
						withTitle: "Mail Sent",
						andMessage: "The test email was sent successfully.")
                }
            } catch {
                await MainActor.run {
                    self?.model?.setSendingTest(false)
                    Self.log.error("Test mail failed: \(error.localizedDescription, privacy: .public)")
                    Common.showAlert(
						withTitle: "Mail Failed",
						andMessage: "Unable to send the test email. See the AppBox logs in Console.app for details.")
                }
            }
        }
    }
}
