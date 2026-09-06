//
//  AppBoxCLI.swift
//  AppBoxCLI
//
//  Created by Vineet Choudhary on 06/09/25.
//  Copyright © 2025 Developer Insider. All rights reserved.

import Foundation
import ArgumentParser
import AppBoxCore
import AppKit

/// The CLI's backend client, mirroring the GUI's `AppServices`.
enum AppBoxCLIServices {
	static let serviceClient = AppBoxServiceClient(
		configuration: .production(clientToken: AppBoxSecrets.clientToken),
		httpClient: URLSessionHTTPClient(),
		tokenProvider: DropboxSessionTokenProvider())
}

/// Root command.
@main
@available(macOS 10.15, *)
struct AppBoxCLI: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "appboxcli",
		abstract: "AppBox is a tool for iOS developers to deploy Development, Ad-Hoc, and In-house (Enterprise) applications directly to the devices from your Dropbox account.",
		subcommands: [Upload.self, Login.self, Logout.self, WhoAmI.self, Space.self, List.self, Delete.self],
		defaultSubcommand: Upload.self
	)
}

/// `appboxcli delete` — interactively delete a build from Dropbox and the dashboard (the GUI's "Delete from Dropbox and Dashboard"), or `--dashboard-only` to just drop the record.
struct Delete: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "delete",
		abstract: "Delete a build from Dropbox and your dashboard (interactive).")

	@Flag(name: .customLong("dashboard-only"),
		  help: "Remove the record from the dashboard only; leave the Dropbox files in place.")
	var dashboardOnly = false

	private static func appBoxIsRunning() -> Bool {
		!NSRunningApplication.runningApplications(withBundleIdentifier: "com.developerinsider.AppBox").isEmpty
	}

	func run() async throws {
		if Self.appBoxIsRunning() {
			print("AppBox is open. Quit AppBox before deleting from the CLI (both can't safely write the store).")
			throw ExitCode.failure
		}

		let service = BuildDeletionService(appKey: DropboxAppKey.value())
		let builds: [BuildHistoryEntry]
		do {
			builds = try service.loadBuilds()
		} catch {
			print("Error: \(error.localizedDescription)")
			throw ExitCode.failure
		}
		guard !builds.isEmpty else {
			print("No uploads to delete.")
			return
		}

		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
		for (i, b) in builds.enumerated() {
			let date = b.datetime.map { dateFormatter.string(from: $0) } ?? "—"
			let app = b.appName ?? b.bundleIdentifier ?? "—"
			print("[\(i + 1)] \(date)  \(app)  \(b.version ?? "—") (\(b.build ?? "—"))  \(b.shortURL ?? "—")")
		}

		print("\nEnter the number to delete (Return to cancel): ", terminator: "")
		fflush(stdout)
		guard let line = readLine(strippingNewline: true)?.trimmingCharacters(in: .whitespaces),
			  let choice = Int(line), choice >= 1, choice <= builds.count else {
			print("Cancelled.")
			return
		}
		let index = choice - 1
		let chosen = builds[index]
		let target = "\(chosen.appName ?? chosen.bundleIdentifier ?? "build") \(chosen.version ?? "")(\(chosen.build ?? ""))"
		let scope = dashboardOnly ? "the dashboard only" : "Dropbox and the dashboard"
		print("Delete \"\(target)\" from \(scope)? [y/N]: ", terminator: "")
		fflush(stdout)
		guard let confirm = readLine(strippingNewline: true)?.lowercased(), confirm == "y" || confirm == "yes" else {
			print("Cancelled.")
			return
		}

		if Self.appBoxIsRunning() {
			print("AppBox was opened while this prompt was waiting. Quit AppBox and run delete again.")
			throw ExitCode.failure
		}

		do {
			try await service.delete(at: index, fromDropbox: !dashboardOnly)
			print("\u{2713} Deleted.")
		} catch {
			print("Error: \(cliMessage(for: error))")
			throw ExitCode.failure
		}
	}
}

/// `appboxcli list` — prints the upload history (the GUI Dashboard's data) from the shared Core Data store via AppBoxCore's `BuildHistoryStore` (opened read-only, so it's safe alongside a running GUI).
struct List: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "list",
		abstract: "List your AppBox upload history (newest first).")

	func run() throws {
		let builds: [BuildHistoryEntry]
		do {
			builds = try BuildHistoryStore().recentBuilds()
		} catch {
			print("Error: \(error.localizedDescription)")
			throw ExitCode.failure
		}
		guard !builds.isEmpty else {
			print("No uploads yet.")
			return
		}
		printTable(builds)
	}

	private func printTable(_ builds: [BuildHistoryEntry]) {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

		var rows: [(date: String, app: String, version: String, type: String, link: String)] =
			[(date: "DATE", app: "APP", version: "VERSION", type: "TYPE", link: "LINK")]
		for b in builds {
			rows.append((
				date: b.datetime.map { dateFormatter.string(from: $0) } ?? "—",
				app: b.appName ?? b.bundleIdentifier ?? "—",
				version: "\(b.version ?? "—") (\(b.build ?? "—"))",
				type: b.buildType ?? "—",
				link: b.shortURL ?? "—"))
		}

		let wDate = rows.map { $0.date.count }.max() ?? 0
		let wApp = rows.map { $0.app.count }.max() ?? 0
		let wVersion = rows.map { $0.version.count }.max() ?? 0
		let wType = rows.map { $0.type.count }.max() ?? 0
		func pad(_ s: String, _ width: Int) -> String { s.padding(toLength: width, withPad: " ", startingAt: 0) }

		for row in rows {
			print("\(pad(row.date, wDate))  \(pad(row.app, wApp))  \(pad(row.version, wVersion))  \(pad(row.type, wType))  \(row.link)")
		}
	}
}

struct Upload: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "upload",
		abstract: "Upload an IPA and create an install link (default command)."
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
			"[Optional] \nAttach a personal message to the email, shown under \"Message from the developer\".\n",
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

	/// Retired in 4.0 — the notification text is generated. Still accepted so existing CI scripts don't fail on an unknown option.
	@Option(name: .customLong("webhookmessage"), help: .hidden)
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

	func run() async throws {
		try await publish()
	}
}

extension Upload {

	/// Streams each pipeline stage to stdout so a CI log shows the same progress the GUI HUD would.
	private final class PrintingProgressReporter: ProgressReporter {
		private var lastLine = ""

		func report(stage: UploadStage, message: String?, fractionCompleted: Double?) {
			var line = message ?? "Finalising…"
			if let fractionCompleted, fractionCompleted >= 0 {
				line += " (\(Int(fractionCompleted * 100))%)"
			}
			guard line != lastLine else { return }
			lastLine = line
			print(line)
			fflush(stdout)
		}
	}

	/// ArgumentParser calls this before `run()`; rejects bad input, matching the argument checks the GUI used to run.
	func validate() throws {
		if webhookMessage != nil {
			print("NOTE - --webhookmessage is no longer used; the notification text is generated from the build.")
		}
		if let emails, !emails.isEmpty, !EmailValidator.isAllValidEmails(emails) {
			print("ERROR - Invalid email address format in emails argument.")
			throw ExitCode(127)
		}
		if let slackWebhook, !slackWebhook.isEmpty, !WebhookURL.isValid(slackWebhook) {
			print("ERROR - Invalid Slack Webhook URL. Only https:// webhook URLs are supported.")
			throw ExitCode(127)
		}
		if let msTeamsWebhook, !msTeamsWebhook.isEmpty, !WebhookURL.isValid(msTeamsWebhook) {
			print("ERROR - Invalid Microsoft Teams Webhook URL. Only https:// webhook URLs are supported.")
			throw ExitCode(127)
		}
	}

	private func publish() async throws {
		let ipaURL = URL(fileURLWithPath: (ipaPath as NSString).expandingTildeInPath)
		let share = BuildShareOptions(
			emails: (emails ?? "").components(separatedBy: ",")
				.map { $0.trimmingCharacters(in: .whitespaces) }
				.filter { !$0.isEmpty },
			personalMessage: message,
			slackWebhook: slackWebhook,
			msTeamsWebhook: msTeamsWebhook)

		let request = BuildUploadRequest(
			ipaURL: ipaURL,
			settings: UploadSettings(),
			share: share,
			keepSameLink: keepSameLink,
			bundleDirectory: dropboxFolder.map { "/" + $0.replacingOccurrences(of: " ", with: "") })

		let service = BuildPublishService(appKey: DropboxAppKey.value(),
										  serviceClient: AppBoxCLIServices.serviceClient)
		do {
			let (outcome, report) = try await service.publish(request, progress: PrintingProgressReporter())
			ShareURLExport.write(shareURL: outcome.result.shortLink,
								 ipaURL: outcome.result.ipaLink,
								 manifestURL: outcome.result.manifestLink)
			print("SHARE URL - \(outcome.result.shortLink.absoluteString)")
			fflush(stdout)
			if let recordSaveError = report.recordSaveError {
				print("WARNING - the build is live but could not be added to your dashboard: \(recordSaveError.localizedDescription)")
			}
			if report.emailSent == false {
				print("WARNING - the build email could not be sent.")
			}
			if report.slackSent == false || report.teamsSent == false {
				print("WARNING - a webhook notification could not be sent.")
			}
			throw ExitCode(report.emailSent == false ? 111 : 0)
		} catch let error as BuildUploadError {
			print("ERROR - \(error.message)")
			throw ExitCode(error.exitCode)
		}
	}
}
