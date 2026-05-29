//
//  CommonTests.m
//  AppBoxTests
//
//  Created by AppBox on 29/05/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Common.h"

@interface CommonTests : XCTestCase
@end

@implementation CommonTests

#pragma mark - generateUUID Tests

- (void)testGenerateUUID_ReturnsNonNilString {
    NSString *uuid = [Common generateUUID];
    XCTAssertNotNil(uuid);
}

- (void)testGenerateUUID_ReturnsNonEmptyString {
    NSString *uuid = [Common generateUUID];
    XCTAssertGreaterThan(uuid.length, 0);
}

- (void)testGenerateUUID_DoesNotContainSlashes {
    NSString *uuid = [Common generateUUID];
    XCTAssertFalse([uuid containsString:@"/"]);
}

- (void)testGenerateUUID_GeneratesUniqueValues {
    NSString *uuid1 = [Common generateUUID];
    NSString *uuid2 = [Common generateUUID];
    XCTAssertNotEqualObjects(uuid1, uuid2);
}

#pragma mark - errorWithDesc:andCode: Tests

- (void)testErrorWithDesc_ReturnsError {
    NSError *error = [Common errorWithDesc:@"Test error" andCode:42];
    XCTAssertNotNil(error);
}

- (void)testErrorWithDesc_HasCorrectCode {
    NSError *error = [Common errorWithDesc:@"Test error" andCode:42];
    XCTAssertEqual(error.code, 42);
}

- (void)testErrorWithDesc_HasCorrectDescription {
    NSError *error = [Common errorWithDesc:@"Something went wrong" andCode:100];
    XCTAssertEqualObjects(error.localizedDescription, @"Something went wrong");
}

- (void)testErrorWithDesc_HasCocoaDomain {
    NSError *error = [Common errorWithDesc:@"Error" andCode:1];
    XCTAssertEqualObjects(error.domain, NSCocoaErrorDomain);
}

- (void)testErrorWithDesc_WithZeroCode {
    NSError *error = [Common errorWithDesc:@"Zero code error" andCode:0];
    XCTAssertEqual(error.code, 0);
    XCTAssertEqualObjects(error.localizedDescription, @"Zero code error");
}

#pragma mark - isValidWebhookURL: Tests

- (void)testIsValidWebhookURL_WithHTTPS_ReturnsYES {
    XCTAssertTrue([Common isValidWebhookURL:@"https://hooks.slack.com/services/T00/B00/xxxx"]);
}

- (void)testIsValidWebhookURL_WithHTTP_ReturnsYES {
    XCTAssertTrue([Common isValidWebhookURL:@"http://example.com/webhook"]);
}

- (void)testIsValidWebhookURL_WithEmptyString_ReturnsNO {
    XCTAssertFalse([Common isValidWebhookURL:@""]);
}

- (void)testIsValidWebhookURL_WithNilString_ReturnsNO {
    XCTAssertFalse([Common isValidWebhookURL:nil]);
}

- (void)testIsValidWebhookURL_WithNoScheme_ReturnsNO {
    XCTAssertFalse([Common isValidWebhookURL:@"hooks.slack.com/services"]);
}

- (void)testIsValidWebhookURL_WithFTPScheme_ReturnsNO {
    XCTAssertFalse([Common isValidWebhookURL:@"ftp://example.com/file"]);
}

- (void)testIsValidWebhookURL_WithJustScheme_ReturnsNO {
    XCTAssertFalse([Common isValidWebhookURL:@"https://"]);
}

#pragma mark - getFileDirectoryForFilePath: Tests

- (void)testGetFileDirectory_ExtractsParentDirectory {
    NSURL *filePath = [NSURL URLWithString:@"/Users/test/Documents/file.ipa"];
    NSURL *result = [Common getFileDirectoryForFilePath:filePath];
    XCTAssertNotNil(result);
    NSString *resultString = result.absoluteString;
    XCTAssertTrue([resultString containsString:@"Documents"]);
    XCTAssertFalse([resultString containsString:@"file.ipa"]);
}

- (void)testGetFileDirectory_WithNestedPath {
    NSURL *filePath = [NSURL URLWithString:@"/a/b/c/d.txt"];
    NSURL *result = [Common getFileDirectoryForFilePath:filePath];
    XCTAssertNotNil(result);
    NSString *resultString = result.absoluteString;
    XCTAssertTrue([resultString containsString:@"/a/b/c"]);
}

@end
