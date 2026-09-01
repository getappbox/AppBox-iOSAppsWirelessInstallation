import XCTest
@testable import AppBoxCore

final class ManifestBuilderTests: XCTestCase {

    private let manifest = ManifestBuilder.make(
        ipaShareableURL: "https://example.com/app.ipa?dl=1",
        name: "AppBox", identifier: "com.example.app", version: "4.2.0")

    func testStructure() {
        XCTAssertEqual(manifest.items.count, 1)
        let item = manifest.items[0]
        XCTAssertEqual(item.assets.count, 1)
        XCTAssertEqual(item.assets[0].kind, "software-package")
        XCTAssertEqual(item.assets[0].url, "https://example.com/app.ipa?dl=1")
        XCTAssertEqual(item.metadata.kind, "software")
        XCTAssertEqual(item.metadata.title, "AppBox")
        XCTAssertEqual(item.metadata.bundleIdentifier, "com.example.app")
        XCTAssertEqual(item.metadata.bundleVersion, "4.2.0")
    }

    func testPlistRoundTrips() throws {
        let data = try ManifestBuilder.plistData(for: manifest)
        let decoded = try PropertyListDecoder().decode(OTAManifest.self, from: data)
        XCTAssertEqual(decoded, manifest)
    }

    func testPlistUsesHyphenatedMetadataKeys() throws {
        let data = try ManifestBuilder.plistData(for: manifest)
        let xml = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(xml.contains("bundle-identifier"))
        XCTAssertTrue(xml.contains("bundle-version"))
        XCTAssertTrue(xml.contains("software-package"))
    }
}
