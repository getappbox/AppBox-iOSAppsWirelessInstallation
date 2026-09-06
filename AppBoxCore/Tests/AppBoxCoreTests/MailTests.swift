import XCTest
@testable import AppBoxCore

final class EmailValidatorTests: XCTestCase {

    func testValidSingleEmails() {
        XCTAssertTrue(EmailValidator.isValidEmail("user@example.com"))
        XCTAssertTrue(EmailValidator.isValidEmail("user@mail.example.com"))
        XCTAssertTrue(EmailValidator.isValidEmail("user+tag@example.com"))
        XCTAssertTrue(EmailValidator.isValidEmail("first.last@example.co"))
        XCTAssertTrue(EmailValidator.isValidEmail("a_b@a-b.com"))
    }

    func testInvalidSingleEmails() {
        XCTAssertFalse(EmailValidator.isValidEmail(""))
        XCTAssertFalse(EmailValidator.isValidEmail("not-an-email"))
        XCTAssertFalse(EmailValidator.isValidEmail("user@"))
        XCTAssertFalse(EmailValidator.isValidEmail("@example.com"))
        XCTAssertFalse(EmailValidator.isValidEmail("user@example"))
        XCTAssertFalse(EmailValidator.isValidEmail("user @example.com"))
        XCTAssertFalse(EmailValidator.isValidEmail("user@@example.com"))
        XCTAssertFalse(EmailValidator.isValidEmail("user@example.c"))
    }

    func testAllValidEmailLists() {
        XCTAssertTrue(EmailValidator.isAllValidEmails("user@example.com"))
        XCTAssertTrue(EmailValidator.isAllValidEmails("a@example.com,b@example.com"))
        XCTAssertTrue(EmailValidator.isAllValidEmails("a@example.com, b@mail.example.com"))
    }

    func testAllValidEmailLists_rejectInvalidMembers() {
        XCTAssertFalse(EmailValidator.isAllValidEmails("a@example.com,not-an-email"))
        XCTAssertFalse(EmailValidator.isAllValidEmails("a@example.com,,b@example.com"))
    }
}

final class BuildNotificationMessageTests: XCTestCase {

    func testGeneratesTheSummaryLine() {
        XCTAssertEqual(
            BuildNotificationMessage.text(name: "AppBox", version: "4.2.0", build: "200",
                                          installURL: "https://appbox.me/x1"),
            "AppBox 4.2.0 (200) is ready to test. Install - https://appbox.me/x1")
    }

    func testIsASingleLine() {
        let text = BuildNotificationMessage.text(name: "AppBox", version: "4.2.0", build: "200",
                                                 installURL: "https://appbox.me/x1")
        XCTAssertFalse(text.contains("\n"))
    }
}
