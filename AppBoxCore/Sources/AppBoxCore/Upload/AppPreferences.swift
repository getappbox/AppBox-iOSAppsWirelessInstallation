//
//  AppPreferences.swift
//  AppBoxCore
//

import Foundation

/// The install-page preferences the GUI stores, read from wherever the caller runs.
public enum AppPreferences {

    /// The GUI's preference domain.
    public static let suiteName = "com.developerinsider.AppBox"

    /// Keys exactly as the GUI writes them, including the misspelled IPA one.
    enum Key {
        static let chunkSize = "UploadChunkSize"
        static let downloadIPA = "DonwloadIPAEnable"
        static let moreDetails = "MoreDetailsEnable"
        static let showPreviousVersions = "ShowPreviousVersions"
    }

    /// What `DefaultSettings.setFirstTimeSettings()` assigns on the app's first launch.
    enum FirstRun {
        static let downloadIPA = false
        static let moreDetails = true
        static let showPreviousVersions = true
    }

    /// The app's preference domain, or `nil` if it cannot be opened.
    public static var appDefaults: UserDefaults? { UserDefaults(suiteName: suiteName) }

    /// The `UploadSettings` the GUI would use for the same upload, with any
    /// caller-supplied overrides applied on top.
    public static func uploadSettings(
		from defaults: UserDefaults? = appDefaults,
		applying overrides: UploadSettingsOverrides = .init()) -> UploadSettings {
			var settings = storedUploadSettings(from: defaults)
			if let value = overrides.chunkSizeMB { settings.chunkSizeMB = value }
			if let value = overrides.includeIPALink { settings.includeIPALink = value }
			if let value = overrides.includeDetails { settings.includeDetails = value }
			if let value = overrides.keepPreviousVersions { settings.keepPreviousVersions = value }
			return settings
		}

    /// The stored preferences alone, before any override.
    static func storedUploadSettings(from defaults: UserDefaults?) -> UploadSettings {
        guard let defaults else {
            return UploadSettings(
				includeIPALink: FirstRun.downloadIPA,
				includeDetails: FirstRun.moreDetails,
				keepPreviousVersions: FirstRun.showPreviousVersions)
        }

        func flag(_ key: String, unset fallback: Bool) -> Bool {
            defaults.object(forKey: key) == nil ? fallback : defaults.bool(forKey: key)
        }

        // Matches UserData.uploadChunkSize(): anything non-positive means "unset".
        let chunkSize = defaults.integer(forKey: Key.chunkSize)

        return UploadSettings(
            chunkSizeMB: chunkSize > 0 ? chunkSize : UploadSettings.defaultChunkSizeMB,
            includeIPALink: flag(Key.downloadIPA, unset: FirstRun.downloadIPA),
            includeDetails: flag(Key.moreDetails, unset: FirstRun.moreDetails),
            keepPreviousVersions: flag(Key.showPreviousVersions, unset: FirstRun.showPreviousVersions))
    }
}

/// Per-invocation overrides for the app's stored install-page preferences.
public struct UploadSettingsOverrides: Equatable, Sendable {
    public var chunkSizeMB: Int?
    public var includeIPALink: Bool?
    public var includeDetails: Bool?
    public var keepPreviousVersions: Bool?

    public init(
		chunkSizeMB: Int? = nil,
		includeIPALink: Bool? = nil,
		includeDetails: Bool? = nil,
		keepPreviousVersions: Bool? = nil) {
			self.chunkSizeMB = chunkSizeMB
			self.includeIPALink = includeIPALink
			self.includeDetails = includeDetails
			self.keepPreviousVersions = keepPreviousVersions
		}

    /// True when nothing was overridden, so the stored preferences apply as-is.
    public var isEmpty: Bool {
        chunkSizeMB == nil && includeIPALink == nil && includeDetails == nil && keepPreviousVersions == nil
    }
}
