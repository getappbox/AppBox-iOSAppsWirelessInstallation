//
//  UploadSettings.swift
//  AppBoxCore
//

import Foundation

/// The preferences an upload needs, injected so Core doesn't reach into the GUI's defaults.
public struct UploadSettings: Equatable, Sendable {
    /// Default chunk size
    public static let defaultChunkSizeMB = 100
    /// Dropbox upload chunk size, in megabytes.
    public var chunkSizeMB: Int
    /// Include the raw IPA link on the install page.
    public var includeIPALink: Bool
    /// Include the expanded build details on the install page.
    public var includeDetails: Bool
    /// Keep earlier versions listed in `appinfo.json`.
    public var keepPreviousVersions: Bool

    public init(chunkSizeMB: Int = UploadSettings.defaultChunkSizeMB,
                includeIPALink: Bool = false,
                includeDetails: Bool = false,
                keepPreviousVersions: Bool = true) {
        self.chunkSizeMB = chunkSizeMB
        self.includeIPALink = includeIPALink
        self.includeDetails = includeDetails
        self.keepPreviousVersions = keepPreviousVersions
    }

    public var chunkSizeBytes: Int { chunkSizeMB * 1024 * 1024 }
}

/// The share destinations an upload should fan out to once the build is live.
public struct BuildShareOptions: Equatable, Sendable {
    public var emails: [String]
    public var personalMessage: String?
    public var slackWebhook: String?
    public var msTeamsWebhook: String?

    public init(emails: [String] = [], personalMessage: String? = nil,
                slackWebhook: String? = nil, msTeamsWebhook: String? = nil) {
        self.emails = emails
        self.personalMessage = personalMessage
        self.slackWebhook = slackWebhook
        self.msTeamsWebhook = msTeamsWebhook
    }

    public var hasEmailRecipients: Bool { !emails.isEmpty }
}
