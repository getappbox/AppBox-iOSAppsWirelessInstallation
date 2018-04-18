//
//  XCProject.m
//  AppBox
//
//  Created by Vineet Choudhary on 03/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "XCProject.h"

@implementation XCProject

#pragma mark - Helper
-(void)createUDIDAndIsNew:(BOOL)isNew{
    if (isNew || _uuid == nil){
        [self setUuid: [Common generateUUID]];
    }
}

-(NSString *)buildMailURLStringForEmailId:(NSString *)mailId andMessage:(NSString *)message{
    NSMutableString *mailString = [NSMutableString stringWithString:abMailerBaseURL];
    [mailString appendFormat:@"?to=%@",mailId];
    [mailString appendFormat:@"&app=%@",self.name];
    [mailString appendFormat:@"&ver=%@",self.version];
    [mailString appendFormat:@"&build=%@",self.build];
    [mailString appendFormat:@"&link=%@",self.appShortShareableURL.stringValue];
    [mailString appendFormat:@"&devmsg=%@",message];
    return mailString;
}

-(void)createManifestWithIPAURL:(NSURL *)ipaURL completion:(void(^)(NSURL *manifestURL))completion{
    NSMutableDictionary *assetsDict = [[NSMutableDictionary alloc] init];
    [assetsDict setValue:self.ipaFileDBShareableURL.absoluteString forKey:@"url"];
    [assetsDict setValue:@"software-package" forKey:@"kind"];
    
    //TODO: Upload ICONS
    NSMutableDictionary *iconDict = [[NSMutableDictionary alloc] init];
    [iconDict setValue:@"display-image" forKey:@"kind"];
    [iconDict setValue:NO forKey:@"needs-shine"];
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
    
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"\n\n======\nManifest\n======\n\n %@",manifestDict]];
    
    NSString *manifestPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"manifest.plist"];
    if ([manifestDict writeToFile:manifestPath atomically:YES]){
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Menifest File Created and Saved at %@", manifestPath]];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion([NSURL fileURLWithPath:manifestPath]);
        });
    }else{
        [[AppDelegate appDelegate] addSessionLog:@"Can't able to save menifest file"];
        completion(nil);
    }
}

//Create export options plist for archive and upload
- (BOOL)createExportOptionPlist{
    [self createBuildRelatedPathsAndIsNew:YES];
    NSMutableDictionary *exportOption = [[NSMutableDictionary alloc] init];
    [exportOption setValue:self.teamId forKey:@"teamID"];
    [exportOption setValue:self.buildType forKey:@"method"];
    [exportOption setValue:[NSNumber numberWithBool:[UserData uploadBitcode]] forKey:@"uploadBitcode"];
    [exportOption setValue:[NSNumber numberWithBool:[UserData uploadSymbols]] forKey:@"uploadSymbols"];
    [exportOption setValue:[NSNumber numberWithBool:[UserData compileBitcode]] forKey:@"compileBitcode"];
    [exportOption setValue:@"automatic" forKey:@"signingStyle"];
    return [exportOption writeToFile:[self.exportOptionsPlistPath.resourceSpecifier stringByRemovingPercentEncoding] atomically:YES];
}

//Create all path required during archive and upload
- (void)createBuildRelatedPathsAndIsNew:(BOOL)isNew{
    if(isNew || _buildUUIDDirectory == nil){
        //Current Time as UUID
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"dd-MM-yyyy-HH-mm-ss"];
        NSString *currentTime = [dateFormat stringFromDate:[[NSDate alloc] init]];
        
        //Build UUID Path
        NSString *buildUUIDPath = [_buildDirectory.resourceSpecifier stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@",self.name, currentTime]];
        _buildUUIDDirectory = [NSURL URLWithString:buildUUIDPath];
        [[NSFileManager defaultManager] createDirectoryAtPath:buildUUIDPath withIntermediateDirectories:NO attributes:nil error:nil];
        
        //Archive Path
        NSString *archivePath = [_buildUUIDDirectory.resourceSpecifier stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xcarchive",self.name]];
        _buildArchivePath =  [NSURL URLWithString:archivePath];
        
        //IPA Path
        NSString *ipaPath = [_buildUUIDDirectory.resourceSpecifier stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.ipa", self.selectedSchemes]];
        _ipaFullPath = [NSURL URLWithString:[ipaPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        //Export Option Plist
        NSString *exportOptionPlistPath = [_buildUUIDDirectory.resourceSpecifier stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-ExportOptions.plist", self.name]];
        _exportOptionsPlistPath = [NSURL URLWithString:exportOptionPlistPath];
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

#pragma mark - Getter
- (NSString *)uuid{
    [self createUDIDAndIsNew:NO];
    return _uuid;
}

- (NSURL *)buildArchivePath{
    [self createBuildRelatedPathsAndIsNew:NO];
    return _buildArchivePath;
}

#pragma mark - Setter

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

-(void)setProjectFullPath:(NSURL *)projectFullPath{
    _projectFullPath = projectFullPath;
    [self setRootDirectory: [Common getFileDirectoryForFilePath:projectFullPath]];
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
        if (!self.teamId) self.teamId = self.mobileProvision.teamId;
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
        [self setDbAppInfoJSONFullPath:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",validBundleDirectory,abAppInfoFileName]]];
    } else {
        [self setDbAppInfoJSONFullPath:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",toPath, abAppInfoFileName]]];
    }
}

- (void)setBuildListInfo:(NSDictionary *)buildListInfo{
    if ([buildListInfo.allKeys containsObject:@"project"]) {
        _buildListInfo = buildListInfo;
        NSDictionary *projectInfo = [buildListInfo valueForKey:@"project"];
        [self setName: [projectInfo valueForKey:@"name"]];
        [self setSchemes: [projectInfo valueForKey:@"schemes"]];
        [self setTargets: [projectInfo valueForKey:@"targets"]];
    }
}

-(NSString *)validURLString:(NSString *)urlString{
    NSString *temp = [[urlString componentsSeparatedByCharactersInSet:[NSCharacterSet URLQueryAllowedCharacterSet].invertedSet] componentsJoinedByString:@""];
    return temp.length == 0 ? @"AppBox" : temp;
}

@end
