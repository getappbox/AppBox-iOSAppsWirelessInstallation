//
//  ThirdPartyPreferencesViewController.swift
//  AppBox

import AppKit
import AppBoxCore
import os

public final class ThirdPartyPreferencesViewController: NSViewController {

    private static let log = Logger(subsystem: "com.developerinsider.AppBox", category: "ThirdPartyPreferences")
    private var model: ThirdPartyModel?

    public override func loadView() {
        let model = ThirdPartyModel(
			slackWebhook: UserData.userSlackChannel(),
			teamsWebhook: UserData.userMicrosoftTeamWebHook())
        self.model = model
        model.onSave = { [weak self] in self?.saveTapped() }
        model.onTestSlack = { [weak self] in self?.testSlackTapped() }
        model.onTestTeams = { [weak self] in self?.testTeamsTapped() }
        model.onSetupWebhook = {
            if let url = URL(string: "https://my.slack.com/apps/new/A0F7XDUAZ-incoming-webhooks") {
                NSWorkspace.shared.open(url)
            }
        }
        view = ThirdPartyPreferencesHost.makeView(model: model)
    }

    // MARK: - Actions (invoked by the SwiftUI form's callbacks)

    private func isValidWebHookURL(_ urlString: String, name: String, allowEmpty: Bool = false) -> Bool {
        let decoded = urlString.removingPercentEncoding ?? urlString
        if decoded.isEmpty {
            if allowEmpty { return true }
            Common.showAlert(withTitle: "Error", andMessage: "Please enter a \(name) WebHook URL.")
            return false
        }
        if URL(string: decoded) == nil {
            Common.showAlert(withTitle: "Error", andMessage: "Please enter a valid \(name) WebHook URL.")
            return false
        }
        return true
    }

    private func saveTapped() {
        guard let model else { return }
        let slack = model.slackWebhookText
        let teams = model.teamsWebhookText
        guard isValidWebHookURL(slack, name: "Slack", allowEmpty: true),
              isValidWebHookURL(teams, name: "Microsoft Team", allowEmpty: true) else { return }
        UserData.setUserSlackChannel(slack)
        UserData.setUserMicrosoftTeamWebHook(teams)
        Common.showAlert(withTitle: "Saved", andMessage: "Integration settings saved.")
    }

	private func testSlackTapped() {
		guard let model else { return }
		let webhook = model.slackWebhookText
		guard isValidWebHookURL(webhook, name: "Slack") else { return }
		guard requireDropboxSession() else { return }
		model.setTestingSlack(true)
		SlackClient.sendMessage(
			demoIPAUploadInfo(),
			webhook: webhook.removingPercentEncoding ?? webhook) { [weak self] success in
				DispatchQueue.main.async {
					self?.model?.setTestingSlack(false)
					self?.finishWebhookTest(success, service: "Slack")
				}
			}
	}

    private func testTeamsTapped() {
        guard let model else { return }
        let webhook = model.teamsWebhookText
        guard isValidWebHookURL(webhook, name: "Microsoft Team") else { return }
        guard requireDropboxSession() else { return }
        model.setTestingTeams(true)
        MSTeamsClient.sendMessage(
			demoIPAUploadInfo(),
			webhook: webhook.removingPercentEncoding ?? webhook) { [weak self] success in
				DispatchQueue.main.async {
					self?.model?.setTestingTeams(false)
					self?.finishWebhookTest(success, service: "Microsoft Teams")
				}
			}
    }

    private func finishWebhookTest(_ success: Bool, service: String) {
        if success {
            Common.showAlert(
				withTitle: "Message Sent",
				andMessage: "A test message was sent to \(service).")
        } else {
            Self.log.error("\(service, privacy: .public) test webhook failed.")
            Common.showAlert(
				withTitle: "\(service) Test Failed",
				andMessage: "Couldn't send a test message to \(service). Please check the webhook URL.")
        }
    }

    /// Test notifications go through the backend, which authenticates the caller by their Dropbox session — so a test needs a connected account (previously the send was direct from the app).
    private func requireDropboxSession() -> Bool {
        guard DropboxSession.isAuthorized else {
            Common.showAlert(
				withTitle: "Connect Dropbox",
				andMessage: "Connect your Dropbox account first to send a test notification.")
            return false
        }
        return true
    }

    private func demoIPAUploadInfo() -> IPAUploadInfo {
        let info = IPAUploadInfo()
        info.name = "TestApp"
        info.version = "1.0"
        info.build = "1"
        info.appShortShareableURL = URL(string: "https://getappbox.com")
        return info
    }
}
