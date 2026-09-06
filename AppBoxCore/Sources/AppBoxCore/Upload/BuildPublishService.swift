//
//  BuildPublishService.swift
//  AppBoxCore
//

import CoreData
import Foundation
import os

/// The share steps that ran after a build went live, and whether each succeeded.
public struct BuildShareReport {
    public var emailSent: Bool?
    public var slackSent: Bool?
    public var teamsSent: Bool?
    public var recordSaveError: Error?
}

/// Uploads a build, records it in the shared dashboard store, and fans out the email and webhook notifications — the whole "publish a build" flow behind one call.
public final class BuildPublishService {

    private static let log = Logger(subsystem: "com.developerinsider.AppBox.core", category: "Publish")

    private let stack: CoreDataStack
    private let providerFactory: (UploadSettings) -> StorageProvider
    private let serviceClient: AppBoxServiceClient?

    /// Inject a stack, provider factory and backend client (tests pass a temp store and fakes).
    public init(
		stack: CoreDataStack,
		providerFactory: @escaping (UploadSettings) -> StorageProvider,
		serviceClient: AppBoxServiceClient? = nil) {
			self.stack = stack
			self.providerFactory = providerFactory
			self.serviceClient = serviceClient
		}

    /// The CLI wiring: the real store opened read-write plus a Dropbox provider on the CLI's authorized client.
    public convenience init(appKey: String, serviceClient: AppBoxServiceClient?) {
        self.init(stack: CoreDataStack(), providerFactory: { settings in
            CLIDropboxClient.ensureConfigured(appKey: appKey)
            return DropboxSession.makeProvider(chunkSizeBytes: settings.chunkSizeBytes)
        }, serviceClient: serviceClient)
    }

    /// Runs the upload, saves the dashboard record, then sends the configured notifications.
    public func publish(_ request: BuildUploadRequest,
                        progress: ProgressReporter = NullProgressReporter()) async throws
    -> (outcome: BuildUploadOutcome, share: BuildShareReport) {
        let service = BuildUploadService(provider: providerFactory(request.settings),
                                         progress: progress,
                                         shortLinkService: serviceClient)
        let outcome = try await service.run(request)

        var recordSaveError: Error?
        do {
            try saveRecord(for: outcome, request: request)
        } catch {
            recordSaveError = error
            Self.log.error("The build uploaded but its dashboard record could not be saved: \(error.localizedDescription, privacy: .public)")
        }

        var share = await sendNotifications(for: outcome, options: request.share)
        share.recordSaveError = recordSaveError
        return (outcome, share)
    }

    private func saveRecord(for outcome: BuildUploadOutcome, request: BuildUploadRequest) throws {
        let context = try stack.loadViewContext()
        let input = BuildRecordInput(outcome: outcome,
                                     localIPAPath: request.ipaURL.path,
                                     keepSameLink: request.keepSameLink)
        try context.performAndWait {
            try BuildRecordStore.save(input, in: context) { try stack.saveChanges() }
        }
    }

    private func sendNotifications(for outcome: BuildUploadOutcome,
                                   options: BuildShareOptions) async -> BuildShareReport {
        var report = BuildShareReport()
        guard let serviceClient else { return report }

        let installURL = outcome.result.shortLink

        if options.hasEmailRecipients {
            let personal = options.personalMessage
            let request = BuildEmailRequest(name: outcome.metadata.name,
                                            version: outcome.metadata.version,
                                            build: outcome.metadata.build,
                                            to: options.emails,
                                            installURL: installURL,
                                            personalMessage: personal)
            report.emailSent = await succeeded { try await serviceClient.sendBuildEmail(request) }
        }

        let text = BuildNotificationMessage.text(name: outcome.metadata.name,
                                                 version: outcome.metadata.version,
                                                 build: outcome.metadata.build,
                                                 installURL: installURL.absoluteString)
        if let slack = options.slackWebhook, !slack.isEmpty {
            report.slackSent = await succeeded {
                try await serviceClient.sendNotification(service: .slack, webhookURL: slack, text: text)
            }
        }
        if let teams = options.msTeamsWebhook, !teams.isEmpty {
            report.teamsSent = await succeeded {
                try await serviceClient.sendNotification(service: .teams, webhookURL: teams, text: text)
            }
        }
        return report
    }

    private func succeeded(_ work: () async throws -> Void) async -> Bool {
        do {
            try await work()
            return true
        } catch {
            return false
        }
    }
}
