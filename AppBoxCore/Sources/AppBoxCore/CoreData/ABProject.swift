import CoreData
import Foundation

/// Core Data entity `Project` (model `AppBox4`).
@objc(ABProject)
public class ABProject: NSManagedObject {
    @NSManaged public var bundleIdentifier: String?
    @NSManaged public var name: String?
    @NSManaged public var uploadRecords: NSOrderedSet?
}
