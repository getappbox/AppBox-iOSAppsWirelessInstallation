//
//  MSTeamsClient.swift
//  AppBox

import Foundation
import AppBoxCore
import os

public final class MSTeamsClient: NSObject {

    private static let log = Logger(subsystem: "com.developerinsider.AppBox", category: "MSTeamsClient")

    public class func sendMessage(_ ipaUploadInfo: IPAUploadInfo, webhook: String?,
                                  completion: @escaping (Bool) -> Void) {
        guard WebhookURL.isValid(webhook), let webhook else {
            log.error("MS Teams Error - Invalid webhook URL: \(webhook ?? "", privacy: .public)")
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
                try await AppServices.serviceClient.sendNotification(service: .teams, webhookURL: webhook, text: finalMessage)
                log.info("Microsoft Teams message sent")
                await MainActor.run { completion(true) }
            } catch {
                log.info("Microsoft Teams Error - \(error.localizedDescription, privacy: .public)")
                await MainActor.run { completion(false) }
            }
        }
    }
}
