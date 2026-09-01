import Foundation

/// Inputs for one upload, precomputed by the caller (provider-agnostic — no Dropbox/SDK types).
public struct UploadPlan {
    /// The extracted `.ipa` on disk.
    public var ipaLocalURL: URL
    /// A writable per-upload directory for the generated `manifest.plist` / `appinfo.json`.
    public var workingDirectory: URL

    public var ipaRemotePath: RemotePath
    public var manifestRemotePath: RemotePath
    public var appInfoRemotePath: RemotePath

    public var name: String
    public var version: String
    public var build: String
    public var identifier: String

    /// The version-entry inputs.
    public var entryInput: AppVersionInput

    /// Reuse one app-wide `appinfo.json` (and keep history) vs.
    public var keepSameLink: Bool
    /// Keep older versions in the history, or reset to just this build.
    public var keepPreviousVersions: Bool

    public init(ipaLocalURL: URL, workingDirectory: URL,
                ipaRemotePath: RemotePath, manifestRemotePath: RemotePath, appInfoRemotePath: RemotePath,
                name: String, version: String, build: String, identifier: String,
                entryInput: AppVersionInput, keepSameLink: Bool, keepPreviousVersions: Bool) {
        self.ipaLocalURL = ipaLocalURL
        self.workingDirectory = workingDirectory
        self.ipaRemotePath = ipaRemotePath
        self.manifestRemotePath = manifestRemotePath
        self.appInfoRemotePath = appInfoRemotePath
        self.name = name
        self.version = version
        self.build = build
        self.identifier = identifier
        self.entryInput = entryInput
        self.keepSameLink = keepSameLink
        self.keepPreviousVersions = keepPreviousVersions
    }
}

/// The shareable links produced by a successful upload.
public struct UploadResult: Equatable, Sendable {
    public var ipaLink: URL
    public var manifestLink: URL
    /// The Dropbox shared link for `appinfo.json` (the canonical file location).
    public var appInfoSharedLink: URL
    /// The AppBox install-page URL (`web.getappbox.com?url=…`) that the short link resolves to — the fallback shown to the user when the shortener is unavailable.
    public var installLink: URL
    /// The `appbox.me/xxxx` short link, or `installLink` when the shortener was unavailable.
    public var shortLink: URL
}

/// Coordinator failures that aren't provider `StorageError`s.
public enum UploadCoordinatorError: Error {
    case manifestCreationFailed(underlying: Error)
}

/// The on-disk / uploaded `appinfo.json` (the per-app "unique link" file).
struct AppInfoFile: Codable, Equatable {
    var latestVersion: AppVersionEntry?
    var versions: [AppVersionEntry]
    var uniqueLinkShared: String?
    var uniqueLinkShort: String?

    init(latestVersion: AppVersionEntry? = nil, versions: [AppVersionEntry] = [],
         uniqueLinkShared: String? = nil, uniqueLinkShort: String? = nil) {
        self.latestVersion = latestVersion
        self.versions = versions
        self.uniqueLinkShared = uniqueLinkShared
        self.uniqueLinkShort = uniqueLinkShort
    }
}

extension AppInfoFile {
    /// Tolerant decoding: legacy / hand-edited `appinfo.json` files may lack `versions` entirely (the ObjC reader used plain NSDictionary lookups and shrugged).
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        latestVersion = try container.decodeIfPresent(AppVersionEntry.self, forKey: .latestVersion)
        versions = try container.decodeIfPresent([AppVersionEntry].self, forKey: .versions) ?? []
        uniqueLinkShared = try container.decodeIfPresent(String.self, forKey: .uniqueLinkShared)
        uniqueLinkShort = try container.decodeIfPresent(String.self, forKey: .uniqueLinkShort)
    }
}

/// The upload happy-path state machine.
public final class UploadCoordinator {

    public static let appInfoFilename = "appinfo.json"
    public static let manifestFilename = "manifest.plist"

    private let provider: StorageProvider
    private let progress: ProgressReporter
    private let dateProvider: DateProvider
    private let shortLinkService: ShortLinkService?
    private let retry: ConnectivityAwareRetry

    public init(provider: StorageProvider,
                progress: ProgressReporter = NullProgressReporter(),
                dateProvider: DateProvider = SystemDateProvider(),
                shortLinkService: ShortLinkService? = nil,
                maxRetries: Int = UploadRetryPolicy.maxRetryCount,
                reachability: Reachability? = nil,
                pollNanoseconds: UInt64 = 500_000_000) {
        self.provider = provider
        self.progress = progress
        self.dateProvider = dateProvider
        self.shortLinkService = shortLinkService
        self.retry = ConnectivityAwareRetry(maxRetries: maxRetries,
                                            reachability: reachability,
                                            pollNanoseconds: pollNanoseconds)
    }

    public func run(_ plan: UploadPlan) async throws -> UploadResult {
        progress.report(stage: .preparing, message: "Preparing…", fractionCompleted: nil)

        try await upload(plan.ipaLocalURL, to: plan.ipaRemotePath, message: "Uploading IPA", reportsProgress: true)
        let ipaLink = try await createLink(for: plan.ipaRemotePath, message: "Creating Sharable Link for IPA")

        let manifest = ManifestBuilder.make(ipaShareableURL: ipaLink.url.absoluteString,
                                            name: plan.name, identifier: plan.identifier, version: plan.version)
        let manifestURL = plan.workingDirectory.appendingPathComponent(Self.manifestFilename)
        do {
            try ManifestBuilder.plistData(for: manifest).write(to: manifestURL, options: .atomic)
        } catch {
            throw UploadCoordinatorError.manifestCreationFailed(underlying: error)
        }
        try await upload(manifestURL, to: plan.manifestRemotePath, message: "Uploading Manifest")
        let manifestLink = try await createLink(for: plan.manifestRemotePath, message: "Creating Sharable Link for Manifest")

        var entryInput = plan.entryInput
        entryInput.manifestLink = manifestLink.url.absoluteString
        entryInput.shareableIPALink = ipaLink.url.absoluteString
        entryInput.timestamp = dateProvider.now().timeIntervalSince1970
        let entry = AppInfoJSON.makeEntry(entryInput)

        var history: [AppVersionEntry] = []
        var appInfoRevision: String?
        if plan.keepSameLink {
            (history, appInfoRevision) = try await loadExistingHistory(plan)
        }
        let versions = AppInfoJSON.updatedHistory(history, adding: entry, keepPreviousVersions: plan.keepPreviousVersions)

        var file = AppInfoFile(latestVersion: entry, versions: versions)
        let appInfoURL = plan.workingDirectory.appendingPathComponent(Self.appInfoFilename)
        try write(file, to: appInfoURL)
        appInfoRevision = try await upload(appInfoURL, to: plan.appInfoRemotePath, message: "Uploading AppInfo",
                                           ifRevisionMatches: appInfoRevision)

        let appInfoShared = try await createLink(for: plan.appInfoRemotePath, message: "Creating Sharable Link for AppInfo")
        let installLink = InstallLink.make(fromDropboxShareURL: appInfoShared.url) ?? appInfoShared.url
        let shortURL = await shortenedLink(for: plan, shortenURL: appInfoShared.url, fallback: installLink)

        file.uniqueLinkShared = appInfoShared.url.absoluteString
        file.uniqueLinkShort = shortURL.absoluteString
        try write(file, to: appInfoURL)
        try await upload(appInfoURL, to: plan.appInfoRemotePath, message: "Uploading AppInfo",
                         ifRevisionMatches: appInfoRevision)

        progress.report(stage: .completed, message: "Finalising…", fractionCompleted: nil)
        return UploadResult(ipaLink: ipaLink.url, manifestLink: manifestLink.url,
                            appInfoSharedLink: appInfoShared.url, installLink: installLink, shortLink: shortURL)
    }

    // MARK: - Steps

    /// Returns the uploaded file's new revision (nil if the provider doesn't surface one), so a follow-up upload of the same file can be preconditioned on it.
    @discardableResult
    private func upload(_ localURL: URL, to remotePath: RemotePath, message: String,
                        reportsProgress: Bool = false, ifRevisionMatches precondition: String? = nil) async throws -> String? {
        progress.report(stage: .uploading, message: message, fractionCompleted: nil)
        return try await withRetry {
            let reporter: ((Double) -> Void)? = reportsProgress ? { fraction in
                self.progress.report(stage: .uploading, message: message, fractionCompleted: fraction)
            } : nil
            return try await self.provider.upload(fileAt: localURL, to: remotePath,
                                                  ifRevisionMatches: precondition, progress: reporter)
        }
    }

    private func createLink(for remotePath: RemotePath, message: String) async throws -> ShareableLink {
        progress.report(stage: .creatingLink, message: message, fractionCompleted: nil)
        return try await withRetry { try await self.provider.createShareableLink(for: remotePath) }
    }

    /// Shorten `shortenURL` (the Dropbox appinfo link the service knows how to wrap), returning the short link — or `fallback` (the install-page URL) when the shortener is unavailable.
    private func shortenedLink(for plan: UploadPlan, shortenURL: URL, fallback: URL) async -> URL {
        guard let service = shortLinkService else { return fallback }
        let request = ShortLinkRequest(name: plan.name, version: plan.version, build: plan.build,
                                       identifier: plan.identifier, longURL: shortenURL)
        return await service.shortLink(for: request) ?? fallback
    }

    /// The existing shared history plus the revision it was read at (the precondition for the re-upload).
    private func loadExistingHistory(_ plan: UploadPlan) async throws -> ([AppVersionEntry], String?) {
        let temp = plan.workingDirectory.appendingPathComponent("existing-\(Self.appInfoFilename)")
        let revision: String?
        do {
            revision = try await withRetry { try await self.provider.downloadWithRevision(from: plan.appInfoRemotePath, to: temp) }
        } catch StorageError.notFound {
            return ([], nil)
        }
        let data = try Data(contentsOf: temp)
        return ((try? JSONDecoder().decode(AppInfoFile.self, from: data).versions) ?? [], revision)
    }

    private func write(_ file: AppInfoFile, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        try encoder.encode(file).write(to: url, options: .atomic)
    }

    /// Retry a `StorageError` via `ConnectivityAwareRetry`: bounded retries while online, pause-then- resume while offline, fail otherwise.
    private func withRetry<T>(_ operation: () async throws -> T) async throws -> T {
        var attempts = 0
        while true {
            try Task.checkCancellation()
            do {
                return try await operation()
            } catch let error as StorageError {
                switch try await retry.evaluate(error, attempts: attempts) {
                case .retry(let counted): if counted { attempts += 1 }
                case .fail: throw error
                }
            }
        }
    }
}
