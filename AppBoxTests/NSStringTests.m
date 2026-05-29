//
//  NSStringTests.m
//  AppBoxTests
//
//  Created by AppBox on 29/05/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSString+String.h"

@interface NSStringTests : XCTestCase
@end

@implementation NSStringTests

#pragma mark - isEmpty Tests

- (void)testIsEmpty_WithEmptyString_ReturnsYES {
    XCTAssertTrue([@"" isEmpty]);
}

- (void)testIsEmpty_WithWhitespaceOnly_ReturnsYES {
    XCTAssertTrue([@"   " isEmpty]);
}

- (void)testIsEmpty_WithTabsAndSpaces_ReturnsYES {
    XCTAssertTrue([@" \t " isEmpty]);
}

- (void)testIsEmpty_WithNonEmptyString_ReturnsNO {
    XCTAssertFalse([@"hello" isEmpty]);
}

- (void)testIsEmpty_WithWhitespaceSurroundingText_ReturnsNO {
    XCTAssertFalse([@"  hello  " isEmpty]);
}

- (void)testIsEmpty_WithSingleCharacter_ReturnsNO {
    XCTAssertFalse([@"a" isEmpty]);
}

#pragma mark - ipaURL Tests

- (void)testIpaURL_WithValidIPAPath_ReturnsURL {
    NSString *path = @"/path/to/MyApp.ipa";
    NSURL *result = [path ipaURL];
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.pathExtension, @"ipa");
}

- (void)testIpaURL_WithUppercaseIPA_ReturnsURL {
    NSString *path = @"/path/to/MyApp.IPA";
    NSURL *result = [path ipaURL];
    XCTAssertNotNil(result);
}

- (void)testIpaURL_WithMixedCaseIPA_ReturnsURL {
    NSString *path = @"/path/to/MyApp.Ipa";
    NSURL *result = [path ipaURL];
    XCTAssertNotNil(result);
}

- (void)testIpaURL_WithNonIPAExtension_ReturnsNil {
    NSString *path = @"/path/to/MyApp.zip";
    NSURL *result = [path ipaURL];
    XCTAssertNil(result);
}

- (void)testIpaURL_WithNoExtension_ReturnsNil {
    NSString *path = @"/path/to/MyApp";
    NSURL *result = [path ipaURL];
    XCTAssertNil(result);
}

- (void)testIpaURL_WithAppExtension_ReturnsNil {
    NSString *path = @"/path/to/MyApp.app";
    NSURL *result = [path ipaURL];
    XCTAssertNil(result);
}

@end
