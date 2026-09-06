import Foundation

/// Production `FileSystem` backed by `FileManager` + `FileHandle`.
public final class FileManagerFileSystem: FileSystem {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func temporaryDirectory() -> URL {
        fileManager.temporaryDirectory
    }

    public func createUniqueDirectory(permissions: Int?) throws -> URL {
        let url = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try createDirectory(at: url, permissions: permissions)
        return url
    }

    public func createDirectory(at url: URL, permissions: Int?) throws {
        var attributes: [FileAttributeKey: Any]?
        if let permissions {
            attributes = [.posixPermissions: NSNumber(value: permissions)]
        }
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: attributes)
    }

    public func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }

    public func removeItem(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    public func attributes(of url: URL) throws -> FileAttributes {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let size = (attributes[.size] as? NSNumber)?.int64Value ?? 0
        let permissions = (attributes[.posixPermissions] as? NSNumber)?.intValue
        return FileAttributes(size: size, posixPermissions: permissions)
    }

    public func read(contentsOf url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    public func write(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: .atomic)
    }

    public func openForReading(_ url: URL) throws -> FileReadHandle {
        FileHandleReadHandle(handle: try FileHandle(forReadingFrom: url))
    }
}

/// `FileReadHandle` over a `FileHandle`.
final class FileHandleReadHandle: FileReadHandle {
    private let handle: FileHandle

    init(handle: FileHandle) {
        self.handle = handle
    }

    func read(upToCount count: Int) throws -> Data {
        try handle.read(upToCount: count) ?? Data()
    }

    func seek(toOffset offset: UInt64) throws {
        try handle.seek(toOffset: offset)
    }

    func close() throws {
        try handle.close()
    }
}
