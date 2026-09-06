import CoreData
import XCTest
@testable import AppBoxCore

/// Records what the `DeleteCoordinator` asked of the provider, and can fail deletes.
private final class RecordingProvider: StorageProvider {
    let id: StorageProviderID = .dropbox
    var currentAccount: StorageAccount?
    var deleteError: StorageError?

    private(set) var deletedPaths: [RemotePath] = []
    private(set) var downloadedPaths: [RemotePath] = []
    private(set) var uploadedPaths: [RemotePath] = []

    func authenticate() async throws -> StorageAccount { StorageAccount(providerID: .dropbox, accountID: "x") }
    func signOut() throws {}
    func upload(fileAt localURL: URL, to remotePath: RemotePath, progress: ((Double) -> Void)?) async throws { uploadedPaths.append(remotePath) }
    func createShareableLink(for remotePath: RemotePath) async throws -> ShareableLink { ShareableLink(url: URL(string: "https://x")!, isDirectDownload: true) }
    func existingShareableLink(for remotePath: RemotePath) async throws -> ShareableLink? { nil }
    func listRevisions(for remotePath: RemotePath) async throws -> [RemoteRevision] { [] }
    func delete(at remotePath: RemotePath) async throws {
        if let deleteError { throw deleteError }
        deletedPaths.append(remotePath)
    }
    func download(from remotePath: RemotePath, to localURL: URL) async throws { downloadedPaths.append(remotePath) }

    var usedAtAll: Bool { !deletedPaths.isEmpty || !downloadedPaths.isEmpty || !uploadedPaths.isEmpty }
}

final class BuildDeletionServiceTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("BuildDeletionServiceTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws {
        if let tempDir { try? FileManager.default.removeItem(at: tempDir) }
    }

    private func makeModel() -> NSManagedObjectModel {
        func attr(_ name: String, _ type: NSAttributeType) -> NSAttributeDescription {
            let a = NSAttributeDescription(); a.name = name; a.attributeType = type; a.isOptional = true; return a
        }
        let project = NSEntityDescription(); project.name = "Project"; project.managedObjectClassName = "ABProject"
        let record = NSEntityDescription(); record.name = "UploadRecord"; record.managedObjectClassName = "ABUploadRecord"
        let profile = NSEntityDescription(); profile.name = "ProvisioningProfile"; profile.managedObjectClassName = "ABProvisioningProfile"

        project.properties = [attr("name", .stringAttributeType), attr("bundleIdentifier", .stringAttributeType)]
        record.properties = [attr("version", .stringAttributeType), attr("build", .stringAttributeType),
                             attr("datetime", .dateAttributeType), attr("shortURL", .stringAttributeType),
                             attr("dbAppInfoFullPath", .stringAttributeType), attr("dbDirectroy", .stringAttributeType),
                             attr("dbFolderName", .stringAttributeType), attr("dbSharedManifestURL", .stringAttributeType),
                             attr("keepSameLink", .booleanAttributeType)]
        profile.properties = [attr("buildType", .stringAttributeType), attr("teamName", .stringAttributeType)]

        let projUploads = NSRelationshipDescription(); projUploads.name = "uploadRecords"; projUploads.destinationEntity = record
        projUploads.minCount = 0; projUploads.maxCount = 0; projUploads.isOrdered = true; projUploads.deleteRule = .nullifyDeleteRule
        let recProject = NSRelationshipDescription(); recProject.name = "project"; recProject.destinationEntity = project
        recProject.minCount = 0; recProject.maxCount = 1; recProject.deleteRule = .nullifyDeleteRule
        projUploads.inverseRelationship = recProject; recProject.inverseRelationship = projUploads

        let profUploads = NSRelationshipDescription(); profUploads.name = "uploadRecord"; profUploads.destinationEntity = record
        profUploads.minCount = 0; profUploads.maxCount = 0; profUploads.isOrdered = true; profUploads.deleteRule = .nullifyDeleteRule
        let recProfile = NSRelationshipDescription(); recProfile.name = "provisioningProfile"; recProfile.destinationEntity = profile
        recProfile.minCount = 0; recProfile.maxCount = 1; recProfile.deleteRule = .nullifyDeleteRule
        profUploads.inverseRelationship = recProfile; recProfile.inverseRelationship = profUploads

        project.properties += [projUploads]; record.properties += [recProject, recProfile]; profile.properties += [profUploads]

        let model = NSManagedObjectModel(); model.entities = [project, record, profile]; return model
    }

    private func writableStack(_ model: NSManagedObjectModel) -> CoreDataStack {
        CoreDataStack(applicationSupportDirectoryURL: tempDir,
                      sqliteStoreURL: tempDir.appendingPathComponent("OSXCoreDataObjC.sqlite"),
                      storedataStoreURL: tempDir.appendingPathComponent("OSXCoreDataObjC.storedata"),
                      model: model)
    }

    private func seedRecord(_ stack: CoreDataStack, name: String, keepSameLink: Bool,
                            buildFolder: String, manifestLink: String) throws {
        let ctx = try stack.loadViewContext()
        let project = NSEntityDescription.insertNewObject(forEntityName: "Project", into: ctx) as! ABProject
        project.name = name; project.bundleIdentifier = "com.\(name)"
        let record = NSEntityDescription.insertNewObject(forEntityName: "UploadRecord", into: ctx) as! ABUploadRecord
        record.version = "1.0"; record.build = "1"; record.datetime = Date(timeIntervalSince1970: 1_000)
        record.shortURL = "https://s/\(name)"
        record.keepSameLink = NSNumber(value: keepSameLink)
        record.dbDirectroy = buildFolder
        record.dbFolderName = "/\(name)"
        record.dbAppInfoFullPath = "/\(name)/appinfo.json"
        record.dbSharedManifestURL = manifestLink
        record.project = project
        try stack.saveChanges()
    }

    private func recordCount(_ stack: CoreDataStack) throws -> Int {
        try stack.loadViewContext().count(for: NSFetchRequest<ABUploadRecord>(entityName: "UploadRecord"))
    }

    // MARK: Tests

    func testDeleteFromDropbox_nonKeepSameLink_deletesFolderAndRecord() async throws {
        let model = makeModel()
        let stack = writableStack(model)
        try seedRecord(stack, name: "App", keepSameLink: false, buildFolder: "/app/1.0", manifestLink: "m1")
        let provider = RecordingProvider()
        let service = BuildDeletionService(stack: stack, providerFactory: { provider })

        XCTAssertEqual(try service.loadBuilds().count, 1)
        try await service.delete(at: 0, fromDropbox: true)

        XCTAssertEqual(provider.deletedPaths.map(\.path), ["/app/1.0"])  // the build folder
        XCTAssertEqual(try recordCount(stack), 0)
    }

    func testDashboardOnly_removesRecordWithoutTouchingProvider() async throws {
        let stack = writableStack(makeModel())
        try seedRecord(stack, name: "App", keepSameLink: false, buildFolder: "/app/1.0", manifestLink: "m1")
        let provider = RecordingProvider()
        let service = BuildDeletionService(stack: stack, providerFactory: { provider })

        try service.loadBuilds()
        try await service.delete(at: 0, fromDropbox: false)

        XCTAssertFalse(provider.usedAtAll)
        XCTAssertEqual(try recordCount(stack), 0)
    }

    func testDropboxFailure_leavesRecordIntact() async throws {
        let stack = writableStack(makeModel())
        try seedRecord(stack, name: "App", keepSameLink: false, buildFolder: "/app/1.0", manifestLink: "m1")
        let provider = RecordingProvider()
        provider.deleteError = .notAuthenticated
        let service = BuildDeletionService(stack: stack, providerFactory: { provider })

        try service.loadBuilds()
        do {
            try await service.delete(at: 0, fromDropbox: true)
            XCTFail("expected the delete to throw")
        } catch let error as StorageError {
            XCTAssertEqual(error, .notAuthenticated)
        }
        XCTAssertEqual(try recordCount(stack), 1)
    }

    func testDeleteOutOfRange_throws() async throws {
        let stack = writableStack(makeModel())
        let service = BuildDeletionService(stack: stack, providerFactory: { RecordingProvider() })
        try service.loadBuilds()
        do {
            try await service.delete(at: 3, fromDropbox: false)
            XCTFail("expected an out-of-range delete to throw")
        } catch {
            XCTAssertTrue((error as NSError).localizedDescription.contains("No build at that position"))
        }
    }
}
