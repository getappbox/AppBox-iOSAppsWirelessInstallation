import XCTest
@testable import AppBoxCore

final class InstallLinkTests: XCTestCase {

    func testMake_wrapsDropboxSharePathIntoInstallPage() {
        let url = InstallLink.make(fromDropboxShareURL:
            URL(string: "https://www.dropbox.com/scl/fi/abc/appinfo.json?rlkey=xyz")!)
        XCTAssertEqual(url?.absoluteString, "https://web.getappbox.com?url=/scl/fi/abc/appinfo.json?rlkey=xyz")
    }

    func testMake_handlesLegacySPath() {
        let url = InstallLink.make(fromDropboxShareURL:
            URL(string: "https://www.dropbox.com/s/abc/appinfo.json")!)
        XCTAssertEqual(url?.absoluteString, "https://web.getappbox.com?url=/s/abc/appinfo.json")
    }

    func testMake_escapesASecondQueryParameterSoItStaysInsideTheURLValue() {
        let url = InstallLink.make(fromDropboxShareURL:
            URL(string: "https://www.dropbox.com/scl/fi/abc/appinfo.json?rlkey=xyz&st=tok")!)
        XCTAssertEqual(url?.absoluteString,
                       "https://web.getappbox.com?url=/scl/fi/abc/appinfo.json?rlkey=xyz%26st=tok")

        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        XCTAssertEqual(components?.queryItems?.count, 1)
        XCTAssertEqual(components?.queryItems?.first?.value, "/scl/fi/abc/appinfo.json?rlkey=xyz&st=tok")
    }

    func testMake_returnsNilForNonDropboxURL() {
        XCTAssertNil(InstallLink.make(fromDropboxShareURL: URL(string: "https://example.com/x/appinfo.json")!))
    }

    func testMake_customBase() {
        let url = InstallLink.make(fromDropboxShareURL:
            URL(string: "https://www.dropbox.com/scl/fi/abc/appinfo.json?rlkey=xyz")!,
            base: "https://web2.getappbox.com")
        XCTAssertEqual(url?.absoluteString, "https://web2.getappbox.com?url=/scl/fi/abc/appinfo.json?rlkey=xyz")
    }
}
