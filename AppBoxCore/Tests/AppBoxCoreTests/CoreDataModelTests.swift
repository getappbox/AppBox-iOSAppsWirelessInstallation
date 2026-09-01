import CoreData
import XCTest
@testable import AppBoxCore

/// Verifies the Swift `@objc` NSManagedObject subclasses match the `AppBox4` schema: the `@objc(<name>)` registration resolves rows to the right Swift class, every `@NSManaged` attribute round-trips with the correct type (notably `keepSameLink` as `NSNumber`), and the ordered / to-one relationships work.
final class CoreDataModelTests: XCTestCase {

    // MARK: Model builder (mirrors AppBox/AppBox.xcdatamodeld/AppBox4)

    private func attr(_ name: String, _ type: NSAttributeType) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name; a.attributeType = type; a.isOptional = true
        return a
    }

    private func rel(_ name: String, _ destination: NSEntityDescription, toMany: Bool, ordered: Bool) -> NSRelationshipDescription {
        let r = NSRelationshipDescription()
        r.name = name; r.destinationEntity = destination
        r.minCount = 0; r.maxCount = toMany ? 0 : 1; r.isOrdered = ordered
        r.deleteRule = .nullifyDeleteRule
        return r
    }

    private func makeModel() -> NSManagedObjectModel {
        let project = NSEntityDescription(); project.name = "Project"; project.managedObjectClassName = "ABProject"
        let uploadRecord = NSEntityDescription(); uploadRecord.name = "UploadRecord"; uploadRecord.managedObjectClassName = "ABUploadRecord"
        let profile = NSEntityDescription(); profile.name = "ProvisioningProfile"; profile.managedObjectClassName = "ABProvisioningProfile"
        let device = NSEntityDescription(); device.name = "ProvisionedDevice"; device.managedObjectClassName = "ABProvisionedDevice"
        let service = NSEntityDescription(); service.name = "AppBoxService"; service.managedObjectClassName = "AppBoxService"

        project.properties = [attr("bundleIdentifier", .stringAttributeType), attr("name", .stringAttributeType)]
        uploadRecord.properties = [
            attr("build", .stringAttributeType), attr("version", .stringAttributeType),
            attr("datetime", .dateAttributeType), attr("keepSameLink", .booleanAttributeType),
            attr("dbDirectroy", .stringAttributeType), attr("dbIPAFullPath", .stringAttributeType),
        ]
        profile.properties = [attr("uuid", .stringAttributeType), attr("teamId", .stringAttributeType),
                              attr("createDate", .dateAttributeType)]
        device.properties = [attr("deviceId", .stringAttributeType)]
        service.properties = [attr("accountEmail", .stringAttributeType), attr("name", .stringAttributeType)]

        let projUploads = rel("uploadRecords", uploadRecord, toMany: true, ordered: true)
        let recProject = rel("project", project, toMany: false, ordered: false)
        projUploads.inverseRelationship = recProject; recProject.inverseRelationship = projUploads

        let profUploads = rel("uploadRecord", uploadRecord, toMany: true, ordered: true)
        let recProfile = rel("provisioningProfile", profile, toMany: false, ordered: false)
        profUploads.inverseRelationship = recProfile; recProfile.inverseRelationship = profUploads

        let svcUploads = rel("uploadRecords", uploadRecord, toMany: true, ordered: false)
        let recService = rel("service", service, toMany: false, ordered: false)
        svcUploads.inverseRelationship = recService; recService.inverseRelationship = svcUploads

        let profDevices = rel("provisionedDevices", device, toMany: true, ordered: true) // one-way (no inverse)

        project.properties += [projUploads]
        uploadRecord.properties += [recProject, recProfile, recService]
        profile.properties += [profUploads, profDevices]
        service.properties += [svcUploads]

        let model = NSManagedObjectModel()
        model.entities = [project, uploadRecord, profile, device, service]
        return model
    }

    private func makeContext() throws -> NSManagedObjectContext {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: makeModel())
        try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        let ctx = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        ctx.persistentStoreCoordinator = coordinator
        return ctx
    }

    /// The REAL shipping model — the `momc`-compiled `AppBox.momd` that Xcode bundles from `CoreData/Resources/AppBox.xcdatamodeld` into `Bundle.module`.
    private func realModelURL() -> URL? {
        Bundle.module.url(forResource: "AppBox", withExtension: "momd")
    }

    private func makeRealModelContext(_ url: URL) throws -> NSManagedObjectContext {
        let model = try XCTUnwrap(NSManagedObjectModel(contentsOf: url), "Failed to load AppBox.momd")
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        let ctx = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        ctx.persistentStoreCoordinator = coordinator
        return ctx
    }

    // MARK: Tests

    func testInsertResolvesToSwiftClassesAndRoundTrips() throws {
        let ctx = try makeContext()

        let project = NSEntityDescription.insertNewObject(forEntityName: "Project", into: ctx)
        let record = NSEntityDescription.insertNewObject(forEntityName: "UploadRecord", into: ctx)
        let profile = NSEntityDescription.insertNewObject(forEntityName: "ProvisioningProfile", into: ctx)
        let device = NSEntityDescription.insertNewObject(forEntityName: "ProvisionedDevice", into: ctx)
        let service = NSEntityDescription.insertNewObject(forEntityName: "AppBoxService", into: ctx)

        // @objc(name) registration must resolve each entity to its Swift class.
        let abProject = try XCTUnwrap(project as? ABProject)
        let abRecord = try XCTUnwrap(record as? ABUploadRecord)
        let abProfile = try XCTUnwrap(profile as? ABProvisioningProfile)
        let abDevice = try XCTUnwrap(device as? ABProvisionedDevice)
        let abService = try XCTUnwrap(service as? AppBoxService)

        abProject.name = "Test App"
        abProject.bundleIdentifier = "com.test.app"
        abRecord.version = "1.4"
        abRecord.build = "42"
        abRecord.datetime = Date(timeIntervalSince1970: 1000)
        abRecord.keepSameLink = NSNumber(value: true)
        abRecord.dbDirectroy = "/com.test.app/1.4"
        abRecord.project = abProject
        abProfile.uuid = "uuid-1"
        abProfile.teamId = "TEAM1"
        abDevice.deviceId = "device-1"
        abProfile.mutableOrderedSetValue(forKey: "provisionedDevices").add(abDevice)
        abRecord.provisioningProfile = abProfile
        abService.accountEmail = "a@b.com"
        abRecord.service = abService
        abProject.mutableOrderedSetValue(forKey: "uploadRecords").add(abRecord)

        try ctx.save()

        let fetched = try ctx.fetch(NSFetchRequest<ABUploadRecord>(entityName: "UploadRecord"))
        XCTAssertEqual(fetched.count, 1)
        let r = try XCTUnwrap(fetched.first)
        XCTAssertEqual(r.version, "1.4")
        XCTAssertEqual(r.build, "42")
        XCTAssertEqual(r.datetime, Date(timeIntervalSince1970: 1000))
        XCTAssertEqual(r.keepSameLink?.boolValue, true)
        XCTAssertEqual(r.dbDirectroy, "/com.test.app/1.4")
        XCTAssertEqual(r.project?.name, "Test App")
        XCTAssertEqual(r.project?.bundleIdentifier, "com.test.app")
        XCTAssertEqual(r.project?.uploadRecords?.count, 1)
        XCTAssertEqual(r.provisioningProfile?.uuid, "uuid-1")
        XCTAssertEqual(r.provisioningProfile?.provisionedDevices?.count, 1)
        XCTAssertEqual((r.provisioningProfile?.provisionedDevices?.firstObject as? ABProvisionedDevice)?.deviceId, "device-1")
        XCTAssertEqual(r.service?.accountEmail, "a@b.com")
    }

    func testFetchByEntityNameResolvesToSwiftClass() throws {
        let ctx = try makeContext()
        let record = NSEntityDescription.insertNewObject(forEntityName: "UploadRecord", into: ctx) as? ABUploadRecord
        record?.version = "9.9"
        try ctx.save()

        let request = NSFetchRequest<NSManagedObject>(entityName: "UploadRecord")
        let results = try ctx.fetch(request)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual((results.first as? ABUploadRecord)?.version, "9.9")
    }

    // MARK: Real shipping model (Bundle.module .momd)

    func testRealModelLoadsAndHasAppBox4Schema() throws {
        try XCTSkipUnless(realModelURL() != nil, "AppBox.momd not in Bundle.module (swift test doesn't run momc; validated by the Xcode build)")
        let model = try XCTUnwrap(NSManagedObjectModel(contentsOf: realModelURL()!))

        let byName = Dictionary(uniqueKeysWithValues: model.entities.map { ($0.name ?? "", $0) })
        XCTAssertEqual(byName["Project"]?.managedObjectClassName, "ABProject")
        XCTAssertEqual(byName["UploadRecord"]?.managedObjectClassName, "ABUploadRecord")
        XCTAssertEqual(byName["ProvisioningProfile"]?.managedObjectClassName, "ABProvisioningProfile")
        XCTAssertEqual(byName["ProvisionedDevice"]?.managedObjectClassName, "ABProvisionedDevice")
        XCTAssertEqual(byName["AppBoxService"]?.managedObjectClassName, "AppBoxService")
    }

    func testRealModelInsertResolvesToSwiftClassesAndRoundTrips() throws {
        try XCTSkipUnless(realModelURL() != nil, "AppBox.momd not in Bundle.module (swift test doesn't run momc; validated by the Xcode build)")
        let ctx = try makeRealModelContext(realModelURL()!)

        let record = NSEntityDescription.insertNewObject(forEntityName: "UploadRecord", into: ctx) as? ABUploadRecord
        let project = NSEntityDescription.insertNewObject(forEntityName: "Project", into: ctx) as? ABProject
        let profile = NSEntityDescription.insertNewObject(forEntityName: "ProvisioningProfile", into: ctx) as? ABProvisioningProfile
        let device = NSEntityDescription.insertNewObject(forEntityName: "ProvisionedDevice", into: ctx) as? ABProvisionedDevice

        let abRecord = try XCTUnwrap(record, "UploadRecord did not resolve to ABUploadRecord against the real model")
        let abProject = try XCTUnwrap(project)
        let abProfile = try XCTUnwrap(profile)
        let abDevice = try XCTUnwrap(device)

        abProject.name = "Real App"
        abProject.bundleIdentifier = "com.real.app"
        abRecord.version = "2.0"
        abRecord.keepSameLink = NSNumber(value: true)
        abRecord.project = abProject
        abProfile.uuid = "real-uuid"
        abDevice.deviceId = "real-device"
        abProfile.mutableOrderedSetValue(forKey: "provisionedDevices").add(abDevice)
        abRecord.provisioningProfile = abProfile
        abProject.mutableOrderedSetValue(forKey: "uploadRecords").add(abRecord)

        try ctx.save()

        let fetched = try ctx.fetch(NSFetchRequest<ABUploadRecord>(entityName: "UploadRecord"))
        let r = try XCTUnwrap(fetched.first)
        XCTAssertEqual(r.version, "2.0")
        XCTAssertEqual(r.keepSameLink?.boolValue, true)
        XCTAssertEqual(r.project?.bundleIdentifier, "com.real.app")
        XCTAssertEqual(r.provisioningProfile?.uuid, "real-uuid")
        XCTAssertEqual(r.provisioningProfile?.provisionedDevices?.count, 1)
    }
}
