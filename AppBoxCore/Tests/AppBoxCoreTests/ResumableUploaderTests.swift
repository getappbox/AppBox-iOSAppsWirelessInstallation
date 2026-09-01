import XCTest
@testable import AppBoxCore

final class ResumableUploaderTests: XCTestCase {

    // MARK: - Fakes

    private struct MemoryChunkSource: ChunkSource {
        let data: Data
        var totalSize: Int { data.count }
        func read(at offset: Int, maxLength: Int) throws -> Data {
            guard offset < data.count else { return Data() }
            return data.subdata(in: offset..<min(offset + maxLength, data.count))
        }
        func close() {}
    }

    /// Models Dropbox's authoritative-offset behaviour: a commit at the wrong offset returns `incorrectOffset(committedOffset)`.
    private final class FakeSession: ChunkUploadSession {
        private(set) var committed: [(offset: Int, data: Data)] = []
        private(set) var committedOffset = 0
        private(set) var startCalls = 0
        private(set) var appendCalls = 0
        private(set) var finishCalls = 0

        var onStart: (() -> SessionStartResult?)?
        var onAppend: ((_ offset: Int, _ data: Data, _ callIndex: Int) -> ChunkResult?)?
        var onFinish: ((_ offset: Int, _ data: Data, _ callIndex: Int) -> ChunkResult?)?

        func start(data: Data, progress: @escaping (Int) -> Void) async -> SessionStartResult {
            startCalls += 1
            progress(data.count)
            if let scripted = onStart?() { return scripted }
            committed.append((0, data)); committedOffset = data.count
            return .started(sessionID: "sess-1")
        }
        func append(sessionID: String, offset: Int, data: Data, progress: @escaping (Int) -> Void) async -> ChunkResult {
            appendCalls += 1
            progress(data.count)
            if let scripted = onAppend?(offset, data, appendCalls) { return scripted }
            return commit(offset, data)
        }
        func finish(sessionID: String, offset: Int, data: Data, progress: @escaping (Int) -> Void) async -> ChunkResult {
            finishCalls += 1
            progress(data.count)
            if let scripted = onFinish?(offset, data, finishCalls) { return scripted }
            return commit(offset, data)
        }
        private func commit(_ offset: Int, _ data: Data) -> ChunkResult {
            guard offset == committedOffset else { return .incorrectOffset(expectedOffset: committedOffset) }
            committed.append((offset, data)); committedOffset += data.count
            return .committed
        }
        /// Force-commit a chunk server-side (a "phantom commit" the client perceived as a failure).
        func phantomCommit(_ offset: Int, _ data: Data) {
            committed.append((offset, data)); committedOffset = offset + data.count
        }
        var reconstructed: Data {
            committed.sorted { $0.offset < $1.offset }.reduce(Data()) { $0 + $1.data }
        }
    }

    /// Reports "offline" for the first `connectAfterChecks` reads, then "online".
    private final class FlakyReachability: Reachability {
        private var checks = 0
        let connectAfterChecks: Int
        init(connectAfterChecks: Int) { self.connectAfterChecks = connectAfterChecks }
        var isConnected: Bool { checks += 1; return checks > connectAfterChecks }
    }

    private func bytes(_ n: Int) -> Data { Data((0..<n).map { UInt8($0 % 251) }) }

    // MARK: - Tests

    func testHappyMultiChunkUploadsInOrderAndReconstructs() async throws {
        let data = bytes(250)
        let session = FakeSession()
        var fractions: [Double] = []
        try await ResumableUploader(chunkSize: 100)
            .upload(source: MemoryChunkSource(data: data), session: session) { fractions.append($0) }

        XCTAssertEqual(session.reconstructed, data)
        XCTAssertEqual(session.committed.map(\.offset), [0, 100, 200])
        XCTAssertEqual(session.finishCalls, 1)
        XCTAssertEqual(fractions.last, 1.0)
        XCTAssertEqual(fractions, fractions.sorted(), "progress should be non-decreasing on the happy path")
    }

    func testSmallFileStartsThenFinishesEmpty() async throws {
        let data = bytes(30)
        let session = FakeSession()
        try await ResumableUploader(chunkSize: 100)
            .upload(source: MemoryChunkSource(data: data), session: session)
        XCTAssertEqual(session.reconstructed, data)
        XCTAssertEqual(session.startCalls, 1)
        XCTAssertEqual(session.finishCalls, 1)
        XCTAssertEqual(session.appendCalls, 0)
    }

    func testTransientFailureRetriesSameChunkWithoutRestart() async throws {
        let data = bytes(250)
        let session = FakeSession()
        session.onAppend = { _, _, callIndex in callIndex == 1 ? .failure(.network("flaky")) : nil }

        try await ResumableUploader(chunkSize: 100)
            .upload(source: MemoryChunkSource(data: data), session: session)

        XCTAssertEqual(session.reconstructed, data)
        XCTAssertEqual(session.appendCalls, 2)
        XCTAssertEqual(session.startCalls, 1)
    }

    func testIncorrectOffsetResyncsAfterPhantomCommit() async throws {
        let data = bytes(250)
        let session = FakeSession()
        session.onAppend = { offset, data, callIndex in
            if callIndex == 1 {
                session.phantomCommit(offset, data)
                return .failure(.network("dropped after commit"))
            }
            return nil
        }

        try await ResumableUploader(chunkSize: 100)
            .upload(source: MemoryChunkSource(data: data), session: session)

        XCTAssertEqual(session.reconstructed, data, "resync should reconstruct the full file exactly")
        XCTAssertEqual(session.committedOffset, 250)
    }

    func testExhaustedRetriesThrows() async throws {
        let session = FakeSession()
        session.onAppend = { _, _, _ in .failure(.network("always")) }
        do {
            try await ResumableUploader(chunkSize: 100, maxRetriesPerChunk: 2)
                .upload(source: MemoryChunkSource(data: bytes(250)), session: session)
            XCTFail("expected failure after exhausting retries")
        } catch let error as StorageError {
            XCTAssertEqual(error, .network("always"))
            XCTAssertEqual(session.appendCalls, 3)
        }
    }

    func testNonRetryableFailurePropagatesImmediately() async throws {
        let session = FakeSession()
        session.onAppend = { _, _, _ in .failure(.notAuthenticated) }
        do {
            try await ResumableUploader(chunkSize: 100)
                .upload(source: MemoryChunkSource(data: bytes(250)), session: session)
            XCTFail("expected the non-retryable error to propagate")
        } catch let error as StorageError {
            XCTAssertEqual(error, .notAuthenticated)
            XCTAssertEqual(session.appendCalls, 1)
        }
    }

    func testPausesUntilOnlineThenResumesWithoutConsumingRetryBudget() async throws {
        let data = bytes(250)
        let session = FakeSession()
        session.onAppend = { _, _, callIndex in callIndex == 1 ? .failure(.network("offline")) : nil }
        let reachability = FlakyReachability(connectAfterChecks: 1)

        try await ResumableUploader(chunkSize: 100, maxRetriesPerChunk: 0,
                                    reachability: reachability, pollNanoseconds: 0)
            .upload(source: MemoryChunkSource(data: data), session: session)

        XCTAssertEqual(session.reconstructed, data)
        XCTAssertEqual(session.appendCalls, 2)
    }

    func testStartRetriesOnTransientFailure() async throws {
        let session = FakeSession()
        var startAttempts = 0
        session.onStart = {
            startAttempts += 1
            return startAttempts == 1 ? .failure(.server("5xx")) : nil
        }
        try await ResumableUploader(chunkSize: 100)
            .upload(source: MemoryChunkSource(data: bytes(120)), session: session)
        XCTAssertEqual(session.startCalls, 2)
        XCTAssertEqual(session.reconstructed, bytes(120))
    }
}
