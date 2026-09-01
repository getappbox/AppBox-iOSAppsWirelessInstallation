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
