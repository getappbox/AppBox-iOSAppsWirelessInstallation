import Foundation
@testable import AppBoxCore

// MARK: - KeyValueStore

final class InMemoryKeyValueStore: KeyValueStore {
    private(set) var storage: [String: Any] = [:]

    func bool(forKey key: String) -> Bool { storage[key] as? Bool ?? false }
    func integer(forKey key: String) -> Int { storage[key] as? Int ?? 0 }
    func string(forKey key: String) -> String? { storage[key] as? String }
    func data(forKey key: String) -> Data? { storage[key] as? Data }
    func object(forKey key: String) -> Any? { storage[key] }

    func set(_ value: Any?, forKey key: String) {
        if let value { storage[key] = value } else { storage.removeValue(forKey: key) }
    }
    func removeObject(forKey key: String) { storage.removeValue(forKey: key) }
}

// MARK: - SecureStore

final class InMemorySecureStore: SecureStore {
    private struct ItemKey: Hashable { let service: String; let account: String }
    private var storage: [ItemKey: Data] = [:]

    func data(forAccount account: String, service: String) throws -> Data? {
        storage[ItemKey(service: service, account: account)]
    }
    func set(_ data: Data, forAccount account: String, service: String) throws {
        storage[ItemKey(service: service, account: account)] = data
    }
    func removeItem(forAccount account: String, service: String) throws {
        storage.removeValue(forKey: ItemKey(service: service, account: account))
    }
    func accounts(forService service: String) throws -> [String] {
        storage.keys.filter { $0.service == service }.map { $0.account }
    }
    func removeAllItems(forService service: String) throws {
        for key in storage.keys where key.service == service { storage.removeValue(forKey: key) }
    }
}

// MARK: - HTTPClient

final class StubHTTPClient: HTTPClient {
    var responder: (HTTPRequest) throws -> HTTPResponse
    private(set) var sentRequests: [HTTPRequest] = []

    init(responder: @escaping (HTTPRequest) throws -> HTTPResponse = { _ in HTTPResponse(statusCode: 200, data: Data()) }) {
        self.responder = responder
    }

    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        sentRequests.append(request)
        return try responder(request)
    }
}

// MARK: - FileSystem

final class InMemoryReadHandle: FileReadHandle {
    private let data: Data
    private var offset = 0
    init(data: Data) { self.data = data }

    func read(upToCount count: Int) throws -> Data {
        let end = min(offset + count, data.count)
        guard offset < end else { return Data() }
        defer { offset = end }
        return data.subdata(in: offset..<end)
    }
    func seek(toOffset newOffset: UInt64) throws { offset = Int(newOffset) }
    func close() throws {}
}

final class InMemoryFileSystem: FileSystem {
    private var files: [String: Data] = [:]
    private var directories: Set<String> = []
    private var permissions: [String: Int] = [:]
    private let tempDir = URL(fileURLWithPath: "/tmp/appboxcore-inmemory", isDirectory: true)
    private var counter = 0

    func temporaryDirectory() -> URL { tempDir }

    func createUniqueDirectory(permissions perms: Int?) throws -> URL {
        counter += 1
        let url = tempDir.appendingPathComponent("dir-\(counter)", isDirectory: true)
        try createDirectory(at: url, permissions: perms)
        return url
    }
    func createDirectory(at url: URL, permissions perms: Int?) throws {
        directories.insert(url.path)
        if let perms { permissions[url.path] = perms }
    }
    func fileExists(at url: URL) -> Bool { files[url.path] != nil || directories.contains(url.path) }
    func removeItem(at url: URL) throws {
        files.removeValue(forKey: url.path)
        directories.remove(url.path)
        permissions.removeValue(forKey: url.path)
    }
    func attributes(of url: URL) throws -> FileAttributes {
        if let data = files[url.path] {
            return FileAttributes(size: Int64(data.count), posixPermissions: permissions[url.path])
        }
        if directories.contains(url.path) {
            return FileAttributes(size: 0, posixPermissions: permissions[url.path])
        }
        throw CocoaError(.fileNoSuchFile)
    }
    func read(contentsOf url: URL) throws -> Data {
        guard let data = files[url.path] else { throw CocoaError(.fileNoSuchFile) }
        return data
    }
    func write(_ data: Data, to url: URL) throws { files[url.path] = data }
    func openForReading(_ url: URL) throws -> FileReadHandle {
        guard let data = files[url.path] else { throw CocoaError(.fileNoSuchFile) }
        return InMemoryReadHandle(data: data)
    }
}

// MARK: - DateProvider / Reachability / ProgressReporter

final class FixedDateProvider: DateProvider {
    var date: Date
    init(_ date: Date) { self.date = date }
    func now() -> Date { date }
}

final class StubReachability: Reachability {
    var isConnected: Bool
    init(isConnected: Bool = true) { self.isConnected = isConnected }
}

final class RecordingProgressReporter: ProgressReporter {
    struct Entry: Equatable { let stage: UploadStage; let message: String?; let fraction: Double? }
    private(set) var entries: [Entry] = []

    func report(stage: UploadStage, message: String?, fractionCompleted: Double?) {
        entries.append(Entry(stage: stage, message: message, fraction: fractionCompleted))
    }
    var stages: [UploadStage] { entries.map(\.stage) }
}

// MARK: - DropboxAccessTokenProviding

final class StubTokenProvider: DropboxAccessTokenProviding {
    var token: String?
    init(token: String? = "stub-dropbox-token") { self.token = token }
    func currentAccessToken() async -> String? { token }
}

// MARK: - StorageProvider

final class FakeStorageProvider: StorageProvider {
    let id: StorageProviderID
    private(set) var currentAccount: StorageAccount?

    var accountToReturn: StorageAccount
    var uploadError: Error?
    var shareableLink: ShareableLink
    private(set) var uploadedFiles: [(local: URL, remote: RemotePath)] = []
    private(set) var deletedPaths: [RemotePath] = []

    init(id: StorageProviderID = .dropbox,
         account: StorageAccount? = nil,
         shareableLink: ShareableLink = ShareableLink(url: URL(string: "https://example.com/dl")!, isDirectDownload: true)) {
        self.id = id
        self.currentAccount = account
        self.accountToReturn = account ?? StorageAccount(providerID: id, accountID: "fake-account")
        self.shareableLink = shareableLink
    }

    func authenticate() async throws -> StorageAccount {
        currentAccount = accountToReturn
        return accountToReturn
    }
    func signOut() throws { currentAccount = nil }

    func upload(fileAt localURL: URL, to remotePath: RemotePath, progress: ((Double) -> Void)?) async throws {
        if let uploadError { throw uploadError }
        progress?(1.0)
        uploadedFiles.append((localURL, remotePath))
    }

    func createShareableLink(for remotePath: RemotePath) async throws -> ShareableLink { shareableLink }
    func existingShareableLink(for remotePath: RemotePath) async throws -> ShareableLink? { shareableLink }
    func listRevisions(for remotePath: RemotePath) async throws -> [RemoteRevision] { [] }
    func delete(at remotePath: RemotePath) async throws { deletedPaths.append(remotePath) }
    private(set) var downloadedPaths: [RemotePath] = []
    func download(from remotePath: RemotePath, to localURL: URL) async throws { downloadedPaths.append(remotePath) }

    private(set) var uploadPreconditions: [String?] = []
    private var revisionsByPath: [String: Int] = [:]

    func upload(fileAt localURL: URL, to remotePath: RemotePath,
                ifRevisionMatches precondition: String?, progress: ((Double) -> Void)?) async throws -> String? {
        uploadPreconditions.append(precondition)
        if let precondition, precondition != currentRevision(of: remotePath) {
            throw StorageError.conflict("fake: revision mismatch")
        }
        try await upload(fileAt: localURL, to: remotePath, progress: progress)
        let next = (revisionsByPath[remotePath.path] ?? 0) + 1
        revisionsByPath[remotePath.path] = next
        return "r\(next)"
    }

    func downloadWithRevision(from remotePath: RemotePath, to localURL: URL) async throws -> String? {
        try await download(from: remotePath, to: localURL)
        return currentRevision(of: remotePath)
    }

    private func currentRevision(of path: RemotePath) -> String? {
        revisionsByPath[path.path].map { "r\($0)" }
    }
}
