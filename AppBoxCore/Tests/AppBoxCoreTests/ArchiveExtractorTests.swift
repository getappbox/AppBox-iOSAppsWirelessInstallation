import XCTest
import ZIPFoundation
@testable import AppBoxCore

final class ArchiveExtractorTests: XCTestCase {

    func testExtractsZipContents() throws {
        let fileManager = FileManager.default
        let tmp = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tmp) }

        let sourceDir = tmp.appendingPathComponent("Payload", isDirectory: true)
        try fileManager.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        let file = sourceDir.appendingPathComponent("Info.txt")
        try Data("AppBox".utf8).write(to: file)
        let archive = tmp.appendingPathComponent("app.zip")
        try fileManager.zipItem(at: sourceDir, to: archive)

        let outDir = tmp.appendingPathComponent("out", isDirectory: true)
        try ZipFoundationArchiveExtractor().extract(archiveAt: archive, to: outDir)

        let extracted = outDir.appendingPathComponent("Payload/Info.txt")
        XCTAssertTrue(fileManager.fileExists(atPath: extracted.path))
        XCTAssertEqual(try String(contentsOf: extracted, encoding: .utf8), "AppBox")
    }

    func testExtractCreatesDestinationIfMissing() throws {
        let fileManager = FileManager.default
        let tmp = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tmp) }

        let sourceDir = tmp.appendingPathComponent("src", isDirectory: true)
        try fileManager.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        try Data("x".utf8).write(to: sourceDir.appendingPathComponent("f.txt"))
        let archive = tmp.appendingPathComponent("a.zip")
        try fileManager.zipItem(at: sourceDir, to: archive)

        let outDir = tmp.appendingPathComponent("does/not/exist/yet", isDirectory: true)
        XCTAssertFalse(fileManager.fileExists(atPath: outDir.path))
        try ZipFoundationArchiveExtractor().extract(archiveAt: archive, to: outDir)
        XCTAssertTrue(fileManager.fileExists(atPath: outDir.appendingPathComponent("src/f.txt").path))
    }
}
