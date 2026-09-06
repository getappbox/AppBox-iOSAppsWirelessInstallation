import Foundation
import SwiftyDropbox

/// `StorageProvider` backed by the SwiftyDropbox SDK.
public final class DropboxStorageProvider: StorageProvider {

    public let id: StorageProviderID = .dropbox
    public private(set) var currentAccount: StorageAccount?

    private let clientProvider: () -> DropboxClient?
    /// Chunk size for the upload-session path (large files).
    private let chunkSizeBytes: Int
    /// Files larger than this go through a chunked upload session; the single-shot API rejects uploads over 150 MB.
    private let chunkThresholdBytes: Int
    /// Optional reachability so the chunked uploader can pause-until-online instead of failing.
    private let reachability: Reachability?

    public init(clientProvider: @escaping () -> DropboxClient?,
                chunkSizeBytes: Int = 100 * 1024 * 1024,
                chunkThresholdBytes: Int = 150 * 1_000_000,
                reachability: Reachability? = nil) {
        self.clientProvider = clientProvider
        self.chunkSizeBytes = max(chunkSizeBytes, 1)
        self.chunkThresholdBytes = chunkThresholdBytes
        self.reachability = reachability
    }

    private func requireClient() throws -> DropboxClient {
        guard let client = clientProvider() else { throw StorageError.notAuthenticated }
        return client
    }

    // MARK: Auth

    @discardableResult
    public func authenticate() async throws -> StorageAccount {
        guard clientProvider() != nil else { throw StorageError.notAuthenticated }
        let account = StorageAccount(providerID: .dropbox, accountID: "dropbox")
        currentAccount = account
        return account
    }

    public func signOut() throws {
        currentAccount = nil
    }

    // MARK: Upload

    public func upload(fileAt localURL: URL, to remotePath: RemotePath, progress: ((Double) -> Void)?) async throws {
        _ = try await upload(fileAt: localURL, to: remotePath, ifRevisionMatches: nil, progress: progress)
    }

    /// Upload with optimistic concurrency: a non-nil `precondition` becomes `WriteMode.update(rev)` (the write applies only on top of exactly that revision — a concurrent writer surfaces as `StorageError.conflict` instead of being clobbered).
    @discardableResult
    public func upload(fileAt localURL: URL, to remotePath: RemotePath,
                       ifRevisionMatches precondition: String?, progress: ((Double) -> Void)?) async throws -> String? {
        let client = try requireClient()
        let mode: Files.WriteMode = precondition.map { .update($0) } ?? .overwrite

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: localURL.path)[.size] as? Int) ?? nil
        if (fileSize ?? Int.max) > chunkThresholdBytes {
            return try await uploadChunked(client, fileAt: localURL, to: remotePath, mode: mode, progress: progress)
        }

        let data = try Data(contentsOf: localURL)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String?, Error>) in
            client.files.upload(path: remotePath.path, mode: mode, input: data)
                .progress { progressData in
                    progress?(progressData.fractionCompleted)
                }
                .response { metadata, error in
                    if let error {
                        continuation.resume(throwing: DropboxStorageProvider.map(error))
                    } else {
                        progress?(1.0)
                        continuation.resume(returning: metadata?.rev)
                    }
                }
        }
    }

    /// Chunked upload-session path with mid-session resume, driven by the provider-agnostic `ResumableUploader` over a SwiftyDropbox `DropboxChunkUploadSession`.
    @discardableResult
    private func uploadChunked(_ client: DropboxClient, fileAt localURL: URL, to remotePath: RemotePath,
                               mode: Files.WriteMode, progress: ((Double) -> Void)?) async throws -> String? {
        guard let source = FileChunkSource(path: localURL.path) else {
            throw StorageError.unknown("Unable to open the file to upload.")
        }
        let session = DropboxChunkUploadSession(client: client, remotePath: remotePath.path, mode: mode)
        let uploader = ResumableUploader(chunkSize: chunkSizeBytes, reachability: reachability)
        try await uploader.upload(source: source, session: session, progress: progress)
        return session.finishedMetadata?.rev
    }

    // MARK: Shareable links

    private enum CreateLinkOutcome {
        case link(String)
        case alreadyExists
        case failed(StorageError)
    }

    public func createShareableLink(for remotePath: RemotePath) async throws -> ShareableLink {
        let client = try requireClient()
        let outcome: CreateLinkOutcome = await withCheckedContinuation { continuation in
            client.sharing.createSharedLinkWithSettings(path: remotePath.path)
                .response { result, error in
                    if let result {
                        continuation.resume(returning: .link(result.url))
                    } else if case .routeError(let boxed, _, _, _)? = error,
                              case .sharedLinkAlreadyExists = boxed.unboxed {
                        continuation.resume(returning: .alreadyExists)
                    } else {
                        continuation.resume(returning: .failed(DropboxStorageProvider.map(error)))
                    }
                }
        }
        switch outcome {
        case .link(let url):
            return DropboxStorageProvider.shareableLink(url)
        case .alreadyExists:
            if let existing = try await existingShareableLink(for: remotePath) { return existing }
            throw StorageError.conflict("Shared link already exists but could not be fetched")
        case .failed(let error):
            throw error
        }
    }

    public func existingShareableLink(for remotePath: RemotePath) async throws -> ShareableLink? {
        let client = try requireClient()
        let links: [Sharing.SharedLinkMetadata] = try await withCheckedThrowingContinuation { continuation in
            client.sharing.listSharedLinks(path: remotePath.path, directOnly: true)
                .response { result, error in
                    if let result {
                        continuation.resume(returning: result.links)
                    } else {
                        continuation.resume(throwing: DropboxStorageProvider.map(error))
                    }
                }
        }
        return links.first.map { DropboxStorageProvider.shareableLink($0.url) }
    }

    // MARK: Revisions / delete

    public func listRevisions(for remotePath: RemotePath) async throws -> [RemoteRevision] {
        let client = try requireClient()
        let result: Files.ListRevisionsResult = try await withCheckedThrowingContinuation { continuation in
            client.files.listRevisions(path: remotePath.path)
                .response { result, error in
                    if let result {
                        continuation.resume(returning: result)
                    } else {
                        continuation.resume(throwing: DropboxStorageProvider.map(error))
                    }
                }
        }
        return result.entries.map {
            RemoteRevision(revisionID: $0.rev, modified: $0.serverModified, size: Int64($0.size))
        }
    }

    public func delete(at remotePath: RemotePath) async throws {
        let client = try requireClient()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            client.files.deleteV2(path: remotePath.path)
                .response { _, error in
                    if let error {
                        continuation.resume(throwing: DropboxStorageProvider.map(error))
                    } else {
                        continuation.resume()
                    }
                }
        }
    }

    public func download(from remotePath: RemotePath, to localURL: URL) async throws {
        _ = try await downloadWithRevision(from: remotePath, to: localURL)
    }

    /// Download returning the file's current rev — the base revision for a subsequent `ifRevisionMatches` upload of the same file.
    @discardableResult
    public func downloadWithRevision(from remotePath: RemotePath, to localURL: URL) async throws -> String? {
        let client = try requireClient()
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String?, Error>) in
            client.files.download(path: remotePath.path, overwrite: true, destination: localURL)
                .response { result, error in
                    if let error {
                        continuation.resume(throwing: DropboxStorageProvider.map(error))
                    } else {
                        continuation.resume(returning: result?.0.rev)
                    }
                }
        }
    }

    // MARK: Helpers

    /// Normalize a Dropbox share URL the way AppBox's dashboard expects: drop the `dl` query param, keep the `rlkey` (`DropboxTransport.normalizedShareURL`).
    static func shareableLink(_ urlString: String) -> ShareableLink {
        let normalized = DropboxTransport.normalizedShareURL(urlString)
        let url = URL(string: normalized) ?? URL(string: urlString) ?? URL(fileURLWithPath: "/")
        return ShareableLink(url: url, isDirectDownload: false)
    }

    /// Collapse SwiftyDropbox's `CallError` into the provider-agnostic `StorageError`.
    static func map<E>(_ error: CallError<E>?) -> StorageError {
        guard let error else { return .unknown("Unknown Dropbox error") }
        switch error {
        case .authError, .accessError:
            return .notAuthenticated
        case .rateLimitError(let rateLimitError, _, _, _):
            return .rateLimited(retryAfter: TimeInterval(rateLimitError.retryAfter))
        case .internalServerError(let code, let message, _):
            return .server("HTTP \(code): \(message ?? "")")
        case .httpError(let code, let message, _):
            if let code, (500..<600).contains(code) { return .server("HTTP \(code): \(message ?? "")") }
            return .unknown("HTTP \(code.map(String.init) ?? "?"): \(message ?? "HTTP error")")
        case .reconnectionError, .clientError:
            return .network(String(describing: error))
        case .routeError(let boxed, _, _, _):
            if isPathNotFound(boxed.unboxed) { return .notFound }
            if isWriteConflict(boxed.unboxed) {
                return .conflict("The file changed on Dropbox while this operation was running "
                                 + "(another AppBox may be uploading or deleting the same app). Please retry.")
            }
            return .unknown(String(describing: error))
        case .badInputError(let message, _):
            return .unknown(message ?? "Bad input")
        case .serializationError:
            return .unknown(String(describing: error))
        }
    }

    /// Whether an upload route error is a write-conflict (the `WriteMode.update(rev)` precondition failed because the remote file changed).
    private static func isWriteConflict(_ routeError: Any) -> Bool {
        guard let uploadError = routeError as? Files.UploadError,
              case .path(let writeFailed) = uploadError,
              case .conflict = writeFailed.reason else { return false }
        return true
    }

    /// Whether a route error is a path-lookup "not found" for the routes the pipeline uses.
    private static func isPathNotFound(_ routeError: Any) -> Bool {
        switch routeError {
        case let deleteError as Files.DeleteError:
            if case .pathLookup(let lookup) = deleteError, case .notFound = lookup { return true }
        case let downloadError as Files.DownloadError:
            if case .path(let lookup) = downloadError, case .notFound = lookup { return true }
        case let listError as Files.ListRevisionsError:
            if case .path(let lookup) = listError, case .notFound = lookup { return true }
        case let metadataError as Files.GetMetadataError:
            if case .path(let lookup) = metadataError, case .notFound = lookup { return true }
        default:
            break
        }
        return false
    }
}
