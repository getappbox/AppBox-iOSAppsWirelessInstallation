import CoreData
import Foundation

/// Deletes a build from the CLI — the write counterpart to `BuildHistoryStore`, and the CLI's path into the Core `DeleteCoordinator`.
public final class BuildDeletionService {

    private let stack: CoreDataStack
    private let providerFactory: () -> StorageProvider
    /// The fetched records, held so `delete(at:)` operates on the same objects/context `loadBuilds()` returned.
    private var records: [ABUploadRecord] = []

    /// Inject a stack + provider factory (tests pass a temp store + a fake provider).
    public init(stack: CoreDataStack, providerFactory: @escaping () -> StorageProvider) {
        self.stack = stack
        self.providerFactory = providerFactory
    }

    /// The CLI wiring: the real store opened read-write + a Dropbox provider on the CLI's authorized client.
    public convenience init(appKey: String) {
        self.init(stack: CoreDataStack(), providerFactory: {
            CLIDropboxClient.ensureConfigured(appKey: appKey)
            return DropboxSession.makeProvider()
        })
    }

    /// Upload records newest-first (matches the Dashboard / `list`), held for a subsequent `delete(at:)`.
    @discardableResult
    public func loadBuilds() throws -> [BuildHistoryEntry] {
        let context = try stack.loadViewContext()
        return try context.performAndWait {
            let request = NSFetchRequest<ABUploadRecord>(entityName: "UploadRecord")
            request.sortDescriptors = [NSSortDescriptor(key: "datetime", ascending: false)]
            records = try context.fetch(request)
            return records.map(BuildHistoryEntry.init)
        }
    }

    /// Delete the build at `index` (into the last `loadBuilds()` result).
    public func delete(at index: Int, fromDropbox: Bool) async throws {
        guard records.indices.contains(index) else {
            throw NSError(domain: "com.developerinsider.AppBox", code: 9998, userInfo: [
                NSLocalizedDescriptionKey: "No build at that position. List the builds again."])
        }
        let record = records[index]
        let context = try stack.loadViewContext()

        if fromDropbox {
            let workingDirectory = try makeWorkingDirectory()
			defer {
				try? FileManager.default.removeItem(at: workingDirectory)
			}
            let plan: DeletePlan = try context.performAndWait {
                let keepSameLink = record.keepSameLink?.boolValue ?? false
                let appInfoPath = record.dbAppInfoFullPath ?? ""
                let appFolder = record.dbFolderName ?? ""
                let buildFolder = record.dbDirectroy ?? ""
                let requiredPaths = keepSameLink ? [appInfoPath, appFolder] : [buildFolder]
                guard requiredPaths.allSatisfy({ !$0.isEmpty }) else {
                    throw NSError(domain: "com.developerinsider.AppBox", code: 9997, userInfo: [
                        NSLocalizedDescriptionKey: "This record is missing its Dropbox location. Use --dashboard-only to remove it from the dashboard."])
                }
                return DeletePlan(
                    keepSameLink: keepSameLink,
                    appInfoRemotePath: RemotePath(path: appInfoPath),
                    manifestLinkToRemove: record.dbSharedManifestURL ?? "",
                    appFolderPath: RemotePath(path: appFolder),
                    buildFolderPath: RemotePath(path: buildFolder),
                    workingDirectory: workingDirectory)
            }
            _ = try await DeleteCoordinator(provider: providerFactory()).run(plan)
        }

        try context.performAndWait {
            context.delete(record)
            try stack.saveChanges()
        }
        records.remove(at: index)
    }

    private func makeWorkingDirectory() throws -> URL {
        try ABStorePaths.makeTemporaryWorkingDirectory(prefix: "delete-")
    }
}
