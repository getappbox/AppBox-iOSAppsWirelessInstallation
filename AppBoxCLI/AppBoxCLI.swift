//
//  ParsableLaunchArguments.swift
//  AppBoxCLI
//
//  Created by Vineet Choudhary on 06/09/25.
//  Copyright © 2025 Developer Insider. All rights reserved.
//

import Foundation
import ArgumentParser

struct AppBoxCLI: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "appboxcli",
		abstract: "AppBox is a tool for iOS developers to deploy Development, Ad-Hoc, and In-house (Enterprise) applications directly to the devices from your Dropbox account."
	)

	@Option(
		name: .customLong("ipa"),
		help: .init(
			"[Required] \nIPA file path in local file system\n",
			valueName: "ipa path"))
	var ipaPath: String

	@Option(
		name: .customLong("emails"),
		help: .init(
			"[Optional] \nComma-separated list of email address that should receive application installation link.\n",
			valueName: "emails"))
	var emails: String?

	@Option(
		name: .customLong("message"),
		help: .init(
			"[Optional] \nAttach personal message in the email. \nSupported Keywords: {BUILD_NAME}, {BUILD_VERSION}, and {BUILD_NUMBER}\n",
			valueName: "email message"))
	var message: String?

	@Flag(
		name: .customLong("keepsamelink"),
		help: "[Optional] \nKeep same short URL for all future IPA uploaded with same bundle identifier.\n")
	var keepSameLink = false

	@Option(
		name: .customLong("dbfolder"),
		help: .init(
			"[Optional] \nCustom Dropbox Folder Name. By default folder name will be the application bundle identifier.\n",
			valueName: "dropbox folder"))
	var dropboxFolder: String?

	@Option(
		name: .customLong("webhookmessage"),
		help: .init(
			"[Optional] \nCustom message to send along with Slack or Microsoft Teams notification. \nSupported Keywords: {BUILD_NAME}, {BUILD_VERSION}, {BUILD_NUMBER}, {SHARE_URL}\n",
			valueName: "webhook message"))
	var webhookMessage: String?

	@Option(
		name: .customLong("slackwebhook"),
		help: .init(
			"[Optional] \nSlack Incoming Webhook URL to send notification to a Slack channel.\n",
			valueName: "slack webhook"))
	var slackWebhook: String?

	@Option(
		name: .customLong("msteamswebhook"),
		help: .init(
			"[Optional] \nMicrosoft Teams Incoming Webhook URL to send notification to a Teams channel.\n",
			valueName: "msteams webhook"))
	var msTeamsWebhook: String?

	mutating func run() {
		startAppBox()
	}
}

extension AppBoxCLI {
	private func startAppBox() {
		let appBoxPath = "/Applications/AppBox.app/Contents/MacOS/AppBox"
		guard FileManager.default.fileExists(atPath: appBoxPath) else {
			print("\nAppBox is not installed in /Applications folder. AppBox must be installed at /Applications/AppBox.app to use the AppBox CLI tool.")
			Foundation.exit(1)
		}

		let task = Process()
		task.launchPath = appBoxPath
		task.arguments = buildArguments()
		captureStandardOutput(task: task)

		do {
			try task.run()
			task.waitUntilExit()
			Foundation.exit(task.terminationStatus)
		} catch {
			print("Failed to start AppBox: \(error)")
			Foundation.exit(1)
		}
	}

	private func buildArguments() -> [String] {
		var arguments = [String]()
		
		arguments.append("ipa=\(ipaPath)")

		if let emails, !emails.isEmpty {
			arguments.append("emails=\(emails)")
		}
		
		if let message, !message.isEmpty {
			arguments.append("message=\(message)")
		}
		
		if let dropboxFolder, !dropboxFolder.isEmpty {
			arguments.append("dbfolder=\(dropboxFolder)")
		}

		if keepSameLink {
			arguments.append("keepsamelink=1")
		}

		if let webhookMessage, !webhookMessage.isEmpty {
			arguments.append("webhookmessage=\(webhookMessage)")
		}

		if let slackWebhook, !slackWebhook.isEmpty {
			arguments.append("slackwebhook=\(slackWebhook)")
		}

		if let msTeamsWebhook, !msTeamsWebhook.isEmpty {
			arguments.append("msteamswebhook=\(msTeamsWebhook)")
		}

		return arguments
	}

	private func captureStandardOutput(task: Process) {
		let pipe = Pipe()
		task.standardOutput = pipe
		task.standardError = pipe
		pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()

		NotificationCenter.default.addObserver(
			forName: .NSFileHandleDataAvailable,
			object: pipe.fileHandleForReading,
			queue: nil) { _ in
				let data = pipe.fileHandleForReading.availableData
				if let output = String(data: data, encoding: .utf8), !output.isEmpty {
					print(output.trimmingCharacters(in: .whitespacesAndNewlines))
				}
				pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
			}
	}
}
