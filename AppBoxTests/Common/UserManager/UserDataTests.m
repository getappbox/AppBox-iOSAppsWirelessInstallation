//
//  UserDataTests.m
//  AppBoxTests
//
//  Created by AppBox on 29/05/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UserData.h"

@interface UserDataTests : XCTestCase
@end

@implementation UserDataTests

#pragma mark - Email Preferences

- (void)testSetAndGetUserEmail {
    NSString *testEmail = @"test-unit@appbox.io";
    [UserData setUserEmail:testEmail];
    XCTAssertEqualObjects([UserData userEmail], testEmail);
    // Cleanup
    [UserData setUserEmail:@""];
}

- (void)testUserEmail_WhenNil_ReturnsEmptyString {
    [UserData setUserEmail:nil];
    NSString *email = [UserData userEmail];
    XCTAssertNotNil(email);
    XCTAssertEqualObjects(email, @"");
}

#pragma mark - Message Preferences

- (void)testSetAndGetUserMessage {
    NSString *testMessage = @"Test build ready for QA";
    [UserData setUserMessage:testMessage];
    XCTAssertEqualObjects([UserData userMessage], testMessage);
    [UserData setUserMessage:@""];
}

- (void)testUserMessage_WhenNil_ReturnsEmptyString {
    [UserData setUserMessage:nil];
    NSString *message = [UserData userMessage];
    XCTAssertNotNil(message);
    XCTAssertEqualObjects(message, @"");
}

#pragma mark - Slack Webhook Preferences

- (void)testSetAndGetSlackChannel {
    NSString *webhook = @"https://hooks.slack.com/services/T00/B00/test";
    [UserData setUserSlackChannel:webhook];
    XCTAssertEqualObjects([UserData userSlackChannel], webhook);
    [UserData setUserSlackChannel:@""];
}

- (void)testSlackChannel_WhenNil_ReturnsEmptyString {
    [UserData setUserSlackChannel:nil];
    XCTAssertEqualObjects([UserData userSlackChannel], @"");
}

- (void)testSetAndGetSlackMessage {
    NSString *msg = @"New build uploaded: {name} v{version}";
    [UserData setUserSlackMessage:msg];
    XCTAssertEqualObjects([UserData userSlackMessage], msg);
    [UserData setUserSlackMessage:@""];
}

#pragma mark - Hangout Chat Webhook

- (void)testSetAndGetHangoutChatWebHook {
    NSString *webhook = @"https://chat.googleapis.com/v1/spaces/test/messages";
    [UserData setUserHangoutChatWebHook:webhook];
    XCTAssertEqualObjects([UserData userHangoutChatWebHook], webhook);
    [UserData setUserHangoutChatWebHook:@""];
}

#pragma mark - Microsoft Teams Webhook

- (void)testSetAndGetMicrosoftTeamWebHook {
    NSString *webhook = @"https://outlook.office.com/webhook/test";
    [UserData setUserMicrosoftTeamWebHook:webhook];
    XCTAssertEqualObjects([UserData userMicrosoftTeamWebHook], webhook);
    [UserData setUserMicrosoftTeamWebHook:@""];
}

#pragma mark - Installation Page Settings

- (void)testSetAndGetDownloadIPAEnable {
    [UserData setDownloadIPAEnable:YES];
    XCTAssertTrue([UserData downloadIPAEnable]);
    [UserData setDownloadIPAEnable:NO];
    XCTAssertFalse([UserData downloadIPAEnable]);
}

- (void)testSetAndGetMoreDetailsEnable {
    [UserData setMoreDetailsEnable:YES];
    XCTAssertTrue([UserData moreDetailsEnable]);
    [UserData setMoreDetailsEnable:NO];
    XCTAssertFalse([UserData moreDetailsEnable]);
}

- (void)testSetAndGetShowPreviousVersions {
    [UserData setShowPreviousVersions:YES];
    XCTAssertTrue([UserData showPreviousVersions]);
    [UserData setShowPreviousVersions:NO];
    XCTAssertFalse([UserData showPreviousVersions]);
}

#pragma mark - Upload Chunk Size

- (void)testUploadChunkSize_Default_Returns100 {
    [UserData setUploadChunkSize:0];
    XCTAssertEqual([UserData uploadChunkSize], 100);
}

- (void)testSetAndGetUploadChunkSize {
    [UserData setUploadChunkSize:50];
    XCTAssertEqual([UserData uploadChunkSize], 50);
    // Reset
    [UserData setUploadChunkSize:100];
}

- (void)testUploadChunkSize_NegativeValue_ReturnsDefault {
    [UserData setUploadChunkSize:-1];
    XCTAssertEqual([UserData uploadChunkSize], 100);
}

#pragma mark - Debug Log

- (void)testSetAndGetDebugLog {
    [UserData setEnableDebugLog:YES];
    XCTAssertTrue([UserData debugLog]);
    [UserData setEnableDebugLog:NO];
    XCTAssertFalse([UserData debugLog]);
}

#pragma mark - Update Alert

- (void)testSetAndGetUpdateAlertEnable {
    [UserData setUpdateAlertEnable:YES];
    XCTAssertTrue([UserData updateAlertEnable]);
    [UserData setUpdateAlertEnable:NO];
    XCTAssertFalse([UserData updateAlertEnable]);
}

#pragma mark - CLI Version

- (void)testSetAndGetCLIVersion {
    NSString *version = @"2.5.1";
    [UserData setCLIVersion:version];
    XCTAssertEqualObjects([UserData cliVersion], version);
    [UserData setCLIVersion:@""];
}

- (void)testCLIVersion_WhenNil_ReturnsEmptyString {
    [UserData setCLIVersion:nil];
    XCTAssertEqualObjects([UserData cliVersion], @"");
}

#pragma mark - Dropbox Space

- (void)testSetAndGetDropboxUsedSpace {
    [UserData setDropboxUsedSpace:@1024];
    XCTAssertEqualObjects([UserData dropboxUsedSpace], @1024);
    [UserData setDropboxUsedSpace:@0];
}

- (void)testSetAndGetDropboxAvailableSpace {
    [UserData setDropboxAvailableSpace:@2048];
    XCTAssertEqualObjects([UserData dropboxAvailableSpace], @2048);
    [UserData setDropboxAvailableSpace:@0];
}

#pragma mark - Logged In User

- (void)testSetAndGetLoggedInUserEmail {
    NSString *email = @"user@appbox-test.com";
    [UserData setLoggedInUserEmail:email];
    XCTAssertEqualObjects([UserData loggedInUserEmail], email);
    [UserData setLoggedInUserEmail:@""];
}

- (void)testLoggedInUserEmail_WhenNil_ReturnsEmptyString {
    [UserData setLoggedInUserEmail:nil];
    XCTAssertEqualObjects([UserData loggedInUserEmail], @"");
}

- (void)testSetAndGetLoggedInUserDisplayName {
    NSString *name = @"Test User";
    [UserData setLoggedInUserDisplayName:name];
    XCTAssertEqualObjects([UserData loggedInUserDisplayName], name);
    [UserData setLoggedInUserDisplayName:@""];
}

@end
