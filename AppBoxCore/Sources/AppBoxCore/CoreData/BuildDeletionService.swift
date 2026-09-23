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
                do {
                    return try DeletePlan(record: record, workingDirectory: workingDirectory)
                } catch is UnusableBuildLocationError {
                    throw NSError(domain: "com.developerinsider.AppBox", code: 9997, userInfo: [
                        NSLocalizedDescriptionKey: "This record is missing its Dropbox location. Use --dashboard-only to remove it from the dashboard."])
                }
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

extension DeletePlan {
    /// The delete for a stored build; throws `UnusableBuildLocationError` unless the folder it may remove is known and isn't the storage root.
	public init(record: ABUploadRecord, workingDirectory: URL) throws {
		let link = record.linkSettings
		let appInfoPath = RemotePath(path: record.dbAppInfoFullPath ?? "")
		let buildFolder = RemotePath(path: record.dbDirectroy ?? "")
		let hasLocation = link.keepSameLink
			? appInfoPath.components.last == UploadCoordinator.appInfoFilename && link.folder != nil
			: !buildFolder.components.isEmpty
		guard hasLocation else { throw UnusableBuildLocationError() }

		self.init(
			keepSameLink: link.keepSameLink,
			appInfoRemotePath: appInfoPath,
			manifestLinkToRemove: record.dbSharedManifestURL ?? "",
			appFolderPath: link.folder ?? RemotePath([]),
			buildFolderPath: buildFolder,
			workingDirectory: workingDirectory)
	}
}
