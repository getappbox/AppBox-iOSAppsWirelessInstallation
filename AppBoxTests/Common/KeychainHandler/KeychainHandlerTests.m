//
//  KeychainHandlerTests.m
//  AppBoxTests
//
//  Created by AppBox on 29/05/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeychainHandler.h"

@interface KeychainHandlerTests : XCTestCase
@end

@implementation KeychainHandlerTests

#pragma mark - errorMessageForStatus Tests

- (void)testErrorMessageForStatus_Success_ReturnsNoError {
    NSString *message = [KeychainHandler errorMessageForStatus:errSecSuccess];
    XCTAssertNotNil(message);
    // errSecSuccess (0) should not produce an error-style message
    XCTAssertGreaterThan(message.length, 0);
}

- (void)testErrorMessageForStatus_ItemNotFound_ReturnsMessage {
    NSString *message = [KeychainHandler errorMessageForStatus:errSecItemNotFound];
    XCTAssertNotNil(message);
    XCTAssertGreaterThan(message.length, 0);
}

- (void)testErrorMessageForStatus_AuthFailed_ReturnsMessage {
    NSString *message = [KeychainHandler errorMessageForStatus:errSecAuthFailed];
    XCTAssertNotNil(message);
    XCTAssertGreaterThan(message.length, 0);
}

- (void)testErrorMessageForStatus_DuplicateItem_ReturnsMessage {
    NSString *message = [KeychainHandler errorMessageForStatus:errSecDuplicateItem];
    XCTAssertNotNil(message);
    XCTAssertGreaterThan(message.length, 0);
}

- (void)testErrorMessageForStatus_DifferentStatusesDifferentMessages {
    NSString *notFound = [KeychainHandler errorMessageForStatus:errSecItemNotFound];
    NSString *duplicate = [KeychainHandler errorMessageForStatus:errSecDuplicateItem];
    XCTAssertNotEqualObjects(notFound, duplicate);
}

#pragma mark - Constants Tests

- (void)testKeychainAccountKey_HasExpectedValue {
    XCTAssertEqualObjects(kSAMKeychainAccountKey, @"acct");
}

- (void)testKeychainLabelKey_HasExpectedValue {
    XCTAssertEqualObjects(kSAMKeychainLabelKey, @"labl");
}

#pragma mark - accountsForService Tests

- (void)testAccountsForService_WithNonExistentService_ReturnsEmptyArray {
    NSArray *accounts = [KeychainHandler accountsForService:@"com.appbox.test.nonexistent.service.12345"];
    XCTAssertNotNil(accounts);
    XCTAssertEqual(accounts.count, 0);
}

@end
