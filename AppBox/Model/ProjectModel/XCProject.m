//
//  XCProject.m
//  AppBox
//
//  Created by Vineet Choudhary on 03/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "XCProject.h"

@implementation XCProject

//MARK: - Init

- (instancetype)initEmpty {
    self = [super init];
    if (self) {
        self.keepSameLink = @0;
        self.emails = abEmptyString;
        self.buildType = abEmptyString;
        self.personalMessage = abEmptyString;
    }
    return self;
}

//MARK: - Helper
-(void)createUDIDAndIsNew:(BOOL)isNew{
    if (isNew || _uuid == nil){
        [self setUuid: [Common generateUUID]];
    }
}

-(void)createManifestWithIPAURL:(NSURL *)ipaURL completion:(void(^)(NSURL *manifestURL))completion{
    NSMutableDictionary *assetsDict = [[NSMutableDictionary alloc] init];
    [assetsDict setValue:self.ipaFileDBShareableURL.absoluteString forKey:@"url"];
    [assetsDict setValue:@"software-package" forKey:@"kind"];
    
    //TODO: Upload ICONS
    NSMutableDictionary *iconDict = [[NSMutableDictionary alloc] init];
    [iconDict setValue:@"display-image" forKey:@"kind"];
    [iconDict setValue:@NO forKey:@"needs-shine"];
    [iconDict setValue:@"" forKey:@"url"];
    
    NSMutableDictionary *metadataDict = [[NSMutableDictionary alloc] init];
    [metadataDict setValue:@"software" forKey:@"kind"];
    [metadataDict setValue:self.name forKey:@"title"];
    [metadataDict setValue:self.identifer forKey:@"bundle-identifier"];
    [metadataDict setValue:self.version forKey:@"bundle-version"];
    
    NSMutableDictionary *mainItemDict = [[NSMutableDictionary alloc] init];
    [mainItemDict setValue:[NSArray arrayWithObjects:assetsDict, nil] forKey:@"assets"];
    [mainItemDict setValue:metadataDict forKey:@"metadata"];
    
    NSMutableDictionary *manifestDict = [[NSMutableDictionary alloc] init];
    [manifestDict setValue:[NSArray arrayWithObjects:mainItemDict, nil] forKey:@"items"];
    
	DDLogDebug(@"\n\n======\nManifest\n======\n\n %@",manifestDict);
    
    NSString *manifestPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"manifest.plist"];
    if ([manifestDict writeToFile:manifestPath atomically:YES]){
        DDLogDebug(@"Menifest File Created and Saved at %@", manifestPath);
        dispatch_async(dispatch_get_main_queue(), ^{
            completion([NSURL fileURLWithPath:manifestPath]);
        });
    }else{
		DDLogInfo(@"Can't able to save menifest file");
        completion(nil);
    }
}

//validate info plist for current project
- (BOOL)isValidProjectInfoPlist{
    if (self.ipaInfoPlist == nil){
        return false;
    }
    
    //check required value for manifest file
    if (self.name != nil && self.build != nil && self.identifer != nil && self.version != nil){
        return true;
    }
    return false;
}

//MARK: - Getter
- (NSString *)uuid{
    [self createUDIDAndIsNew:NO];
    return _uuid;
}

-(ABPProject *)abpProject{
    ABPProject *project = [[ABPProject alloc] init];
    [project setName:self.name];
    [project setVersion:self.version];
    [project setBuild:self.build];
    [project setIdentifer:self.identifer];
    [project setBuildType:self.buildType];
    [project setIpaFileSize:self.ipaFileSize];
    [project setMiniOSVersion:self.miniOSVersion];
    [project setSupportedDevice:self.supportedDevice];
    
    [project setIsKeepSameLinkEnabled:self.isKeepSameLinkEnabled];
    [project setUniquelinkShareableURL:self.uniquelinkShareableURL];
    
    [project setDbAppInfoJSONFullPath:self.dbAppInfoJSONFullPath];
    [project setAppShortShareableURL:self.appShortShareableURL];
    
    [project setEmails:self.emails];
    [project setPersonalMessage:self.personalMessage];
    [project setDbManager:[Common currentDBManager]];
    
    return project;
}

//MARK: - Setter

-(void)setIpaFullPath:(NSURL *)ipaFullPath{
    _ipaFullPath = ipaFullPath;
    NSError *error;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:ipaFullPath.resourceSpecifier.stringByRemovingPercentEncoding error:&error];
    if (error) {
        _ipaFileSize = [NSNumber numberWithLongLong:0];
    } else {
        NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
        long long fileSize = [fileSizeNumber longLongValue];
        _ipaFileSize = [NSNumber numberWithLongLong:(fileSize/1000000)];
    }
    
}

- (void)setName:(NSString *)name{
    _name = [name stringByReplacingOccurrencesOfString:@" " withString:abEmptyString];
}

- (void)setIpaInfoPlist:(NSDictionary *)ipaInfoPlist{
    _ipaInfoPlist = ipaInfoPlist;
    [self createUDIDAndIsNew:YES];
    if ([ipaInfoPlist valueForKey:@"CFBundleName"] != nil){
        [self setName: [ipaInfoPlist valueForKey:@"CFBundleName"]];
    }
    [self setBuild: [ipaInfoPlist valueForKey:@"CFBundleVersion"]];
    [self setIdentifer:[self.ipaInfoPlist valueForKey:@"CFBundleIdentifier"]];
    [self setVersion: [ipaInfoPlist valueForKey:@"CFBundleShortVersionString"]];
    [self setMiniOSVersion:[ipaInfoPlist valueForKey:@"MinimumOSVersion"]];
    
    //Supported Devices
    NSArray *supportedDeviceKey = [ipaInfoPlist valueForKey:@"UIDeviceFamily"];
    NSMutableString *supportedDevice = [[NSMutableString alloc] init];
    [supportedDeviceKey enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj integerValue] == 1) {
            [supportedDevice appendString:@"iPhone"];
        } else if ([obj integerValue] == 2) {
            if (supportedDevice.length > 0){
                [supportedDevice appendString:@" and "];
            }
            [supportedDevice appendString:@"iPad"];
        }
    }];
    [self setSupportedDevice:supportedDevice];
    
    //Bundle directory path
    NSString *bundlePath = [NSString stringWithFormat:@"/%@",self.identifer];
    if (self.bundleDirectory.absoluteString.length == 0){
        [self setBundleDirectory:[NSURL URLWithString:bundlePath]];
    }
    [self upadteDbDirectoryByBundleDirectory];
}

-(void)setMobileProvision:(MobileProvision *)mobileProvision{
    _mobileProvision = mobileProvision;
    if (self.mobileProvision){
        if (!self.buildType) self.buildType = self.mobileProvision.buildType;
    }
}

- (void)upadteDbDirectoryByBundleDirectory{
    //Build URL for DropBox
    NSString *validName = [self validURLString:self.name];
    NSString *validVersion = [self validURLString:self.version];
    NSString *validBuild = [self validURLString:self.build];
    NSString *validUUID = [self validURLString:self.uuid];
    NSString *validBundleDirectory = [self validURLString:self.bundleDirectory.absoluteString];
    
    NSString *toPath = [validBundleDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-ver%@(%@)-%@",validName, validVersion, validBuild, validUUID]];
    [self setDbDirectory:[NSURL URLWithString:toPath]];
    
    NSString * dbIPAFullPathString = [NSString stringWithFormat:@"%@/%@.ipa", toPath, validName];
    [self setDbIPAFullPath:[NSURL URLWithString:dbIPAFullPathString]];
    
    [self setDbManifestFullPath:[NSURL URLWithString:[NSString stringWithFormat:@"%@/manifest.plist",toPath]]];
    
    if (self.isKeepSameLinkEnabled){
        [self setDbAppInfoJSONFullPath:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",validBundleDirectory,FILE_NAME_UNIQUE_JSON]]];
    } else {
        [self setDbAppInfoJSONFullPath:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",toPath, FILE_NAME_UNIQUE_JSON]]];
    }
}

-(NSString *)validURLString:(NSString *)urlString{
    NSString *temp = [[urlString componentsSeparatedByCharactersInSet:[NSCharacterSet URLQueryAllowedCharacterSet].invertedSet] componentsJoinedByString:@""];
    return temp.length == 0 ? @"AppBox" : temp;
}

- (BOOL)exportSharedURLInSystemFile {
    // Set Shared Variables
    NSMutableDictionary *exportVariable = [[NSMutableDictionary alloc] init];
    [exportVariable setValue: [NSString stringWithFormat:@"%@", self.appShortShareableURL] forKey: @"APPBOX_SHARE_URL"];
    [exportVariable setValue: [NSString stringWithFormat:@"%@", self.appLongShareableURL] forKey: @"APPBOX_LONG_SHARE_URL"];
    [exportVariable setValue: [NSString stringWithFormat:@"%@", self.ipaFileDBShareableURL] forKey: @"APPBOX_IPA_URL"];
    [exportVariable setValue: [NSString stringWithFormat:@"%@", self.manifestFileSharableURL] forKey: @"APPBOX_MANIFEST_URL"];
    
    NSString *path = [[NSString stringWithFormat:@"~/%@", FILE_NAME_SHARE_URL] stringByExpandingTildeInPath];
    if([[NSFileManager defaultManager] fileExistsAtPath:path]){
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:exportVariable options:NSJSONWritingPrettyPrinted error:&error];
    return [jsonData writeToFile:path atomically:YES];
}

@end
