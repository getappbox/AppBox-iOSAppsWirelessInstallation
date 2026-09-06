import CoreData
import Foundation
import os

/// The AppBox Core Data stack, moved out of `AppDelegate.m` into Core so the GUI and the standalone CLI load the SAME compiled model and point at the SAME store.
public final class CoreDataStack: NSObject {

    /// The process-wide stack pointed at the real on-disk store.
    public static let shared = CoreDataStack()

    private static let log = Logger(subsystem: "com.developerinsider.AppBox.core", category: "CoreData")

    private let applicationSupportDirectoryURL: URL
    private let sqliteStoreURL: URL
    private let storedataStoreURL: URL
    private let injectedModel: NSManagedObjectModel?
    private let readOnly: Bool

    private var _coordinator: NSPersistentStoreCoordinator?
    private var _viewContext: NSManagedObjectContext?

    /// Real-store initializer (used by `shared`): real store paths, model from `Bundle.module`.
    public override convenience init() {
        self.init(applicationSupportDirectoryURL: ABStorePaths.applicationSupportDirectoryURL,
                  sqliteStoreURL: ABStorePaths.sqliteStoreURL,
                  storedataStoreURL: ABStorePaths.storedataStoreURL,
                  model: nil)
    }

    /// A read-only stack on the real store — for the CLI, which only reads the upload history and must not contend with a running GUI's writes (Core Data's SQLite WAL allows a concurrent reader).
    public static func readOnlyOnRealStore() -> CoreDataStack {
        CoreDataStack(applicationSupportDirectoryURL: ABStorePaths.applicationSupportDirectoryURL,
                      sqliteStoreURL: ABStorePaths.sqliteStoreURL,
                      storedataStoreURL: ABStorePaths.storedataStoreURL,
                      model: nil, readOnly: true)
    }

    /// Designated initializer — store locations and the model are injectable so tests can use a temp directory and the programmatic model (the compiled `.momd` is absent under `swift test`).
    public init(applicationSupportDirectoryURL: URL, sqliteStoreURL: URL, storedataStoreURL: URL,
                model: NSManagedObjectModel? = nil, readOnly: Bool = false) {
        self.applicationSupportDirectoryURL = applicationSupportDirectoryURL
        self.sqliteStoreURL = sqliteStoreURL
        self.storedataStoreURL = storedataStoreURL
        self.injectedModel = model
        self.readOnly = readOnly
        super.init()
    }

    // MARK: - Model

    /// Loads the compiled `AppBox.momd` from the module resource bundle.
    public static func loadManagedObjectModel() -> NSManagedObjectModel? {
        guard let url = moduleResourceBundle?.url(forResource: "AppBox", withExtension: "momd") else {
            return nil
        }
        return NSManagedObjectModel(contentsOf: url)
    }

    /// Locates `AppBoxCore_AppBoxCore.bundle` without the generated `Bundle.module` accessor, which `fatalError`s when the bundle is absent — a missing bundle must surface as the "Failed to load the AppBox managed object model" NSError, not a crash.
    private static var moduleResourceBundle: Bundle? {
        let bundleName = "AppBoxCore_AppBoxCore.bundle"
        var candidates: [URL?] = [
            Bundle.main.resourceURL,
            Bundle(for: CoreDataStack.self).resourceURL,
            Bundle.main.bundleURL,
        ]
        if let executable = Bundle.main.executableURL?.resolvingSymlinksInPath() {
            candidates.append(executable.deletingLastPathComponent())
        }
        for candidate in candidates {
            if let url = candidate?.appendingPathComponent(bundleName),
               FileManager.default.fileExists(atPath: url.path),
               let bundle = Bundle(url: url) {
                return bundle
            }
        }
        return nil
    }

    // MARK: - Context (lazy, idempotent)

    /// Returns the main-queue view context, building the coordinator + store on first call.
    public func loadViewContext() throws -> NSManagedObjectContext {
        if let ctx = _viewContext { return ctx }
        let coordinator = try makeCoordinator()
        let ctx = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        ctx.persistentStoreCoordinator = coordinator
        _viewContext = ctx
        return ctx
    }

    /// The view context if it has already been built, else nil — used by `saveChanges()` so a save before any fetch is a no-op (matches the original `if (_managedObjectContext) …`).
    public var existingViewContext: NSManagedObjectContext? { _viewContext }

    // MARK: - Save

    /// Saves pending changes on the view context.
    public func saveChanges() throws {
        guard let ctx = _viewContext, ctx.hasChanges else { return }
        try ctx.save()
    }

    // MARK: - Coordinator + store (mirrors AppDelegate.m persistentStoreCoordinator)

    private func makeCoordinator() throws -> NSPersistentStoreCoordinator {
        if let coordinator = _coordinator { return coordinator }

        guard let model = injectedModel ?? CoreDataStack.loadManagedObjectModel() else {
            throw makeError("Failed to load the AppBox managed object model (AppBox.momd).")
        }

        let fileManager = FileManager.default

        if readOnly {
            guard fileManager.fileExists(atPath: sqliteStoreURL.path) else {
                throw makeError("No AppBox upload history found. Upload a build with the AppBox app first.")
            }
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil,
                                               at: sqliteStoreURL, options: [NSReadOnlyPersistentStoreOption: true])
            _coordinator = coordinator
            return coordinator
        }

        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: applicationSupportDirectoryURL.path, isDirectory: &isDirectory) {
            if !isDirectory.boolValue {
                throw makeError("Expected a folder to store application data, found a file (\(applicationSupportDirectoryURL.path)).")
            }
        } else {
            try fileManager.createDirectory(at: applicationSupportDirectoryURL,
                                            withIntermediateDirectories: true, attributes: nil)
        }

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let options: [AnyHashable: Any] = [
            NSInferMappingModelAutomaticallyOption: true,
            NSMigratePersistentStoresAutomaticallyOption: true
        ]

        let xmlExists = fileManager.fileExists(atPath: storedataStoreURL.path)
        let sqliteExists = fileManager.fileExists(atPath: sqliteStoreURL.path)

        if xmlExists && !sqliteExists {
            let xmlStore = try coordinator.addPersistentStore(ofType: NSXMLStoreType, configurationName: nil,
                                                              at: storedataStoreURL, options: options)
            _ = try coordinator.migratePersistentStore(xmlStore, to: sqliteStoreURL,
                                                       options: options, withType: NSSQLiteStoreType)
            CoreDataStack.log.info("Migrated Core Data store from XML to SQLite.")
            try? fileManager.removeItem(at: storedataStoreURL)
        } else {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil,
                                               at: sqliteStoreURL, options: options)
        }

        _coordinator = coordinator
        return coordinator
    }

    private func makeError(_ reason: String) -> NSError {
        NSError(domain: "com.developerinsider.AppBox", code: 9999, userInfo: [
            NSLocalizedDescriptionKey: "Failed to initialize the application's saved data",
            NSLocalizedFailureReasonErrorKey: reason
        ])
    }
}
