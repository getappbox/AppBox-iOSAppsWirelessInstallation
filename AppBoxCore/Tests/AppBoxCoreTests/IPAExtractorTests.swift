import XCTest
import ZIPFoundation
@testable import AppBoxCore

final class ExtractedIPALocatorTests: XCTestCase {

    func testLocatesPayloadInfoPlistAndProvision() {
        let entries = [
            "Payload/",
            "Payload/MyApp.app/",
            "Payload/MyApp.app/Info.plist",
            "Payload/MyApp.app/embedded.mobileprovision",
            "Payload/MyApp.app/Assets.car"
        ]
        let layout = ExtractedIPALocator.locate(entries: entries)
        XCTAssertEqual(layout?.payloadAppPath, "Payload/MyApp.app")
        XCTAssertEqual(layout?.infoPlistPath, "Payload/MyApp.app/Info.plist")
        XCTAssertEqual(layout?.mobileProvisionPath, "Payload/MyApp.app/embedded.mobileprovision")
    }

    func testProvisionOptional() {
        let entries = ["Payload/MyApp.app/Info.plist"]
        let layout = ExtractedIPALocator.locate(entries: entries)
        XCTAssertEqual(layout?.payloadAppPath, "Payload/MyApp.app")
        XCTAssertNil(layout?.mobileProvisionPath)
    }

    func testNilWhenNoApp() {
        XCTAssertNil(ExtractedIPALocator.locate(entries: ["readme.txt", "Foo/bar.plist"]))
    }

    func testNilWhenNoInfoPlist() {
        XCTAssertNil(ExtractedIPALocator.locate(entries: ["Payload/MyApp.app/", "Payload/MyApp.app/Assets.car"]))
    }

    func testCaseInsensitiveInfoPlistMatch() {
        let entries = ["Payload/MyApp.app/info.plist"]
        XCTAssertEqual(ExtractedIPALocator.locate(entries: entries)?.infoPlistPath, "Payload/MyApp.app/info.plist")
    }
}

final class IPAExtractorTests: XCTestCase {

    func testExtractsAndLocatesFromRealZip() throws {
        let fileManager = FileManager.default
        let tmp = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tmp) }

        let appDir = tmp.appendingPathComponent("Payload/MyApp.app", isDirectory: true)
        try fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        try Data("plist".utf8).write(to: appDir.appendingPathComponent("Info.plist"))
        try Data("profile".utf8).write(to: appDir.appendingPathComponent("embedded.mobileprovision"))

        let ipa = tmp.appendingPathComponent("app.ipa")
        try fileManager.zipItem(at: tmp.appendingPathComponent("Payload"), to: ipa)

        let outDir = tmp.appendingPathComponent("out", isDirectory: true)
        let extracted = try IPAExtractor(archiveExtractor: ZipFoundationArchiveExtractor())
            .extract(ipaAt: ipa, to: outDir)

        XCTAssertTrue(fileManager.fileExists(atPath: extracted.infoPlistURL.path))
        XCTAssertEqual(try String(contentsOf: extracted.infoPlistURL, encoding: .utf8), "plist")
        XCTAssertNotNil(extracted.mobileProvisionURL)
        XCTAssertTrue(fileManager.fileExists(atPath: extracted.mobileProvisionURL!.path))
    }

    func testThrowsOnNonIPAZip() throws {
        let fileManager = FileManager.default
        let tmp = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tmp) }

        let junk = tmp.appendingPathComponent("junk", isDirectory: true)
        try fileManager.createDirectory(at: junk, withIntermediateDirectories: true)
        try Data("x".utf8).write(to: junk.appendingPathComponent("readme.txt"))
        let zip = tmp.appendingPathComponent("junk.zip")
        try fileManager.zipItem(at: junk, to: zip)

        XCTAssertThrowsError(
            try IPAExtractor(archiveExtractor: ZipFoundationArchiveExtractor())
                .extract(ipaAt: zip, to: tmp.appendingPathComponent("out"))
        )
    }
}
