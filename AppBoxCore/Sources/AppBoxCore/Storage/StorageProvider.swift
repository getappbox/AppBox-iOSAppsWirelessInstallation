import Foundation

// MARK: - Identity

/// Identifies a cloud-storage backend.
public enum StorageProviderID: String, Sendable, CaseIterable {
    case dropbox
    case googleDrive
    case s3
    case webDAV
}

// MARK: - Value types

/// An authenticated account on some provider.
public struct StorageAccount: Equatable, Sendable {
    public let providerID: StorageProviderID
    public let accountID: String
    public let displayName: String?
    public let email: String?

    public init(providerID: StorageProviderID, accountID: String, displayName: String? = nil, email: String? = nil) {
        self.providerID = providerID
        self.accountID = accountID
        self.displayName = displayName
        self.email = email
    }
}

/// A provider-agnostic destination path, expressed as ordered components (e.g.
public struct RemotePath: Equatable, Sendable {
    public let components: [String]

    public init(_ components: [String]) {
        self.components = components
    }

    public init(path: String) {
        self.components = path.split(separator: "/").map(String.init)
    }

    /// POSIX-style joined path, always leading-slashed (Dropbox-style).
    public var path: String { "/" + components.joined(separator: "/") }

    public func appending(_ component: String) -> RemotePath { RemotePath(components + [component]) }
}

/// A link that can be handed to a device to download a file.
public struct ShareableLink: Equatable, Sendable {
    public let url: URL
    public let isDirectDownload: Bool

    public init(url: URL, isDirectDownload: Bool) {
        self.url = url
        self.isDirectDownload = isDirectDownload
    }
}

/// A stored revision of a remote file (used for "install previous version" / dashboard history).
public struct RemoteRevision: Equatable, Sendable {
    public let revisionID: String
    public let modified: Date
    public let size: Int64

    public init(revisionID: String, modified: Date, size: Int64) {
        self.revisionID = revisionID
        self.modified = modified
        self.size = size
    }
}

// MARK: - Errors

/// Unified error surface across providers — each provider maps its own SDK/HTTP errors onto these cases so the upload pipeline (and `UploadRetryPolicy`) can reason about failures without knowing which backend produced them.
public enum StorageError: Error, Equatable {
    case notAuthenticated
    case authenticationFailed(String)
    /// Transient connectivity/transport failure — safe to retry.
    case network(String)
    /// Provider asked us to back off; `retryAfter` is seconds if the provider supplied it.
    case rateLimited(retryAfter: TimeInterval?)
    case notFound
    case conflict(String)
    /// Provider-side (5xx-equivalent) failure — generally retryable.
    case server(String)
    case cancelled
    case unknown(String)

    /// Whether a retry could plausibly succeed (drives `UploadRetryPolicy`).
    public var isRetryable: Bool {
        switch self {
        case .network, .server, .rateLimited:
            return true
        case .notAuthenticated, .authenticationFailed, .notFound, .conflict, .cancelled, .unknown:
            return false
        }
    }
}

// MARK: - Provider

/// Provider-agnostic cloud storage.
public protocol StorageProvider: AnyObject {
    var id: StorageProviderID { get }

    /// The currently authenticated account, or `nil` if signed out.
    var currentAccount: StorageAccount? { get }

    /// Authenticate (provider decides how — OAuth, token, etc.) and return the account.
    @discardableResult
    func authenticate() async throws -> StorageAccount
    func signOut() throws

    /// Upload a local file to `remotePath`.
    func upload(fileAt localURL: URL, to remotePath: RemotePath, progress: ((Double) -> Void)?) async throws

    /// Upload with optimistic concurrency for shared files (the app-wide `appinfo.json`): when `precondition` is non-nil the write must apply on top of exactly that revision — if the remote file changed in the meantime the provider throws `StorageError.conflict` instead of clobbering it.
    @discardableResult
    func upload(fileAt localURL: URL, to remotePath: RemotePath,
                ifRevisionMatches precondition: String?, progress: ((Double) -> Void)?) async throws -> String?

    /// Create (or fetch, if it already exists) a shareable direct-download link.
    func createShareableLink(for remotePath: RemotePath) async throws -> ShareableLink
    /// An existing shareable link if one is already published, else `nil`.
    func existingShareableLink(for remotePath: RemotePath) async throws -> ShareableLink?

    func listRevisions(for remotePath: RemotePath) async throws -> [RemoteRevision]
    func delete(at remotePath: RemotePath) async throws

    /// Download the file at `remotePath` to `localURL` (used to fetch the existing appinfo.json when keeping the same link).
    func download(from remotePath: RemotePath, to localURL: URL) async throws

    /// Like `download(from:to:)` but returns the downloaded file's current revision (nil when the provider doesn't surface revisions) — the base for a subsequent `ifRevisionMatches` upload.
    @discardableResult
    func downloadWithRevision(from remotePath: RemotePath, to localURL: URL) async throws -> String?
}

public extension StorageProvider {
    @discardableResult
    func upload(fileAt localURL: URL, to remotePath: RemotePath,
                ifRevisionMatches precondition: String?, progress: ((Double) -> Void)?) async throws -> String? {
        try await upload(fileAt: localURL, to: remotePath, progress: progress)
        return nil
    }

    @discardableResult
    func downloadWithRevision(from remotePath: RemotePath, to localURL: URL) async throws -> String? {
        try await download(from: remotePath, to: localURL)
        return nil
    }
}

// MARK: - Registry

/// Maps a `StorageProviderID` to a factory that builds its `StorageProvider`.
public final class StorageProviderRegistry {
    public typealias Factory = () -> StorageProvider

    private var factories: [StorageProviderID: Factory] = [:]

    public init() {}

    public func register(_ id: StorageProviderID, factory: @escaping Factory) {
        factories[id] = factory
    }

    public func makeProvider(_ id: StorageProviderID) -> StorageProvider? {
        factories[id]?()
    }

    public var registeredProviders: [StorageProviderID] {
        Array(factories.keys)
    }
}
