import CoreData
import Foundation

/// One row of AppBox upload history, as plain values.
public struct BuildHistoryEntry: Equatable {
    public let appName: String?
    public let bundleIdentifier: String?
    public let version: String?
    public let build: String?
    public let buildType: String?
    public let teamName: String?
    public let datetime: Date?
    public let shortURL: String?
    public let link: BuildLinkSettings

    init(record: ABUploadRecord) {
        appName = record.project?.name
        bundleIdentifier = record.project?.bundleIdentifier
        version = record.version
        build = record.build
        buildType = record.provisioningProfile?.buildType
        teamName = record.provisioningProfile?.teamName
        datetime = record.datetime
        shortURL = record.shortURL
        link = record.linkSettings
    }
}

/// Reads the AppBox upload history from the shared Core Data store.
public final class BuildHistoryStore {

    private let stack: CoreDataStack

    /// Inject a stack (tests use a temp store + the programmatic model).
    public init(stack: CoreDataStack) {
        self.stack = stack
    }

    /// The real on-disk store, opened read-only (the CLI default).
    public convenience init() {
        self.init(stack: CoreDataStack.readOnlyOnRealStore())
    }

    /// Upload records, newest first (matches the Dashboard's `datetime` descending sort).
    public func recentBuilds() throws -> [BuildHistoryEntry] {
        let context = try stack.loadViewContext()
        return try context.performAndWait {
            let request = NSFetchRequest<ABUploadRecord>(entityName: "UploadRecord")
            request.sortDescriptors = [NSSortDescriptor(key: "datetime", ascending: false)]
            return try context.fetch(request).map(BuildHistoryEntry.init)
        }
    }

    /// The link settings of the newest upload of `bundleIdentifier`, or nil when that app was never uploaded.
    public func latestLink(forBundleIdentifier bundleIdentifier: String) throws -> BuildLinkSettings? {
        let context = try stack.loadViewContext()
        return try context.performAndWait {
            let request = NSFetchRequest<ABUploadRecord>(entityName: "UploadRecord")
            request.predicate = NSPredicate(format: "project.bundleIdentifier == %@", bundleIdentifier)
            request.sortDescriptors = [NSSortDescriptor(key: "datetime", ascending: false)]
            request.fetchLimit = 1
            return try context.fetch(request).first?.linkSettings
        }
    }
}
