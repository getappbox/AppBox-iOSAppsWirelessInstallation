import CoreData
import Foundation

/// Core Data entity `ProvisioningProfile` (model `AppBox4`).
@objc(ABProvisioningProfile)
public class ABProvisioningProfile: NSManagedObject {
    @NSManaged public var buildType: String?
    @NSManaged public var createDate: Date?
    @NSManaged public var expirationDate: Date?
    @NSManaged public var teamId: String?
    @NSManaged public var teamName: String?
    @NSManaged public var uuid: String?
    @NSManaged public var provisionedDevices: NSOrderedSet?
    @NSManaged public var uploadRecord: NSOrderedSet?
}
