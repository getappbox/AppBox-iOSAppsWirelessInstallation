//
//  MobileProvisionTests.m
//  AppBoxTests
//
//  Created by AppBox on 29/05/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MobileProvision.h"

@interface MobileProvisionTests : XCTestCase
@property (nonatomic, strong) NSString *tempDir;
@end

@implementation MobileProvisionTests

- (void)setUp {
    [super setUp];
    self.tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    [[NSFileManager defaultManager] createDirectoryAtPath:self.tempDir withIntermediateDirectories:YES attributes:nil error:nil];
}

- (void)tearDown {
    [[NSFileManager defaultManager] removeItemAtPath:self.tempDir error:nil];
    [super tearDown];
}

- (NSString *)createProvisionFileWithPlist:(NSDictionary *)plist {
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListXMLFormat_v1_0 options:0 error:nil];
    NSString *plistString = [[NSString alloc] initWithData:plistData encoding:NSUTF8StringEncoding];
    // Wrap plist in binary content to simulate a real .mobileprovision file
    NSString *content = [NSString stringWithFormat:@"BINARY_HEADER_DATA%@BINARY_FOOTER_DATA", plistString];
    NSString *filePath = [self.tempDir stringByAppendingPathComponent:@"test.mobileprovision"];
    [content writeToFile:filePath atomically:YES encoding:NSISOLatin1StringEncoding error:nil];
    return filePath;
}

#pragma mark - Build Type Detection Tests

- (void)testBuildType_Enterprise_WhenProvisionsAllDevices {
    NSDictionary *plist = @{
        @"ProvisionsAllDevices": @YES,
        @"TeamIdentifier": @[@"ABC123"],
        @"TeamName": @"Enterprise Corp",
        @"UUID": @"test-uuid-enterprise"
    };
    NSString *path = [self createProvisionFileWithPlist:plist];
    MobileProvision *provision = [[MobileProvision alloc] initWithPath:path];
    XCTAssertTrue(provision.isValid);
    XCTAssertEqualObjects(provision.buildType, BuildTypeEnterprise);
}

- (void)testBuildType_Development_WhenHasDevicesAndGetTaskAllow {
    NSDictionary *plist = @{
        @"ProvisionedDevices": @[@"UDID-1", @"UDID-2"],
        @"Entitlements": @{@"get-task-allow": @YES},
        @"TeamIdentifier": @[@"DEV123"],
        @"TeamName": @"Dev Team",
        @"UUID": @"test-uuid-dev"
    };
    NSString *path = [self createProvisionFileWithPlist:plist];
    MobileProvision *provision = [[MobileProvision alloc] initWithPath:path];
    XCTAssertTrue(provision.isValid);
    XCTAssertEqualObjects(provision.buildType, BuildTypeDevelopment);
}

- (void)testBuildType_AdHoc_WhenHasDevicesButNoGetTaskAllow {
    NSDictionary *plist = @{
        @"ProvisionedDevices": @[@"UDID-1", @"UDID-2"],
        @"Entitlements": @{@"get-task-allow": @NO},
        @"TeamIdentifier": @[@"ADHOC123"],
        @"TeamName": @"AdHoc Team",
        @"UUID": @"test-uuid-adhoc"
    };
    NSString *path = [self createProvisionFileWithPlist:plist];
    MobileProvision *provision = [[MobileProvision alloc] initWithPath:path];
    XCTAssertTrue(provision.isValid);
    XCTAssertEqualObjects(provision.buildType, BuildTypeAdHoc);
}

- (void)testBuildType_AppStore_WhenNoDevices {
    NSDictionary *plist = @{
        @"TeamIdentifier": @[@"STORE123"],
        @"TeamName": @"AppStore Team",
        @"UUID": @"test-uuid-appstore"
    };
    NSString *path = [self createProvisionFileWithPlist:plist];
    MobileProvision *provision = [[MobileProvision alloc] initWithPath:path];
    XCTAssertTrue(provision.isValid);
    XCTAssertEqualObjects(provision.buildType, BuildTypeAppStore);
}

#pragma mark - Property Extraction Tests

- (void)testExtractsTeamId {
    NSDictionary *plist = @{
        @"TeamIdentifier": @[@"TEAM999"],
        @"TeamName": @"My Team",
        @"UUID": @"uuid-123"
    };
    NSString *path = [self createProvisionFileWithPlist:plist];
    MobileProvision *provision = [[MobileProvision alloc] initWithPath:path];
    XCTAssertEqualObjects(provision.teamId, @"TEAM999");
}

- (void)testExtractsTeamName {
    NSDictionary *plist = @{
        @"TeamIdentifier": @[@"T1"],
        @"TeamName": @"Awesome Team",
        @"UUID": @"uuid-456"
    };
    NSString *path = [self createProvisionFileWithPlist:plist];
    MobileProvision *provision = [[MobileProvision alloc] initWithPath:path];
    XCTAssertEqualObjects(provision.teamName, @"Awesome Team");
}

- (void)testExtractsUUID {
    NSDictionary *plist = @{
        @"TeamIdentifier": @[@"T1"],
        @"TeamName": @"Team",
        @"UUID": @"unique-profile-uuid"
    };
    NSString *path = [self createProvisionFileWithPlist:plist];
    MobileProvision *provision = [[MobileProvision alloc] initWithPath:path];
    XCTAssertEqualObjects(provision.uuid, @"unique-profile-uuid");
}

- (void)testExtractsProvisionedDevices {
    NSArray *devices = @[@"AAA-BBB-CCC", @"DDD-EEE-FFF"];
    NSDictionary *plist = @{
        @"ProvisionedDevices": devices,
        @"Entitlements": @{@"get-task-allow": @YES},
        @"TeamIdentifier": @[@"T1"],
        @"TeamName": @"Team",
        @"UUID": @"uuid"
    };
    NSString *path = [self createProvisionFileWithPlist:plist];
    MobileProvision *provision = [[MobileProvision alloc] initWithPath:path];
    XCTAssertEqualObjects(provision.provisionedDevices, devices);
}

- (void)testExtractsCreationDate {
    NSDate *createDate = [NSDate dateWithTimeIntervalSince1970:1700000000];
    NSDictionary *plist = @{
        @"TeamIdentifier": @[@"T1"],
        @"TeamName": @"Team",
        @"UUID": @"uuid",
        @"CreationDate": createDate
    };
    NSString *path = [self createProvisionFileWithPlist:plist];
    MobileProvision *provision = [[MobileProvision alloc] initWithPath:path];
    XCTAssertEqualObjects(provision.createDate, createDate);
}

- (void)testExtractsExpirationDate {
    NSDate *expDate = [NSDate dateWithTimeIntervalSince1970:1800000000];
    NSDictionary *plist = @{
        @"TeamIdentifier": @[@"T1"],
        @"TeamName": @"Team",
        @"UUID": @"uuid",
        @"ExpirationDate": expDate
    };
    NSString *path = [self createProvisionFileWithPlist:plist];
    MobileProvision *provision = [[MobileProvision alloc] initWithPath:path];
    XCTAssertEqualObjects(provision.expirationDate, expDate);
}

#pragma mark - Invalid Input Tests

- (void)testInvalidPath_IsNotValid {
    MobileProvision *provision = [[MobileProvision alloc] initWithPath:@"/nonexistent/path.mobileprovision"];
    XCTAssertFalse(provision.isValid);
}

- (void)testFileWithNoPlist_IsNotValid {
    NSString *filePath = [self.tempDir stringByAppendingPathComponent:@"garbage.mobileprovision"];
    [@"this is not a valid mobileprovision file" writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    MobileProvision *provision = [[MobileProvision alloc] initWithPath:filePath];
    XCTAssertFalse(provision.isValid);
}

- (void)testEmptyPlist_BuildType_DeveloperId {
    // An empty plist dict results in DeveloperID build type
    NSDictionary *plist = @{};
    NSString *path = [self createProvisionFileWithPlist:plist];
    MobileProvision *provision = [[MobileProvision alloc] initWithPath:path];
    XCTAssertTrue(provision.isValid);
    XCTAssertEqualObjects(provision.buildType, BuildTypeDeveloperId);
}

@end
