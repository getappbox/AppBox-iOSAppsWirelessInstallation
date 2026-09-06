//
//  SlackClient.swift
//  AppBox

import Foundation
import AppBoxCore
import os

public final class SlackClient: NSObject {

    private static let log = Logger(subsystem: "com.developerinsider.AppBox", category: "SlackClient")

    public class func sendMessage(_ ipaUploadInfo: IPAUploadInfo, webhook: String?,
                                  completion: @escaping (Bool) -> Void) {
        guard WebhookURL.isValid(webhook), let webhook else {
            log.error("Slack Error - Invalid webhook URL: \(webhook ?? "", privacy: .public)")
            completion(false)
            return
        }

        let finalMessage = BuildNotificationMessage.text(
			name: ipaUploadInfo.name ?? "",
			version: ipaUploadInfo.version ?? "",
			build: ipaUploadInfo.build ?? "",
			installURL: ipaUploadInfo.appShortShareableURL?.absoluteString ?? "")

        Task {
            do {
                try await AppServices.serviceClient.sendNotification(service: .slack, webhookURL: webhook, text: finalMessage)
                log.info("Slack message sent")
                await MainActor.run { completion(true) }
            } catch {
                log.info("Slack Error - \(error.localizedDescription, privacy: .public)")
                await MainActor.run { completion(false) }
            }
        }
    }
}
