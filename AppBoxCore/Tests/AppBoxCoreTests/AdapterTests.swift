import XCTest
@testable import AppBoxCore

final class AdapterTests: XCTestCase {

    func testUserDefaultsStore_roundTripAndRemove() throws {
        let suiteName = "AppBoxCoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsKeyValueStore(defaults: defaults)

        store.set("hello", forKey: "greeting")
        store.set(true, forKey: "flag")
        store.set(42, forKey: "count")

        XCTAssertEqual(store.string(forKey: "greeting"), "hello")
        XCTAssertTrue(store.bool(forKey: "flag"))
        XCTAssertEqual(store.integer(forKey: "count"), 42)

        store.removeObject(forKey: "greeting")
        XCTAssertNil(store.string(forKey: "greeting"))
    }

    func testFileSystem_uniqueDirectoryIsOwnerOnly() throws {
        let fs = FileManagerFileSystem()
        let dir = try fs.createUniqueDirectory(permissions: 0o700)
        defer { try? fs.removeItem(at: dir) }

        XCTAssertTrue(fs.fileExists(at: dir))
        XCTAssertEqual(try fs.attributes(of: dir).posixPermissions, 0o700)
    }

    func testFileSystem_uniqueDirectoriesDiffer() throws {
        let fs = FileManagerFileSystem()
        let a = try fs.createUniqueDirectory()
        let b = try fs.createUniqueDirectory()
        defer { try? fs.removeItem(at: a); try? fs.removeItem(at: b) }
        XCTAssertNotEqual(a, b)
    }

    func testFileSystem_writeReadAndChunkedRead() throws {
        let fs = FileManagerFileSystem()
        let dir = try fs.createUniqueDirectory()
        defer { try? fs.removeItem(at: dir) }
        let file = dir.appendingPathComponent("data.bin")
        let payload = Data((0..<10).map { UInt8($0) })
        try fs.write(payload, to: file)

        XCTAssertEqual(try fs.read(contentsOf: file), payload)
        XCTAssertEqual(try fs.attributes(of: file).size, 10)

        let handle = try fs.openForReading(file)
        defer { try? handle.close() }
        XCTAssertEqual(Array(try handle.read(upToCount: 4)), [0, 1, 2, 3])
        try handle.seek(toOffset: 8)
        XCTAssertEqual(Array(try handle.read(upToCount: 100)), [8, 9])
    }

    func testSystemDateProvider_returnsCurrentTime() {
        let before = Date()
        let now = SystemDateProvider().now()
        let after = Date()
        XCTAssertGreaterThanOrEqual(now, before)
        XCTAssertLessThanOrEqual(now, after)
    }
}
