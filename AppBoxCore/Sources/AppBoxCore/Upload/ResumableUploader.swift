import Foundation

// MARK: - Seams

/// Source of file bytes for a resumable upload.
public protocol ChunkSource {
    var totalSize: Int { get }
    /// Read up to `maxLength` bytes starting at `offset`; fewer (or empty) at EOF.
    func read(at offset: Int, maxLength: Int) throws -> Data
    func close()
}

/// A `ChunkSource` backed by a file on disk (never loads the whole file into memory).
public final class FileChunkSource: ChunkSource {
    private let handle: FileHandle
    public let totalSize: Int

    public init?(path: String) {
        guard let handle = FileHandle(forReadingAtPath: path) else { return nil }
        guard let size = (try? FileManager.default.attributesOfItem(atPath: path))?[.size] as? Int else {
            try? handle.close()
            return nil
        }
        self.handle = handle
        self.totalSize = size
    }

    public func read(at offset: Int, maxLength: Int) throws -> Data {
        try handle.seek(toOffset: UInt64(offset))
        return try handle.read(upToCount: maxLength) ?? Data()
    }

    public func close() { try? handle.close() }
}

/// Outcome of opening an upload session.
public enum SessionStartResult {
    case started(sessionID: String)
    case failure(StorageError)
}

/// Outcome of committing one chunk (append or finish).
public enum ChunkResult {
    case committed
    /// The server's committed offset differs from ours — resync to `expectedOffset` and continue.
    case incorrectOffset(expectedOffset: Int)
    case failure(StorageError)
}

/// Provider-agnostic upload-session primitives (Dropbox: uploadSessionStart/AppendV2/Finish).
public protocol ChunkUploadSession {
    func start(data: Data, progress: @escaping (Int) -> Void) async -> SessionStartResult
    func append(sessionID: String, offset: Int, data: Data, progress: @escaping (Int) -> Void) async -> ChunkResult
    func finish(sessionID: String, offset: Int, data: Data, progress: @escaping (Int) -> Void) async -> ChunkResult
}

// MARK: - Connectivity-aware retry

/// Shared retry decision for the upload pipeline (used by both `ResumableUploader` and `UploadCoordinator`).
struct ConnectivityAwareRetry {
    let maxRetries: Int
    let reachability: Reachability?
    let pollNanoseconds: UInt64

    enum Outcome { case retry(counted: Bool); case fail }

    /// Throws `CancellationError` when the surrounding task is cancelled — every wait in here uses `try await Task.sleep`, so a cancelled upload aborts instead of busy-waiting the poll loop.
    func evaluate(_ error: StorageError, attempts: Int) async throws -> Outcome {
        let kind = UploadFailureKind(error)

        if kind == .connectivity, reachability != nil {
            try await Task.sleep(nanoseconds: pollNanoseconds)
        }

        switch UploadRetryPolicy.decide(failure: kind,
                                        retryCount: attempts,
                                        isConnected: reachability?.isConnected ?? true,
                                        maxRetryCount: maxRetries) {
        case .pauseUntilOnline:
            try await waitUntilConnected()
            return .retry(counted: false)
        case .retry:
            if case .rateLimited(let retryAfter) = error {
                try await Task.sleep(nanoseconds: UInt64(min(max(retryAfter ?? 1, 1), 60)) * 1_000_000_000)
            } else if kind == .retryableServer {
                try await Task.sleep(nanoseconds: pollNanoseconds * UInt64(attempts + 1))
            }
            return .retry(counted: true)
        case .fail:
            return .fail
        }
    }

    private func waitUntilConnected() async throws {
        guard let reachability else { return }
        while !reachability.isConnected {
            try await Task.sleep(nanoseconds: pollNanoseconds)
        }
    }
}

// MARK: - Driver

/// Drives an upload session chunk by chunk with **mid-session resume**: a transient (`isRetryable`) failure retries the *same* chunk in place (no full restart), and a server `incorrectOffset` resyncs to the server's committed offset and continues.
public struct ResumableUploader {
    public let chunkSize: Int
    public let maxRetriesPerChunk: Int
    /// Safety cap on `incorrectOffset` resyncs so a misbehaving server can't loop us forever.
    public let maxResyncs: Int
    private let retry: ConnectivityAwareRetry

    public init(chunkSize: Int,
                maxRetriesPerChunk: Int = UploadRetryPolicy.maxRetryCount,
                maxResyncs: Int = 16,
                reachability: Reachability? = nil,
                pollNanoseconds: UInt64 = 500_000_000) {
        self.chunkSize = max(chunkSize, 1)
        self.maxRetriesPerChunk = maxRetriesPerChunk
        self.maxResyncs = maxResyncs
        self.retry = ConnectivityAwareRetry(maxRetries: maxRetriesPerChunk,
                                            reachability: reachability,
                                            pollNanoseconds: pollNanoseconds)
    }

    public func upload(source: ChunkSource, session: ChunkUploadSession, progress: ((Double) -> Void)? = nil) async throws {
        defer { source.close() }
        let total = source.totalSize
        func report(committed: Int, inChunk: Int) {
            guard total > 0 else { return }
            progress?(min(Double(committed + inChunk) / Double(total), 1.0))
        }

        let firstChunk = try source.read(at: 0, maxLength: chunkSize)
        let sessionID = try await startWithRetry(session, data: firstChunk) { report(committed: 0, inChunk: $0) }
        var offset = firstChunk.count
        report(committed: offset, inChunk: 0)

        var resyncs = 0
        while true {
            let chunk = try source.read(at: offset, maxLength: chunkSize)
            let isLast = offset + chunk.count >= total
            switch try await commitChunk(session, sessionID: sessionID, offset: offset, data: chunk, isLast: isLast,
                                         progress: { report(committed: offset, inChunk: $0) }) {
            case .advanced:
                offset += chunk.count
                report(committed: offset, inChunk: 0)
                if isLast { return }
            case .resync(let expected):
                resyncs += 1
                if resyncs > maxResyncs {
                    throw StorageError.unknown("Upload could not resync after \(maxResyncs) attempts")
                }
                offset = expected
            }
        }
    }

    // MARK: Private

    private enum ChunkProgress { case advanced; case resync(Int) }

    private func startWithRetry(_ session: ChunkUploadSession, data: Data,
                                progress: @escaping (Int) -> Void) async throws -> String {
        var attempts = 0
        while true {
            try Task.checkCancellation()
            switch await session.start(data: data, progress: progress) {
            case .started(let sessionID):
                return sessionID
            case .failure(let error):
                switch try await retry.evaluate(error, attempts: attempts) {
                case .retry(let counted): if counted { attempts += 1 }
                case .fail: throw error
                }
            }
        }
    }

    private func commitChunk(_ session: ChunkUploadSession, sessionID: String, offset: Int, data: Data,
                             isLast: Bool, progress: @escaping (Int) -> Void) async throws -> ChunkProgress {
        var attempts = 0
        while true {
            try Task.checkCancellation()
            let result = isLast
                ? await session.finish(sessionID: sessionID, offset: offset, data: data, progress: progress)
                : await session.append(sessionID: sessionID, offset: offset, data: data, progress: progress)
            switch result {
            case .committed:
                return .advanced
            case .incorrectOffset(let expected):
                return .resync(expected)
            case .failure(let error):
                switch try await retry.evaluate(error, attempts: attempts) {
                case .retry(let counted): if counted { attempts += 1 }
                case .fail: throw error
                }
            }
        }
    }
}
