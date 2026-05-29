//
//  NSURLTests.m
//  AppBoxTests
//
//  Created by AppBox on 29/05/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSURL+URL.h"

@interface NSURLTests : XCTestCase
@end

@implementation NSURLTests

#pragma mark - isIPA Tests

- (void)testIsIPA_WithIPAFile_ReturnsYES {
    NSURL *url = [NSURL fileURLWithPath:@"/path/to/MyApp.ipa"];
    XCTAssertTrue([url isIPA]);
}

- (void)testIsIPA_WithUppercaseIPA_ReturnsYES {
    NSURL *url = [NSURL fileURLWithPath:@"/path/to/MyApp.IPA"];
    XCTAssertTrue([url isIPA]);
}

- (void)testIsIPA_WithMixedCaseIPA_ReturnsYES {
    NSURL *url = [NSURL fileURLWithPath:@"/path/to/MyApp.Ipa"];
    XCTAssertTrue([url isIPA]);
}

- (void)testIsIPA_WithZipFile_ReturnsNO {
    NSURL *url = [NSURL fileURLWithPath:@"/path/to/MyApp.zip"];
    XCTAssertFalse([url isIPA]);
}

- (void)testIsIPA_WithNoExtension_ReturnsNO {
    NSURL *url = [NSURL fileURLWithPath:@"/path/to/MyApp"];
    XCTAssertFalse([url isIPA]);
}

#pragma mark - acceptableURL Tests

- (void)testAcceptableURL_WithIPAFile_ReturnsYES {
    NSURL *url = [NSURL fileURLWithPath:@"/path/to/app.ipa"];
    XCTAssertTrue([url acceptableURL]);
}

- (void)testAcceptableURL_WithNonIPAFile_ReturnsNO {
    NSURL *url = [NSURL fileURLWithPath:@"/path/to/app.dmg"];
    XCTAssertFalse([url acceptableURL]);
}

#pragma mark - stringValue Tests

- (void)testStringValue_WithFileURL_ReturnsString {
    NSURL *url = [NSURL fileURLWithPath:@"/path/to/file.ipa"];
    NSString *result = [url stringValue];
    XCTAssertNotNil(result);
    XCTAssertTrue([result containsString:@"/path/to/file.ipa"]);
}

- (void)testStringValue_WithHTTPURL_ReturnsString {
    NSURL *url = [NSURL URLWithString:@"https://example.com/app.ipa"];
    NSString *result = [url stringValue];
    XCTAssertEqualObjects(result, @"https://example.com/app.ipa");
}

@end
