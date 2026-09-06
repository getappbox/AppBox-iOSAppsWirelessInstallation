//
//  MailHandlerTests.swift
//  AppBoxTests

import XCTest
@testable import AppBox

final class MailHandlerTests: XCTestCase {

    // MARK: - isValidEmail (single)

    func testIsValidEmail_SimpleValidEmail() { XCTAssertTrue(MailHandler.isValidEmail("user@example.com")) }
    func testIsValidEmail_WithSubdomain() { XCTAssertTrue(MailHandler.isValidEmail("user@mail.example.com")) }
    func testIsValidEmail_WithPlusTag() { XCTAssertTrue(MailHandler.isValidEmail("user+tag@example.com")) }
    func testIsValidEmail_WithDots() { XCTAssertTrue(MailHandler.isValidEmail("first.last@example.com")) }
    func testIsValidEmail_WithUnderscore() { XCTAssertTrue(MailHandler.isValidEmail("user_name@example.com")) }
    func testIsValidEmail_WithHyphenInDomain() { XCTAssertTrue(MailHandler.isValidEmail("user@my-company.com")) }
    func testIsValidEmail_WithNumbers() { XCTAssertTrue(MailHandler.isValidEmail("user123@example456.com")) }
    func testIsValidEmail_WithPercentSign() { XCTAssertTrue(MailHandler.isValidEmail("user%name@example.com")) }
    func testIsValidEmail_WithLongTLD() { XCTAssertTrue(MailHandler.isValidEmail("user@example.technology")) }
    func testIsValidEmail_WithTwoLetterTLD() { XCTAssertTrue(MailHandler.isValidEmail("user@example.io")) }

    func testIsValidEmail_EmptyString_ReturnsNO() { XCTAssertFalse(MailHandler.isValidEmail("")) }
    func testIsValidEmail_NoAtSign_ReturnsNO() { XCTAssertFalse(MailHandler.isValidEmail("userexample.com")) }
    func testIsValidEmail_NoDomain_ReturnsNO() { XCTAssertFalse(MailHandler.isValidEmail("user@")) }
    func testIsValidEmail_NoUsername_ReturnsNO() { XCTAssertFalse(MailHandler.isValidEmail("@example.com")) }
    func testIsValidEmail_NoTLD_ReturnsNO() { XCTAssertFalse(MailHandler.isValidEmail("user@example")) }
    func testIsValidEmail_SpacesInEmail_ReturnsNO() { XCTAssertFalse(MailHandler.isValidEmail("user @example.com")) }
    func testIsValidEmail_DoubleAtSign_ReturnsNO() { XCTAssertFalse(MailHandler.isValidEmail("user@@example.com")) }
    func testIsValidEmail_DotAtEnd_ReturnsNO() { XCTAssertFalse(MailHandler.isValidEmail("user@example.")) }
    func testIsValidEmail_JustText_ReturnsNO() { XCTAssertFalse(MailHandler.isValidEmail("plaintext")) }
    func testIsValidEmail_SingleCharTLD_ReturnsNO() { XCTAssertFalse(MailHandler.isValidEmail("user@example.c")) }
    func testIsValidEmail_MultipleAtSigns_ReturnsNO() { XCTAssertFalse(MailHandler.isValidEmail("user@name@example.com")) }

    // MARK: - isAllValidEmail (comma-separated)

    func testIsAllValidEmail_SingleEmail() { XCTAssertTrue(MailHandler.isAllValidEmail("user@example.com")) }
    func testIsAllValidEmail_TwoEmails() { XCTAssertTrue(MailHandler.isAllValidEmail("user@example.com,admin@test.io")) }
    func testIsAllValidEmail_MultipleEmails() { XCTAssertTrue(MailHandler.isAllValidEmail("a@b.com,c@d.org,e@f.net")) }
    func testIsAllValidEmail_WithSpacesAfterComma() { XCTAssertTrue(MailHandler.isAllValidEmail("user@example.com, admin@test.io")) }
    func testIsAllValidEmail_EmptyString() { XCTAssertTrue(MailHandler.isAllValidEmail("")) }
    func testIsAllValidEmail_InvalidEmail_ReturnsNO() { XCTAssertFalse(MailHandler.isAllValidEmail("notanemail")) }
    func testIsAllValidEmail_MixedValidAndInvalid_ReturnsNO() { XCTAssertFalse(MailHandler.isAllValidEmail("user@example.com,invalid")) }
    func testIsAllValidEmail_DoubleComma_ReturnsNO() { XCTAssertFalse(MailHandler.isAllValidEmail("user@example.com,,admin@test.io")) }

    // MARK: - parseMessage(_:forIPAUploadInfo:)

}
