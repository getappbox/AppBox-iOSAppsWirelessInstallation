import CoreData
import XCTest
@testable import AppBoxCore

final class BuildRecordStoreTests: XCTestCase {

    // MARK: Model (the Project ↔ UploadRecord slice of AppBox4 that `BuildRecordStore.save` writes)

    private func makeContext() throws -> NSManagedObjectContext {
        func attr(_ name: String, _ type: NSAttributeType) -> NSAttributeDescription {
            let a = NSAttributeDescription(); a.name = name; a.attributeType = type; a.isOptional = true; return a
        }
        let project = NSEntityDescription(); project.name = "Project"; project.managedObjectClassName = "ABProject"
        let record = NSEntityDescription(); record.name = "UploadRecord"; record.managedObjectClassName = "ABUploadRecord"

        project.properties = [attr("name", .stringAttributeType), attr("bundleIdentifier", .stringAttributeType)]
        record.properties = ["buildType", "dbAppInfoFullPath", "dbDirectroy", "dbFolderName", "dbIPAFullPath",
                             "dbManifestFullPath", "dbSharedIPAURL", "dbSharedManifestURL", "dbSharedAppInfoURL",
                             "localBuildPath", "shortURL", "build", "version"].map { attr($0, .stringAttributeType) }
            + [attr("keepSameLink", .booleanAttributeType), attr("datetime", .dateAttributeType)]

        let uploads = NSRelationshipDescription(); uploads.name = "uploadRecords"; uploads.destinationEntity = record
        uploads.minCount = 0; uploads.maxCount = 0; uploads.isOrdered = true; uploads.deleteRule = .cascadeDeleteRule
        let owner = NSRelationshipDescription(); owner.name = "project"; owner.destinationEntity = project
        owner.minCount = 0; owner.maxCount = 1; owner.deleteRule = .nullifyDeleteRule
        uploads.inverseRelationship = owner; owner.inverseRelationship = uploads
        project.properties += [uploads]; record.properties += [owner]

        let model = NSManagedObjectModel(); model.entities = [project, record]
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        return context
    }

    private func input(bundleDirectory: String, keepSameLink: Bool) -> BuildRecordInput {
        let metadata = BuildMetadata(name: "MyApp", version: "1.2", build: "345", identifier: "com.example.myapp",
                                     minimumOSVersion: nil, supportedDevice: "iPhone")
        let paths = BuildRemotePaths(metadata: metadata, uuid: "ABC123", bundleDirectory: bundleDirectory,
                                     keepSameLink: keepSameLink)
        return BuildRecordInput(identifier: metadata.identifier, name: metadata.name, version: metadata.version,
                                build: metadata.build, keepSameLink: keepSameLink,
                                bundleDirectory: paths.bundleDirectory, buildDirectory: paths.buildDirectory,
                                ipaRemotePath: paths.ipa.path, manifestRemotePath: paths.manifest.path,
                                appInfoRemotePath: paths.appInfo.path)
    }

    private func savedRecord(_ input: BuildRecordInput, in context: NSManagedObjectContext) throws -> ABUploadRecord {
        let project = try BuildRecordStore.save(input, in: context) { try context.save() }
        return try XCTUnwrap(project.uploadRecords?.lastObject as? ABUploadRecord)
    }

    // MARK: Tests

    func testSaveKeepsTheLinkChoiceAndTheFullNestedFolder() throws {
        let record = try savedRecord(input(bundleDirectory: "/Team/QA", keepSameLink: true), in: makeContext())

        XCTAssertEqual(record.keepSameLink?.boolValue, true)
        XCTAssertEqual(record.dbFolderName, "/Team/QA")
        XCTAssertEqual(record.linkSettings, BuildLinkSettings(keepSameLink: true, folder: RemotePath(path: "/Team/QA")))
    }

    func testSaveRecordsAnUnkeptUploadInTheBundleIdentifierFolder() throws {
        let record = try savedRecord(input(bundleDirectory: "", keepSameLink: false), in: makeContext())

        XCTAssertEqual(record.keepSameLink?.boolValue, false)
        XCTAssertEqual(record.linkSettings,
                       BuildLinkSettings(keepSameLink: false, folder: RemotePath(path: "/com.example.myapp")))
    }

    func testCLIFolderWithALeadingSlashReadsBackNormalized() throws {
        let record = try savedRecord(input(bundleDirectory: "//Foo", keepSameLink: true), in: makeContext())

        XCTAssertEqual(record.linkSettings.folder?.relativePath, "Foo")
    }

    func testRepeatedUploadsOfAnAppShareOneProject() throws {
        let context = try makeContext()
        _ = try savedRecord(input(bundleDirectory: "/Team/QA", keepSameLink: true), in: context)
        let second = try savedRecord(input(bundleDirectory: "/Team/QA", keepSameLink: true), in: context)

        let projects = try context.fetch(NSFetchRequest<ABProject>(entityName: "Project"))
        XCTAssertEqual(projects.count, 1)
        XCTAssertEqual(projects.first?.uploadRecords?.count, 2)
        XCTAssertEqual(second.project, projects.first)
    }
}
