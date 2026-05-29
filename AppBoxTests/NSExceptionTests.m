//
//  NSExceptionTests.m
//  AppBoxTests
//
//  Created by AppBox on 29/05/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSException+Description.h"

@interface NSExceptionTests : XCTestCase
@end

@implementation NSExceptionTests

- (void)testAbDescription_ContainsName {
    NSException *exception = [NSException exceptionWithName:@"TestException"
                                                    reason:@"Something failed"
                                                  userInfo:nil];
    NSString *description = [exception abDescription];
    XCTAssertTrue([description containsString:@"TestException"]);
}

- (void)testAbDescription_ContainsReason {
    NSException *exception = [NSException exceptionWithName:@"TestException"
                                                    reason:@"Something failed"
                                                  userInfo:nil];
    NSString *description = [exception abDescription];
    XCTAssertTrue([description containsString:@"Something failed"]);
}

- (void)testAbDescription_ContainsUserInfo {
    NSDictionary *userInfo = @{@"key": @"value"};
    NSException *exception = [NSException exceptionWithName:@"TestException"
                                                    reason:@"Reason"
                                                  userInfo:userInfo];
    NSString *description = [exception abDescription];
    XCTAssertTrue([description containsString:@"key"]);
    XCTAssertTrue([description containsString:@"value"]);
}

- (void)testAbDescription_WithNilReason_DoesNotCrash {
    NSException *exception = [NSException exceptionWithName:@"TestException"
                                                    reason:nil
                                                  userInfo:nil];
    NSString *description = [exception abDescription];
    XCTAssertNotNil(description);
    XCTAssertTrue([description containsString:@"TestException"]);
}

- (void)testAbDescription_ContainsNameLabel {
    NSException *exception = [NSException exceptionWithName:@"Crash"
                                                    reason:@"oops"
                                                  userInfo:nil];
    NSString *description = [exception abDescription];
    XCTAssertTrue([description containsString:@"Name:"]);
    XCTAssertTrue([description containsString:@"Reason:"]);
    XCTAssertTrue([description containsString:@"UserInfo:"]);
}

@end
