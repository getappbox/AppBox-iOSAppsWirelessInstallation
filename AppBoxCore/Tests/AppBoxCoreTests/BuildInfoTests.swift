import XCTest
@testable import AppBoxCore

final class BuildInfoTests: XCTestCase {

    func testModuleNameIsAppBoxCore() {
        XCTAssertEqual(ABCoreBuildInfo.moduleName, "AppBoxCore")
    }

    func testIsLinkedReturnsTrue() {
        XCTAssertTrue(ABCoreBuildInfo.isLinked())
    }
}
