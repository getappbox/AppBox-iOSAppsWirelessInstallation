//
//  MailHandlerTests.m
//  AppBoxTests
//
//  Created by AppBox on 29/05/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MailHandler.h"
#import "IPAUploadInfo.h"

@interface MailHandlerTests : XCTestCase
@end

@implementation MailHandlerTests

#pragma mark - isValidEmail: Tests (Single Email Regex)

- (void)testIsValidEmail_SimpleValidEmail {
    XCTAssertTrue([MailHandler isValidEmail:@"user@example.com"]);
}

- (void)testIsValidEmail_WithSubdomain {
    XCTAssertTrue([MailHandler isValidEmail:@"user@mail.example.com"]);
}

- (void)testIsValidEmail_WithPlusTag {
    XCTAssertTrue([MailHandler isValidEmail:@"user+tag@example.com"]);
}

- (void)testIsValidEmail_WithDots {
    XCTAssertTrue([MailHandler isValidEmail:@"first.last@example.com"]);
}

- (void)testIsValidEmail_WithUnderscore {
    XCTAssertTrue([MailHandler isValidEmail:@"user_name@example.com"]);
}

- (void)testIsValidEmail_WithHyphenInDomain {
    XCTAssertTrue([MailHandler isValidEmail:@"user@my-company.com"]);
}

- (void)testIsValidEmail_WithNumbers {
    XCTAssertTrue([MailHandler isValidEmail:@"user123@example456.com"]);
}

- (void)testIsValidEmail_WithPercentSign {
    XCTAssertTrue([MailHandler isValidEmail:@"user%name@example.com"]);
}

- (void)testIsValidEmail_WithLongTLD {
    XCTAssertTrue([MailHandler isValidEmail:@"user@example.technology"]);
}

- (void)testIsValidEmail_WithTwoLetterTLD {
    XCTAssertTrue([MailHandler isValidEmail:@"user@example.io"]);
}

- (void)testIsValidEmail_EmptyString_ReturnsNO {
    XCTAssertFalse([MailHandler isValidEmail:@""]);
}

- (void)testIsValidEmail_NoAtSign_ReturnsNO {
    XCTAssertFalse([MailHandler isValidEmail:@"userexample.com"]);
}

- (void)testIsValidEmail_NoDomain_ReturnsNO {
    XCTAssertFalse([MailHandler isValidEmail:@"user@"]);
}

- (void)testIsValidEmail_NoUsername_ReturnsNO {
    XCTAssertFalse([MailHandler isValidEmail:@"@example.com"]);
}

- (void)testIsValidEmail_NoTLD_ReturnsNO {
    XCTAssertFalse([MailHandler isValidEmail:@"user@example"]);
}

- (void)testIsValidEmail_SpacesInEmail_ReturnsNO {
    XCTAssertFalse([MailHandler isValidEmail:@"user @example.com"]);
}

- (void)testIsValidEmail_DoubleAtSign_ReturnsNO {
    XCTAssertFalse([MailHandler isValidEmail:@"user@@example.com"]);
}

- (void)testIsValidEmail_DotAtEnd_ReturnsNO {
    XCTAssertFalse([MailHandler isValidEmail:@"user@example."]);
}

- (void)testIsValidEmail_JustText_ReturnsNO {
    XCTAssertFalse([MailHandler isValidEmail:@"plaintext"]);
}

- (void)testIsValidEmail_SingleCharTLD_ReturnsNO {
    XCTAssertFalse([MailHandler isValidEmail:@"user@example.c"]);
}

- (void)testIsValidEmail_MultipleAtSigns_ReturnsNO {
    XCTAssertFalse([MailHandler isValidEmail:@"user@name@example.com"]);
}

#pragma mark - isAllValidEmail: Tests (Comma-Separated Emails)

- (void)testIsAllValidEmail_SingleEmail {
    XCTAssertTrue([MailHandler isAllValidEmail:@"user@example.com"]);
}

- (void)testIsAllValidEmail_TwoEmails {
    XCTAssertTrue([MailHandler isAllValidEmail:@"user@example.com,admin@test.io"]);
}

- (void)testIsAllValidEmail_MultipleEmails {
    XCTAssertTrue([MailHandler isAllValidEmail:@"a@b.com,c@d.org,e@f.net"]);
}

- (void)testIsAllValidEmail_WithSpacesAfterComma {
    XCTAssertTrue([MailHandler isAllValidEmail:@"user@example.com, admin@test.io"]);
}

- (void)testIsAllValidEmail_EmptyString {
    XCTAssertTrue([MailHandler isAllValidEmail:@""]);
}

- (void)testIsAllValidEmail_InvalidEmail_ReturnsNO {
    XCTAssertFalse([MailHandler isAllValidEmail:@"notanemail"]);
}

- (void)testIsAllValidEmail_MixedValidAndInvalid_ReturnsNO {
    XCTAssertFalse([MailHandler isAllValidEmail:@"user@example.com,invalid"]);
}

- (void)testIsAllValidEmail_DoubleComma_ReturnsNO {
    XCTAssertFalse([MailHandler isAllValidEmail:@"user@example.com,,admin@test.io"]);
}

#pragma mark - parseMessage:forIPAUploadInfo: Tests

- (void)testParseMessage_ReplacesBuildName {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    info.name = @"MyApp";
    info.version = @"1.0";
    info.build = @"42";
    info.appShortShareableURL = [NSURL URLWithString:@"https://example.com/app"];
    
    NSString *result = [MailHandler parseMessage:@"New build: {BUILD_NAME}" forIPAUploadInfo:info];
    XCTAssertTrue([result containsString:@"MyApp"]);
    XCTAssertFalse([result containsString:@"{BUILD_NAME}"]);
}

- (void)testParseMessage_ReplacesBuildNumber {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    info.name = @"TestApp";
    info.version = @"2.0";
    info.build = @"99";
    info.appShortShareableURL = [NSURL URLWithString:@"https://example.com/app"];
    
    NSString *result = [MailHandler parseMessage:@"Build #{BUILD_NUMBER}" forIPAUploadInfo:info];
    XCTAssertTrue([result containsString:@"99"]);
    XCTAssertFalse([result containsString:@"{BUILD_NUMBER}"]);
}

- (void)testParseMessage_ReplacesBuildVersion {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    info.name = @"TestApp";
    info.version = @"3.5.1";
    info.build = @"1";
    info.appShortShareableURL = [NSURL URLWithString:@"https://example.com/app"];
    
    NSString *result = [MailHandler parseMessage:@"Version: {BUILD_VERSION}" forIPAUploadInfo:info];
    XCTAssertTrue([result containsString:@"3.5.1"]);
    XCTAssertFalse([result containsString:@"{BUILD_VERSION}"]);
}

- (void)testParseMessage_ReplacesShareURL {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    info.name = @"TestApp";
    info.version = @"1.0";
    info.build = @"1";
    info.appShortShareableURL = [NSURL URLWithString:@"https://getappbox.com/share/abc123"];
    
    NSString *result = [MailHandler parseMessage:@"Download: {SHARE_URL}" forIPAUploadInfo:info];
    XCTAssertTrue([result containsString:@"https://getappbox.com/share/abc123"]);
    XCTAssertFalse([result containsString:@"{SHARE_URL}"]);
}

- (void)testParseMessage_AllPlaceholders {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    info.name = @"AppBox";
    info.version = @"4.2.0";
    info.build = @"200";
    info.appShortShareableURL = [NSURL URLWithString:@"https://example.com/link"];
    
    NSString *template = @"{BUILD_NAME} v{BUILD_VERSION} ({BUILD_NUMBER}) - {SHARE_URL}";
    NSString *result = [MailHandler parseMessage:template forIPAUploadInfo:info];
    XCTAssertTrue([result containsString:@"AppBox"]);
    XCTAssertTrue([result containsString:@"4.2.0"]);
    XCTAssertTrue([result containsString:@"200"]);
    XCTAssertTrue([result containsString:@"https://example.com/link"]);
}

- (void)testParseMessage_WithoutShareURL_AppendsURL {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    info.name = @"TestApp";
    info.version = @"1.0";
    info.build = @"1";
    info.appShortShareableURL = [NSURL URLWithString:@"https://example.com/download"];
    
    NSString *result = [MailHandler parseMessage:@"Build is ready!" forIPAUploadInfo:info];
    XCTAssertTrue([result containsString:@"Build is ready!"]);
    XCTAssertTrue([result containsString:@"https://example.com/download"]);
}

- (void)testParseMessage_WithShareURL_DoesNotAppendDuplicate {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    info.name = @"TestApp";
    info.version = @"1.0";
    info.build = @"1";
    info.appShortShareableURL = [NSURL URLWithString:@"https://example.com/dl"];
    
    NSString *result = [MailHandler parseMessage:@"Link: {SHARE_URL}" forIPAUploadInfo:info];
    // Should only appear once since {SHARE_URL} was explicitly used
    NSUInteger count = [[result componentsSeparatedByString:@"https://example.com/dl"] count] - 1;
    XCTAssertEqual(count, 1);
}

- (void)testParseMessage_NoPlaceholders_ReturnsOriginalWithURL {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    info.name = @"TestApp";
    info.version = @"1.0";
    info.build = @"1";
    info.appShortShareableURL = [NSURL URLWithString:@"https://example.com"];
    
    NSString *result = [MailHandler parseMessage:@"Hello World" forIPAUploadInfo:info];
    XCTAssertTrue([result hasPrefix:@"Hello World"]);
}

@end
