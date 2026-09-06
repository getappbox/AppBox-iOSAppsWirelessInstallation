import Foundation

/// Inputs for deleting one build, precomputed by the caller (provider-agnostic — no Dropbox/SDK types).
public struct DeletePlan {
    /// Reuse one app-wide `appinfo.json` (remove just this version) vs.
    public var keepSameLink: Bool
    /// The shared app-level `appinfo.json` (only used when `keepSameLink`).
    public var appInfoRemotePath: RemotePath
    /// Identifies the version to remove: its `manifestLink` in `appinfo.json` (the record's shared manifest URL).
    public var manifestLinkToRemove: String
    /// The app's root folder — deleted when removing this version empties the history.
    public var appFolderPath: RemotePath
    /// This build's folder — deleted directly when `keepSameLink` is off.
    public var buildFolderPath: RemotePath
    /// A writable scratch directory for the downloaded/rewritten `appinfo.json`.
    public var workingDirectory: URL

    public init(keepSameLink: Bool, appInfoRemotePath: RemotePath, manifestLinkToRemove: String,
                appFolderPath: RemotePath, buildFolderPath: RemotePath, workingDirectory: URL) {
        self.keepSameLink = keepSameLink
        self.appInfoRemotePath = appInfoRemotePath
        self.manifestLinkToRemove = manifestLinkToRemove
        self.appFolderPath = appFolderPath
        self.buildFolderPath = buildFolderPath
        self.workingDirectory = workingDirectory
    }
}

/// What a delete did: removed a whole folder, or removed one version and re-uploaded `appinfo.json`.
public enum DeleteOutcome: Equatable {
    case deletedFolder(RemotePath)
    case updatedAppInfo
}

/// The delete state machine, the counterpart to `UploadCoordinator`.
public final class DeleteCoordinator {

    private let provider: StorageProvider
    private let progress: ProgressReporter
    private let retry: ConnectivityAwareRetry

    public init(provider: StorageProvider,
                progress: ProgressReporter = NullProgressReporter(),
                maxRetries: Int = UploadRetryPolicy.maxRetryCount,
                reachability: Reachability? = nil,
                pollNanoseconds: UInt64 = 500_000_000) {
        self.provider = provider
        self.progress = progress
        self.retry = ConnectivityAwareRetry(maxRetries: maxRetries,
                                            reachability: reachability,
                                            pollNanoseconds: pollNanoseconds)
    }

    public func run(_ plan: DeletePlan) async throws -> DeleteOutcome {
        progress.report(stage: .preparing, message: "Deleting…", fractionCompleted: nil)

        guard plan.keepSameLink else {
            try await delete(plan.buildFolderPath)
            progress.report(stage: .completed, message: nil, fractionCompleted: nil)
            return .deletedFolder(plan.buildFolderPath)
        }

        let appInfoURL = plan.workingDirectory.appendingPathComponent(UploadCoordinator.appInfoFilename)
        guard let (file, revision) = try await downloadAppInfo(from: plan.appInfoRemotePath, to: appInfoURL) else {
            progress.report(stage: .completed, message: nil, fractionCompleted: nil)
            return .updatedAppInfo
        }

        switch AppInfoJSON.removingVersion(withManifestLink: plan.manifestLinkToRemove,
                                           from: file.versions, latestVersion: file.latestVersion) {
        case .historyEmptied:
            try await delete(plan.appFolderPath)
            progress.report(stage: .completed, message: nil, fractionCompleted: nil)
            return .deletedFolder(plan.appFolderPath)
        case let .updated(versions, latestVersion):
            var updated = file
            updated.versions = versions
            updated.latestVersion = latestVersion
            try write(updated, to: appInfoURL)
            try await upload(appInfoURL, to: plan.appInfoRemotePath, ifRevisionMatches: revision)
            progress.report(stage: .completed, message: nil, fractionCompleted: nil)
            return .updatedAppInfo
        }
    }

    // MARK: - Steps

    private func delete(_ remotePath: RemotePath) async throws {
        progress.report(stage: .preparing, message: "Deleting…", fractionCompleted: nil)
        try await withRetry { try await self.provider.delete(at: remotePath) }
    }

    private func upload(_ localURL: URL, to remotePath: RemotePath, ifRevisionMatches precondition: String?) async throws {
        progress.report(stage: .uploading, message: "Updating app records", fractionCompleted: nil)
        try await withRetry {
            _ = try await self.provider.upload(fileAt: localURL, to: remotePath,
                                               ifRevisionMatches: precondition, progress: nil)
        }
    }

    /// Downloads + decodes the shared `appinfo.json` and the revision it was read at, or `nil` if the file no longer exists.
    private func downloadAppInfo(from remotePath: RemotePath, to localURL: URL) async throws -> (AppInfoFile, String?)? {
        progress.report(stage: .preparing, message: "Fetching app records", fractionCompleted: nil)
        let revision: String?
        do {
            revision = try await withRetry { try await self.provider.downloadWithRevision(from: remotePath, to: localURL) }
        } catch StorageError.notFound {
            return nil
        }
        let data = try Data(contentsOf: localURL)
        return (try JSONDecoder().decode(AppInfoFile.self, from: data), revision)
    }

    private func write(_ file: AppInfoFile, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        try encoder.encode(file).write(to: url, options: .atomic)
    }

    /// Retry a `StorageError` via `ConnectivityAwareRetry` (matches `UploadCoordinator`): bounded retries while online, pause-then-resume while offline, fail otherwise.
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
