import Foundation
import SwiftyDropbox

/// SwiftyDropbox-backed `ChunkUploadSession` (uploadSessionStart → AppendV2 … → Finish).
final class DropboxChunkUploadSession: ChunkUploadSession {
    private let client: DropboxClient
    private let commit: Files.CommitInfo
    /// Set when `finish` succeeds — the committed file's path/rev, for callers that need it.
    private(set) var finishedMetadata: RemoteFileRef?

    init(client: DropboxClient, remotePath: String, mode: Files.WriteMode) {
        self.client = client
        self.commit = Files.CommitInfo(path: remotePath, mode: mode, autorename: false, mute: false)
    }

    func start(data: Data, progress: @escaping (Int) -> Void) async -> SessionStartResult {
        await withCheckedContinuation { (continuation: CheckedContinuation<SessionStartResult, Never>) in
            client.files.uploadSessionStart(input: data)
                .progress { p in progress(Int(p.completedUnitCount)) }
                .response(queue: .main) { result, error in
                    if let result {
                        continuation.resume(returning: .started(sessionID: result.sessionId))
                    } else {
                        continuation.resume(returning: .failure(DropboxStorageProvider.map(error)))
                    }
                }
        }
    }

    func append(sessionID: String, offset: Int, data: Data, progress: @escaping (Int) -> Void) async -> ChunkResult {
        let cursor = Files.UploadSessionCursor(sessionId: sessionID, offset: UInt64(offset))
        return await withCheckedContinuation { (continuation: CheckedContinuation<ChunkResult, Never>) in
            client.files.uploadSessionAppendV2(cursor: cursor, input: data)
                .progress { p in progress(Int(p.completedUnitCount)) }
                .response(queue: .main) { result, error in
                    if result != nil {
                        continuation.resume(returning: .committed)
                    } else if case .routeError(let boxed, _, _, _)? = error,
                              case .incorrectOffset(let offsetError) = boxed.unboxed {
                        continuation.resume(returning: .incorrectOffset(expectedOffset: Int(offsetError.correctOffset)))
                    } else {
                        continuation.resume(returning: .failure(DropboxStorageProvider.map(error)))
                    }
                }
        }
    }

    func finish(sessionID: String, offset: Int, data: Data, progress: @escaping (Int) -> Void) async -> ChunkResult {
        let cursor = Files.UploadSessionCursor(sessionId: sessionID, offset: UInt64(offset))
        return await withCheckedContinuation { (continuation: CheckedContinuation<ChunkResult, Never>) in
            client.files.uploadSessionFinish(cursor: cursor, commit: commit, input: data)
                .progress { p in progress(Int(p.completedUnitCount)) }
                .response(queue: .main) { result, error in
                    if let result {
                        self.finishedMetadata = RemoteFileRef(pathDisplay: result.pathDisplay ?? self.commit.path, rev: result.rev)
                        continuation.resume(returning: .committed)
                    } else if case .routeError(let boxed, _, _, _)? = error,
                              case .lookupFailed(let lookup) = boxed.unboxed,
                              case .incorrectOffset(let offsetError) = lookup {
                        continuation.resume(returning: .incorrectOffset(expectedOffset: Int(offsetError.correctOffset)))
                    } else {
                        continuation.resume(returning: .failure(DropboxStorageProvider.map(error)))
                    }
                }
        }
    }
}
