import Foundation

/// A subset of file attributes Core actually needs.
public struct FileAttributes: Equatable, Sendable {
    public let size: Int64
    /// POSIX permission bits (e.g.
    public let posixPermissions: Int?

    public init(size: Int64, posixPermissions: Int?) {
        self.size = size
        self.posixPermissions = posixPermissions
    }
}

/// A seekable, chunked reader over a file — used by the resumable uploader to stream a large IPA without loading it fully into memory.
public protocol FileReadHandle: AnyObject {
    /// Reads up to `count` bytes from the current offset (fewer at EOF, empty when exhausted).
    func read(upToCount count: Int) throws -> Data
    func seek(toOffset offset: UInt64) throws
    func close() throws
}

/// Abstraction over the file system (production: `FileManager` + `FileHandle`).
public protocol FileSystem: AnyObject {
    func temporaryDirectory() -> URL

    /// Creates a fresh, uniquely-named directory (default permissions `0o700`) and returns it.
    func createUniqueDirectory(permissions: Int?) throws -> URL
    func createDirectory(at url: URL, permissions: Int?) throws

    func fileExists(at url: URL) -> Bool
    func removeItem(at url: URL) throws
    func attributes(of url: URL) throws -> FileAttributes

    func read(contentsOf url: URL) throws -> Data
    func write(_ data: Data, to url: URL) throws

    func openForReading(_ url: URL) throws -> FileReadHandle
}

public extension FileSystem {
    func createUniqueDirectory() throws -> URL { try createUniqueDirectory(permissions: 0o700) }
}
