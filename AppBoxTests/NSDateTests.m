//
//  NSDateTests.m
//  AppBoxTests
//
//  Created by AppBox on 29/05/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSDate+Date.h"

@interface NSDateTests : XCTestCase
@end

@implementation NSDateTests

- (void)testString_ReturnsFormattedDate {
    // Create a known date: 2024-06-15 14:30:00 UTC
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = 2024;
    components.month = 6;
    components.day = 15;
    components.hour = 14;
    components.minute = 30;
    components.second = 0;
    components.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDate *date = [calendar dateFromComponents:components];
    
    NSString *result = [date string];
    XCTAssertNotNil(result);
    // The format is "YYYY-MM-dd, hh:mm a" - verify structure
    XCTAssertTrue([result containsString:@"2024"]);
    XCTAssertTrue([result containsString:@"-"]);
    XCTAssertTrue([result containsString:@","]);
}

- (void)testString_ContainsAMPM {
    NSDate *now = [NSDate date];
    NSString *result = [now string];
    XCTAssertNotNil(result);
    // Should contain AM or PM
    BOOL hasAMPM = [result containsString:@"AM"] || [result containsString:@"PM"];
    XCTAssertTrue(hasAMPM, @"Date string should contain AM or PM marker");
}

- (void)testString_IsNotEmpty {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
    NSString *result = [date string];
    XCTAssertNotNil(result);
    XCTAssertGreaterThan(result.length, 0);
}

@end
