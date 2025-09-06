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
		abstract: "AppBox CLI is a command line tool to upload and distribute iOS applications using AppBox and Dropbox."
	)

	@Option(
		name: .customLong("ipa"),
		help: "IPA file path in local file system")
	var ipaPath: String

	@Option(
		name: .customLong("emails"),
		help: "Comma-separated list of email address that should receive application installation link.")
	var emails: String?

	@Option(
		name: .customLong("message"),
		help: "Attach personal message in the email. Supported Keywords: {PROJECT_NAME}, {BUILD_VERSION}, and {BUILD_NUMBER}")
	var message: String?

	@Option(
		name: .customLong("dbfolder"),
		help: "Custom Dropbox Folder Name. By default folder name will be the application bundle identifier.")
	var dropboxFolder: String?

	@Flag(
		name: .customLong("keepsamelink"),
		help: "Keep same short URL for all future IPA uploaded with same bundle identifier.")
	var keepSameLink = false

	mutating func run() {
		startAppBox()
	}
}

extension AppBoxCLI {
	private func startAppBox() {
		let appBoxPath = "/Applications/AppBox.app/Contents/MacOS/AppBox"
		guard FileManager.default.fileExists(atPath: appBoxPath) else {
			print("\nAppBox is not installed in /Applications folder. AppBox must be installed at /Applications/AppBox.app to use the AppBox CLI tool.")
			return
		}

		let task = Process()
		task.launchPath = appBoxPath
		task.arguments = buildArguments()
		captureStandardOutput(task: task)

		do {
			try task.run()
			task.waitUntilExit()
		} catch {
			print("Failed to start AppBox: \(error)")
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
