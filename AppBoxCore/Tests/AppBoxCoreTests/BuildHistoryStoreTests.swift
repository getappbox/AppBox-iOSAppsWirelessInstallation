import CoreData
import XCTest
@testable import AppBoxCore

/// Exercises `BuildHistoryStore` against a TEMP on-disk SQLite store with the programmatic model (the compiled `.momd` is absent under `swift test`): the newest-first sort + field mapping, an empty store, the read-only open path, and the missing-store error.
final class BuildHistoryStoreTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("BuildHistoryStoreTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let tempDir { try? FileManager.default.removeItem(at: tempDir) }
    }

    // MARK: Model (Project ↔ UploadRecord → ProvisioningProfile, mirroring AppBox4's relevant slice)

    private func makeModel() -> NSManagedObjectModel {
        func attr(_ name: String, _ type: NSAttributeType) -> NSAttributeDescription {
            let a = NSAttributeDescription(); a.name = name; a.attributeType = type; a.isOptional = true; return a
        }
        let project = NSEntityDescription(); project.name = "Project"; project.managedObjectClassName = "ABProject"
        let record = NSEntityDescription(); record.name = "UploadRecord"; record.managedObjectClassName = "ABUploadRecord"
        let profile = NSEntityDescription(); profile.name = "ProvisioningProfile"; profile.managedObjectClassName = "ABProvisioningProfile"

        project.properties = [attr("name", .stringAttributeType), attr("bundleIdentifier", .stringAttributeType)]
        record.properties = [attr("version", .stringAttributeType), attr("build", .stringAttributeType),
                             attr("datetime", .dateAttributeType), attr("shortURL", .stringAttributeType)]
        profile.properties = [attr("buildType", .stringAttributeType), attr("teamName", .stringAttributeType)]

        func rel(_ name: String, _ dest: NSEntityDescription, toMany: Bool, ordered: Bool) -> NSRelationshipDescription {
            let r = NSRelationshipDescription(); r.name = name; r.destinationEntity = dest
            r.minCount = 0; r.maxCount = toMany ? 0 : 1; r.isOrdered = ordered; r.deleteRule = .nullifyDeleteRule
            return r
        }
        let projUploads = rel("uploadRecords", record, toMany: true, ordered: true)
        let recProject = rel("project", project, toMany: false, ordered: false)
        projUploads.inverseRelationship = recProject; recProject.inverseRelationship = projUploads

        let profUploads = rel("uploadRecord", record, toMany: true, ordered: true)
        let recProfile = rel("provisioningProfile", profile, toMany: false, ordered: false)
        profUploads.inverseRelationship = recProfile; recProfile.inverseRelationship = profUploads

        project.properties += [projUploads]
        record.properties += [recProject, recProfile]
        profile.properties += [profUploads]

        let model = NSManagedObjectModel()
        model.entities = [project, record, profile]
        return model
    }

    private func writableStack(_ model: NSManagedObjectModel) -> CoreDataStack {
        CoreDataStack(applicationSupportDirectoryURL: tempDir,
                      sqliteStoreURL: tempDir.appendingPathComponent("OSXCoreDataObjC.sqlite"),
                      storedataStoreURL: tempDir.appendingPathComponent("OSXCoreDataObjC.storedata"),
                      model: model)
    }

    @discardableResult
    private func seed(_ stack: CoreDataStack, name: String, version: String, build: String,
                      buildType: String, team: String, date: Date, shortURL: String) throws -> NSManagedObject {
        let ctx = try stack.loadViewContext()
        let project = NSEntityDescription.insertNewObject(forEntityName: "Project", into: ctx) as! ABProject
        project.name = name; project.bundleIdentifier = "com.\(name)"
        let profile = NSEntityDescription.insertNewObject(forEntityName: "ProvisioningProfile", into: ctx) as! ABProvisioningProfile
        profile.buildType = buildType; profile.teamName = team
        let record = NSEntityDescription.insertNewObject(forEntityName: "UploadRecord", into: ctx) as! ABUploadRecord
        record.version = version; record.build = build; record.datetime = date; record.shortURL = shortURL
        record.project = project; record.provisioningProfile = profile
        try stack.saveChanges()
        return record
    }

    // MARK: Tests

    func testRecentBuilds_newestFirstWithMappedFields() throws {
        let model = makeModel()
        let stack = writableStack(model)
        try seed(stack, name: "Older", version: "1.0", build: "1", buildType: "ad-hoc", team: "T1",
                 date: Date(timeIntervalSince1970: 1_000), shortURL: "https://s/old")
        try seed(stack, name: "Newer", version: "2.0", build: "9", buildType: "enterprise", team: "T2",
                 date: Date(timeIntervalSince1970: 2_000), shortURL: "https://s/new")

        let builds = try BuildHistoryStore(stack: stack).recentBuilds()
        XCTAssertEqual(builds.count, 2)
        XCTAssertEqual(builds.first?.appName, "Newer")           // newest first
        XCTAssertEqual(builds.first?.version, "2.0")
        XCTAssertEqual(builds.first?.build, "9")
        XCTAssertEqual(builds.first?.buildType, "enterprise")    // from provisioning profile
        XCTAssertEqual(builds.first?.teamName, "T2")
        XCTAssertEqual(builds.first?.bundleIdentifier, "com.Newer")
        XCTAssertEqual(builds.first?.shortURL, "https://s/new")
        XCTAssertEqual(builds.last?.appName, "Older")
    }

    func testRecentBuilds_emptyStore() throws {
        let builds = try BuildHistoryStore(stack: writableStack(makeModel())).recentBuilds()
        XCTAssertTrue(builds.isEmpty)
    }

    func testReadOnlyStack_readsAPreSeededStore() throws {
        let model = makeModel()
        try seed(writableStack(model), name: "App", version: "3.1", build: "42", buildType: "ad-hoc",
                 team: "T", date: Date(timeIntervalSince1970: 5_000), shortURL: "https://s/x")

        let readOnly = CoreDataStack(applicationSupportDirectoryURL: tempDir,
                                     sqliteStoreURL: tempDir.appendingPathComponent("OSXCoreDataObjC.sqlite"),
                                     storedataStoreURL: tempDir.appendingPathComponent("OSXCoreDataObjC.storedata"),
                                     model: model, readOnly: true)
        let builds = try BuildHistoryStore(stack: readOnly).recentBuilds()
        XCTAssertEqual(builds.first?.version, "3.1")
        XCTAssertEqual(builds.first?.build, "42")
    }

    func testReadOnlyStack_missingStoreThrowsClearError() {
        let readOnly = CoreDataStack(applicationSupportDirectoryURL: tempDir,
                                     sqliteStoreURL: tempDir.appendingPathComponent("does-not-exist.sqlite"),
                                     storedataStoreURL: tempDir.appendingPathComponent("OSXCoreDataObjC.storedata"),
                                     model: makeModel(), readOnly: true)
        XCTAssertThrowsError(try BuildHistoryStore(stack: readOnly).recentBuilds()) { error in
            XCTAssertTrue((error as NSError).localizedFailureReason?.contains("No AppBox upload history") ?? false)
        }
    }
}
