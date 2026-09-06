import CoreData
import Foundation

/// Core Data entity `ProvisionedDevice` (model `AppBox4`) — just a stored device UDID.
@objc(ABProvisionedDevice)
public class ABProvisionedDevice: NSManagedObject {
    @NSManaged public var deviceId: String?
}
