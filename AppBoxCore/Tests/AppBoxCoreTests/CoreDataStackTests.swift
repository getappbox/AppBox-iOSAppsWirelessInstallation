import CoreData
import XCTest
@testable import AppBoxCore

/// Exercises `CoreDataStack`'s coordinator/store logic against a TEMP on-disk SQLite store using the programmatic model (the compiled `.momd` is absent under `swift test`).
final class CoreDataStackTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoreDataStackTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let tempDir { try? FileManager.default.removeItem(at: tempDir) }
    }

    private func makeModel() -> NSManagedObjectModel {
        let record = NSEntityDescription()
        record.name = "UploadRecord"
        record.managedObjectClassName = "ABUploadRecord"
        let version = NSAttributeDescription(); version.name = "version"; version.attributeType = .stringAttributeType; version.isOptional = true
        let build = NSAttributeDescription(); build.name = "build"; build.attributeType = .stringAttributeType; build.isOptional = true
        record.properties = [version, build]
        let model = NSManagedObjectModel()
        model.entities = [record]
        return model
    }

    private func makeStack(model: NSManagedObjectModel) -> CoreDataStack {
        CoreDataStack(applicationSupportDirectoryURL: tempDir,
                      sqliteStoreURL: tempDir.appendingPathComponent("OSXCoreDataObjC.sqlite"),
                      storedataStoreURL: tempDir.appendingPathComponent("OSXCoreDataObjC.storedata"),
                      model: model)
    }

    func testCreatesSQLiteStoreAndPersistsAcrossInstances() throws {
        let model = makeModel()
        let sqliteURL = tempDir.appendingPathComponent("OSXCoreDataObjC.sqlite")

        let stack = makeStack(model: model)
        let ctx = try stack.loadViewContext()
        let record = try XCTUnwrap(NSEntityDescription.insertNewObject(forEntityName: "UploadRecord", into: ctx) as? ABUploadRecord)
        record.version = "1.0"
        record.build = "7"
        try stack.saveChanges()
        XCTAssertTrue(FileManager.default.fileExists(atPath: sqliteURL.path), "SQLite store should be created on disk")

        let stack2 = makeStack(model: model)
        let ctx2 = try stack2.loadViewContext()
        let fetched = try ctx2.fetch(NSFetchRequest<ABUploadRecord>(entityName: "UploadRecord"))
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.version, "1.0")
        XCTAssertEqual(fetched.first?.build, "7")
    }

    func testViewContextIsLazyAndCached() throws {
        let stack = makeStack(model: makeModel())
        XCTAssertNil(stack.existingViewContext, "no context before first load")
        let ctx = try stack.loadViewContext()
        XCTAssertTrue(stack.existingViewContext === ctx, "context is cached")
        XCTAssertTrue(try stack.loadViewContext() === ctx, "second load returns the same context")
    }

    func testSaveBeforeLoadIsNoOp() throws {
        let stack = makeStack(model: makeModel())
        XCTAssertNoThrow(try stack.saveChanges())
    }

    func testMigratesLegacyXMLStoreToSQLite() throws {
        let model = makeModel()
        let xmlURL = tempDir.appendingPathComponent("OSXCoreDataObjC.storedata")
        let sqliteURL = tempDir.appendingPathComponent("OSXCoreDataObjC.sqlite")

        let seedCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try seedCoordinator.addPersistentStore(ofType: NSXMLStoreType, configurationName: nil, at: xmlURL, options: nil)
        let seedCtx = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        seedCtx.persistentStoreCoordinator = seedCoordinator
        let seeded = NSEntityDescription.insertNewObject(forEntityName: "UploadRecord", into: seedCtx) as? ABUploadRecord
        seeded?.version = "legacy-9.9"
        try seedCtx.save()
        XCTAssertTrue(FileManager.default.fileExists(atPath: xmlURL.path))

        let stack = makeStack(model: model)
        let ctx = try stack.loadViewContext()
        XCTAssertTrue(FileManager.default.fileExists(atPath: sqliteURL.path), "SQLite store created")
        XCTAssertFalse(FileManager.default.fileExists(atPath: xmlURL.path), "legacy XML store removed after migration")
        let fetched = try ctx.fetch(NSFetchRequest<ABUploadRecord>(entityName: "UploadRecord"))
        XCTAssertEqual(fetched.first?.version, "legacy-9.9", "migrated data survives")
    }
}
