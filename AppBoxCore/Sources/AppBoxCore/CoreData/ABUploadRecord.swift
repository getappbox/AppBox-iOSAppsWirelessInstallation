import CoreData
import Foundation

/// Core Data entity `UploadRecord` (model `AppBox4`).
@objc(ABUploadRecord)
public class ABUploadRecord: NSManagedObject {
    @NSManaged public var build: String?
    @NSManaged public var buildType: String?
    @NSManaged public var datetime: Date?
    @NSManaged public var dbAppInfoFullPath: String?
    @NSManaged public var dbDirectroy: String?
    @NSManaged public var dbFolderName: String?
    @NSManaged public var dbIPAFullPath: String?
    @NSManaged public var dbManifestFullPath: String?
    @NSManaged public var dbSharedAppInfoURL: String?
    @NSManaged public var dbSharedIPAURL: String?
    @NSManaged public var dbSharedManifestURL: String?
    @NSManaged public var keepSameLink: NSNumber?
    @NSManaged public var localBuildPath: String?
    @NSManaged public var mailURL: String?
    @NSManaged public var projectPath: String?
    @NSManaged public var shortURL: String?
    @NSManaged public var teamId: String?
    @NSManaged public var version: String?

    @NSManaged public var project: ABProject?
    @NSManaged public var provisioningProfile: ABProvisioningProfile?
    @NSManaged public var service: AppBoxService?
}

/// Whether a build kept its app's link, and the app-level folder it was uploaded into.
public struct BuildLinkSettings: Equatable, Sendable {
    public let keepSameLink: Bool
    public let folder: RemotePath?

    public init(keepSameLink: Bool, folder: RemotePath?) {
        self.keepSameLink = keepSameLink
        self.folder = folder
    }
}

extension ABUploadRecord {
    /// The link settings this build was uploaded with, read from the record's own attributes only.
    public var linkSettings: BuildLinkSettings {
        let keepSameLink = self.keepSameLink?.boolValue ?? false
        return BuildLinkSettings(
            keepSameLink: keepSameLink,
            folder: BuildRemotePaths.appFolder(
				keepSameLink: keepSameLink,
				appInfoPath: dbAppInfoFullPath,
				buildDirectory: dbDirectroy,
				folderName: dbFolderName))
    }
}
