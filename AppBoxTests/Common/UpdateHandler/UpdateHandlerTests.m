//
//  UpdateHandlerTests.m
//  AppBoxTests
//
//  Created by AppBox on 29/05/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UpdateHandler.h"

@interface UpdateHandler (Testing)
+ (NSString *)extractVersionString:(NSString *)input;
@end

@interface UpdateHandlerTests : XCTestCase
@end

@implementation UpdateHandlerTests

#pragma mark - extractVersionString: Tests

- (void)testExtractVersion_SimpleVersion {
    XCTAssertEqualObjects([UpdateHandler extractVersionString:@"1.2.3"], @"1.2.3");
}

- (void)testExtractVersion_VersionWithVPrefix {
    XCTAssertEqualObjects([UpdateHandler extractVersionString:@"v2.5.1"], @"2.5.1");
}

- (void)testExtractVersion_VersionWithTagPrefix {
    XCTAssertEqualObjects([UpdateHandler extractVersionString:@"release-3.0.0"], @"3.0.0");
}

- (void)testExtractVersion_VersionWithText {
    XCTAssertEqualObjects([UpdateHandler extractVersionString:@"AppBox v4.1.2"], @"4.1.2");
}

- (void)testExtractVersion_SingleNumber {
    XCTAssertEqualObjects([UpdateHandler extractVersionString:@"5"], @"5");
}

- (void)testExtractVersion_TwoPartVersion {
    XCTAssertEqualObjects([UpdateHandler extractVersionString:@"1.0"], @"1.0");
}

- (void)testExtractVersion_FourPartVersion {
    XCTAssertEqualObjects([UpdateHandler extractVersionString:@"1.2.3.4"], @"1.2.3.4");
}

- (void)testExtractVersion_WithTrailingDot_RemovesDot {
    XCTAssertEqualObjects([UpdateHandler extractVersionString:@"1.2."], @"1.2");
}

- (void)testExtractVersion_WithLeadingText {
    XCTAssertEqualObjects([UpdateHandler extractVersionString:@"version1.0.0"], @"1.0.0");
}

- (void)testExtractVersion_NilInput_ReturnsZero {
    XCTAssertEqualObjects([UpdateHandler extractVersionString:nil], @"0");
}

- (void)testExtractVersion_EmptyString_ReturnsZero {
    XCTAssertEqualObjects([UpdateHandler extractVersionString:@""], @"0");
}

- (void)testExtractVersion_NoDigits_ReturnsZero {
    XCTAssertEqualObjects([UpdateHandler extractVersionString:@"abc"], @"0");
}

- (void)testExtractVersion_OnlyDots_ReturnsZero {
    XCTAssertEqualObjects([UpdateHandler extractVersionString:@"..."], @"0");
}

- (void)testExtractVersion_MixedSpecialChars {
    XCTAssertEqualObjects([UpdateHandler extractVersionString:@"v2.0-beta.1"], @"2.0.1");
}

- (void)testExtractVersion_LeadingDotsIgnored {
    // Dots before first digit are ignored per the algorithm
    NSString *result = [UpdateHandler extractVersionString:@".1.2"];
    XCTAssertEqualObjects(result, @"1.2");
}

- (void)testExtractVersion_LargeVersionNumbers {
    XCTAssertEqualObjects([UpdateHandler extractVersionString:@"123.456.789"], @"123.456.789");
}

#pragma mark - Version Comparison Logic Tests

- (void)testVersionComparison_NewerVersion {
    NSString *latest = [UpdateHandler extractVersionString:@"v2.0.0"];
    NSString *current = [UpdateHandler extractVersionString:@"1.9.9"];
    NSComparisonResult result = [latest compare:current options:NSNumericSearch];
    XCTAssertEqual(result, NSOrderedDescending);
}

- (void)testVersionComparison_SameVersion {
    NSString *latest = [UpdateHandler extractVersionString:@"v1.5.0"];
    NSString *current = [UpdateHandler extractVersionString:@"1.5.0"];
    NSComparisonResult result = [latest compare:current options:NSNumericSearch];
    XCTAssertEqual(result, NSOrderedSame);
}

- (void)testVersionComparison_OlderVersion {
    NSString *latest = [UpdateHandler extractVersionString:@"v1.0.0"];
    NSString *current = [UpdateHandler extractVersionString:@"2.0.0"];
    NSComparisonResult result = [latest compare:current options:NSNumericSearch];
    XCTAssertEqual(result, NSOrderedAscending);
}

- (void)testVersionComparison_PatchUpdate {
    NSString *latest = [UpdateHandler extractVersionString:@"v1.0.1"];
    NSString *current = [UpdateHandler extractVersionString:@"1.0.0"];
    NSComparisonResult result = [latest compare:current options:NSNumericSearch];
    XCTAssertEqual(result, NSOrderedDescending);
}

- (void)testVersionComparison_MajorVsMinor {
    NSString *latest = [UpdateHandler extractVersionString:@"v2.0.0"];
    NSString *current = [UpdateHandler extractVersionString:@"1.99.99"];
    NSComparisonResult result = [latest compare:current options:NSNumericSearch];
    XCTAssertEqual(result, NSOrderedDescending);
}

@end
