import XCTest
@testable import AppBoxCore

final class IPANameTests: XCTestCase {

    func testStripSpaces() {
        XCTAssertEqual(IPAName.stripSpaces("My App"), "MyApp")
        XCTAssertEqual(IPAName.stripSpaces("NoSpaces"), "NoSpaces")
        XCTAssertEqual(IPAName.stripSpaces("a b c"), "abc")
    }

    func testSanitizedForURL() {
        XCTAssertEqual(IPAName.sanitizedForURL("MyApp"), "MyApp")
        XCTAssertEqual(IPAName.sanitizedForURL(""), "AppBox")
        XCTAssertEqual(IPAName.sanitizedForURL(nil), "AppBox")
        XCTAssertEqual(IPAName.sanitizedForURL("1.2.3"), "1.2.3")
        XCTAssertEqual(IPAName.sanitizedForURL("/com.example.app"), "/com.example.app")
        XCTAssertEqual(IPAName.sanitizedForURL("App\u{01}Box"), "AppBox")
    }
    func testSanitizedPathComponent_stripsPathStructure() {
        XCTAssertEqual(IPAName.sanitizedPathComponent("MyApp"), "MyApp")
        XCTAssertEqual(IPAName.sanitizedPathComponent("Is?This"), "IsThis")
        XCTAssertEqual(IPAName.sanitizedPathComponent("My/App"), "MyApp")
        XCTAssertEqual(IPAName.sanitizedPathComponent("1.2.3"), "1.2.3")
        XCTAssertEqual(IPAName.sanitizedPathComponent("u+d3/VPg="), "u+d3VPg=")
        XCTAssertEqual(IPAName.sanitizedPathComponent("/"), "AppBox")
        XCTAssertEqual(IPAName.sanitizedPathComponent(nil), "AppBox")
    }

    func testSanitizedPath_keepsSeparatorsButSanitizesEachSegment() {
        XCTAssertEqual(IPAName.sanitizedPath("/com.example.app"), "/com.example.app")
        XCTAssertEqual(IPAName.sanitizedPath("/Custom Folder/Sub"), "/CustomFolder/Sub")
        XCTAssertEqual(IPAName.sanitizedPath("/com.example.app?x"), "/com.example.appx")
        XCTAssertEqual(IPAName.sanitizedPath(""), "AppBox")
        XCTAssertEqual(IPAName.sanitizedPath(nil), "AppBox")
    }
}

final class IPADeviceFamilyTests: XCTestCase {

    func testDescribe() {
        XCTAssertEqual(IPADeviceFamily.describe([1]), "iPhone")
        XCTAssertEqual(IPADeviceFamily.describe([2]), "iPad")
        XCTAssertEqual(IPADeviceFamily.describe([1, 2]), "iPhone and iPad")
        XCTAssertEqual(IPADeviceFamily.describe([]), "")
        XCTAssertEqual(IPADeviceFamily.describe(nil), "")
    }

    func testDescribe_appleTVAndOtherFamilies() {
        XCTAssertEqual(IPADeviceFamily.describe([3]), "Apple TV")
        XCTAssertEqual(IPADeviceFamily.describe([4]), "Apple Watch")
        XCTAssertEqual(IPADeviceFamily.describe([6]), "Mac")
        XCTAssertEqual(IPADeviceFamily.describe([7]), "Apple Vision Pro")
        XCTAssertEqual(IPADeviceFamily.describe([1, 2, 3]), "iPhone and iPad and Apple TV")
        XCTAssertEqual(IPADeviceFamily.describe([5]), "") // unknown family ignored
    }
}
