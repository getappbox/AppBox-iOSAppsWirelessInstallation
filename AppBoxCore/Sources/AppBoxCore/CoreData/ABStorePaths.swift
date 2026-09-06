import Foundation

/// Single source of truth for the AppBox Core Data store location, so the GUI (and, the CLI) point at the same file.
public final class ABStorePaths: NSObject {

    /// `~/Library/Application Support/com.developerinsider.AppBox`.
    public static var applicationSupportDirectoryURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("com.developerinsider.AppBox")
    }

    /// The SQLite store URL.
    public static var sqliteStoreURL: URL {
        applicationSupportDirectoryURL.appendingPathComponent("OSXCoreDataObjC.sqlite")
    }

    /// The legacy XML store URL.
    public static var storedataStoreURL: URL {
        applicationSupportDirectoryURL.appendingPathComponent("OSXCoreDataObjC.storedata")
    }

    /// AppBox's own subdirectory of the (per-user, process-shared) temporary directory
    public static var temporaryDirectoryURL: URL {
        URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AppBox", isDirectory: true)
    }

    /// A fresh, private scratch directory under `temporaryDirectoryURL`.
    public static func makeTemporaryWorkingDirectory(prefix: String = "") throws -> URL {
        let url = temporaryDirectoryURL.appendingPathComponent(prefix + UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
			at: url,
			withIntermediateDirectories: true,
			attributes: [.posixPermissions: 0o700])
        return url
    }
}
