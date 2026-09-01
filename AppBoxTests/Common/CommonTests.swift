//
//  CommonTests.swift
//  AppBoxTests

import XCTest
@testable import AppBox

final class CommonTests: XCTestCase {

    // MARK: - generateUUID

    func testGenerateUUID_ReturnsNonEmptyString() {
        XCTAssertFalse(Common.generateUUID().isEmpty)
    }

    func testGenerateUUID_DoesNotContainSlashes() {
        XCTAssertFalse(Common.generateUUID().contains("/"))
    }

    func testGenerateUUID_GeneratesUniqueValues() {
        XCTAssertNotEqual(Common.generateUUID(), Common.generateUUID())
    }

    // MARK: - error(withDesc:andCode:)

    func testErrorWithDesc_HasCorrectCode() {
        XCTAssertEqual(Common.error(withDesc: "Test error", andCode: 42).code, 42)
    }

    func testErrorWithDesc_HasCorrectDescription() {
        XCTAssertEqual(Common.error(withDesc: "Something went wrong", andCode: 100).localizedDescription, "Something went wrong")
    }

    func testErrorWithDesc_HasCocoaDomain() {
        XCTAssertEqual(Common.error(withDesc: "Error", andCode: 1).domain, NSCocoaErrorDomain)
    }

    func testErrorWithDesc_WithZeroCode() {
        let error = Common.error(withDesc: "Zero code error", andCode: 0)
        XCTAssertEqual(error.code, 0)
        XCTAssertEqual(error.localizedDescription, "Zero code error")
    }


    // MARK: - getFileDirectory(forFilePath:)

    func testGetFileDirectory_ExtractsParentDirectory() {
        let result = Common.getFileDirectory(forFilePath: URL(string: "/Users/test/Documents/file.ipa"))
        XCTAssertNotNil(result)
        let resultString = result?.absoluteString ?? ""
        XCTAssertTrue(resultString.contains("Documents"))
        XCTAssertFalse(resultString.contains("file.ipa"))
    }

    func testGetFileDirectory_WithNestedPath() {
        let result = Common.getFileDirectory(forFilePath: URL(string: "/a/b/c/d.txt"))
        XCTAssertNotNil(result)
        XCTAssertTrue((result?.absoluteString ?? "").contains("/a/b/c"))
    }
}
