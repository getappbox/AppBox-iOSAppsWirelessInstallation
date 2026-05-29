//
//  IPAUploadInfoTests.m
//  AppBoxTests
//
//  Created by AppBox on 29/05/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IPAUploadInfo.h"
#import "Constants.h"

@interface IPAUploadInfoTests : XCTestCase
@end

@implementation IPAUploadInfoTests

#pragma mark - initEmpty Tests

- (void)testInitEmpty_SetsKeepSameLinkToZero {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    XCTAssertEqualObjects(info.keepSameLink, @0);
}

- (void)testInitEmpty_SetsEmptyEmails {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    XCTAssertEqualObjects(info.emails, @"");
}

- (void)testInitEmpty_SetsEmptyBuildType {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    XCTAssertEqualObjects(info.buildType, @"");
}

- (void)testInitEmpty_SetsEmptyPersonalMessage {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    XCTAssertEqualObjects(info.personalMessage, @"");
}

#pragma mark - setName Tests

- (void)testSetName_RemovesSpaces {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    info.name = @"My App Name";
    XCTAssertEqualObjects(info.name, @"MyAppName");
}

- (void)testSetName_WithNoSpaces_RemainsUnchanged {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    info.name = @"MyApp";
    XCTAssertEqualObjects(info.name, @"MyApp");
}

- (void)testSetName_WithMultipleSpaces_RemovesAll {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    info.name = @"  My  App  ";
    XCTAssertEqualObjects(info.name, @"MyApp");
}

#pragma mark - isValidInfoPlist Tests

- (void)testIsValidInfoPlist_WithAllFields_ReturnsYES {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    NSDictionary *plist = @{
        @"CFBundleName": @"TestApp",
        @"CFBundleVersion": @"1",
        @"CFBundleIdentifier": @"com.test.app",
        @"CFBundleShortVersionString": @"1.0"
    };
    info.ipaInfoPlist = plist;
    XCTAssertTrue([info isValidInfoPlist]);
}

- (void)testIsValidInfoPlist_WithNilPlist_ReturnsNO {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    XCTAssertFalse([info isValidInfoPlist]);
}

- (void)testIsValidInfoPlist_WithMissingName_ReturnsNO {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    NSDictionary *plist = @{
        @"CFBundleVersion": @"1",
        @"CFBundleIdentifier": @"com.test.app",
        @"CFBundleShortVersionString": @"1.0"
    };
    info.ipaInfoPlist = plist;
    XCTAssertFalse([info isValidInfoPlist]);
}

#pragma mark - setIpaInfoPlist Tests

- (void)testSetIpaInfoPlist_ExtractsBundleVersion {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    NSDictionary *plist = @{
        @"CFBundleName": @"TestApp",
        @"CFBundleVersion": @"42",
        @"CFBundleIdentifier": @"com.test.app",
        @"CFBundleShortVersionString": @"2.1"
    };
    info.ipaInfoPlist = plist;
    XCTAssertEqualObjects(info.build, @"42");
}

- (void)testSetIpaInfoPlist_ExtractsVersion {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    NSDictionary *plist = @{
        @"CFBundleName": @"TestApp",
        @"CFBundleVersion": @"1",
        @"CFBundleIdentifier": @"com.test.app",
        @"CFBundleShortVersionString": @"3.5.2"
    };
    info.ipaInfoPlist = plist;
    XCTAssertEqualObjects(info.version, @"3.5.2");
}

- (void)testSetIpaInfoPlist_ExtractsIdentifier {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    NSDictionary *plist = @{
        @"CFBundleName": @"TestApp",
        @"CFBundleVersion": @"1",
        @"CFBundleIdentifier": @"com.example.myapp",
        @"CFBundleShortVersionString": @"1.0"
    };
    info.ipaInfoPlist = plist;
    XCTAssertEqualObjects(info.identifer, @"com.example.myapp");
}

- (void)testSetIpaInfoPlist_ExtractsMinOS {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    NSDictionary *plist = @{
        @"CFBundleName": @"TestApp",
        @"CFBundleVersion": @"1",
        @"CFBundleIdentifier": @"com.test.app",
        @"CFBundleShortVersionString": @"1.0",
        @"MinimumOSVersion": @"15.0"
    };
    info.ipaInfoPlist = plist;
    XCTAssertEqualObjects(info.miniOSVersion, @"15.0");
}

- (void)testSetIpaInfoPlist_SupportedDevice_iPhone {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    NSDictionary *plist = @{
        @"CFBundleName": @"TestApp",
        @"CFBundleVersion": @"1",
        @"CFBundleIdentifier": @"com.test.app",
        @"CFBundleShortVersionString": @"1.0",
        @"UIDeviceFamily": @[@1]
    };
    info.ipaInfoPlist = plist;
    XCTAssertEqualObjects(info.supportedDevice, @"iPhone");
}

- (void)testSetIpaInfoPlist_SupportedDevice_iPad {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    NSDictionary *plist = @{
        @"CFBundleName": @"TestApp",
        @"CFBundleVersion": @"1",
        @"CFBundleIdentifier": @"com.test.app",
        @"CFBundleShortVersionString": @"1.0",
        @"UIDeviceFamily": @[@2]
    };
    info.ipaInfoPlist = plist;
    XCTAssertEqualObjects(info.supportedDevice, @"iPad");
}

- (void)testSetIpaInfoPlist_SupportedDevice_Universal {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    NSDictionary *plist = @{
        @"CFBundleName": @"TestApp",
        @"CFBundleVersion": @"1",
        @"CFBundleIdentifier": @"com.test.app",
        @"CFBundleShortVersionString": @"1.0",
        @"UIDeviceFamily": @[@1, @2]
    };
    info.ipaInfoPlist = plist;
    XCTAssertEqualObjects(info.supportedDevice, @"iPhone and iPad");
}

- (void)testSetIpaInfoPlist_GeneratesUUID {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    NSDictionary *plist = @{
        @"CFBundleName": @"TestApp",
        @"CFBundleVersion": @"1",
        @"CFBundleIdentifier": @"com.test.app",
        @"CFBundleShortVersionString": @"1.0"
    };
    info.ipaInfoPlist = plist;
    XCTAssertNotNil(info.uuid);
    XCTAssertGreaterThan(info.uuid.length, 0);
}

- (void)testSetIpaInfoPlist_NameStripsSpaces {
    IPAUploadInfo *info = [[IPAUploadInfo alloc] initEmpty];
    NSDictionary *plist = @{
        @"CFBundleName": @"My Cool App",
        @"CFBundleVersion": @"1",
        @"CFBundleIdentifier": @"com.test.app",
        @"CFBundleShortVersionString": @"1.0"
    };
    info.ipaInfoPlist = plist;
    XCTAssertEqualObjects(info.name, @"MyCoolApp");
}

@end
