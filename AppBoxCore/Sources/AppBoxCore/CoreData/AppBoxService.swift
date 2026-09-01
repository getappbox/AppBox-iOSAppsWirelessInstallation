import CoreData
import Foundation

/// Core Data entity `AppBoxService` (model `AppBox4`).
@objc(AppBoxService)
public class AppBoxService: NSManagedObject {
    @NSManaged public var name: String?
    @NSManaged public var accountEmail: String?
    @NSManaged public var accountId: String?
    @NSManaged public var accountAccessKey: String?
    @NSManaged public var accountSecretKey: String?
    @NSManaged public var baseURL: String?
    @NSManaged public var uploadRecords: NSSet?
}
