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

-(void)createManifestWithIPAURL:(NSURL *)ipaURL completion:(void(^)(NSString *manifestPath))completion{
    NSMutableDictionary *assetsDict = [[NSMutableDictionary alloc] init];
    [assetsDict setValue:self.ipaFileDBShareableURL.absoluteString forKey:@"url"];
    [assetsDict setValue:@"software-package" forKey:@"kind"];
    
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
    
    NSString *manifestPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"manifest.plist"];
    [manifestDict writeToFile:manifestPath atomically:YES];
    
    [[AppDelegate appDelegate].sessionLog appendFormat:@"\n\n======\nManifest\n======\n\n %@",manifestDict];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        completion(manifestPath);
    });
}

- (void)createExportOpetionPlist{
    [self createBuildRelatedPathsAndIsNew:YES];
    NSMutableDictionary *exportOption = [[NSMutableDictionary alloc] init];
    [exportOption setValue:self.teamId forKey:@"teamID"];
    [exportOption setValue:self.buildType forKey:@"method"];
    [exportOption writeToFile:self.exportOptionsPlistPath.resourceSpecifier atomically:YES];
}

- (void)createBuildRelatedPathsAndIsNew:(BOOL)isNew{
    
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
    NSString *ipaPath = [_buildUUIDDirectory.resourceSpecifier stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.ipa", self.name]];
    _ipaFullPath = [NSURL URLWithString:ipaPath];
    
    //Export Option Plist
    NSString *exportOptionPlistPath = [_buildUUIDDirectory.resourceSpecifier stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-ExportOptions.plist", [[self.targets firstObject] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    _exportOptionsPlistPath = [NSURL URLWithString:exportOptionPlistPath];
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

- (void)setName:(NSString *)name{
    _name = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
}

- (void)setFullPath:(NSURL *)fullPath{
    _fullPath = fullPath;
    [self setRootDirectory: [Common getFileDirectoryForFilePath:fullPath]];
}


- (void)setIpaInfoPlist:(NSDictionary *)ipaInfoPlist{
    _ipaInfoPlist = ipaInfoPlist;
    [self createUDIDAndIsNew:YES];
    if (self.name == nil){
        [self setName: [ipaInfoPlist valueForKey:@"CFBundleName"]];
    }
    [self setBuild: [ipaInfoPlist valueForKey:@"CFBundleVersion"]];
    [self setIdentifer:[self.ipaInfoPlist valueForKey:@"CFBundleIdentifier"]];
    [self setVersion: [ipaInfoPlist valueForKey:@"CFBundleShortVersionString"]];
    NSString *toPath = [NSString stringWithFormat:@"/%@-ver%@(%@)-%@",self.name,self.version,self.build,self.uuid];
    [self setDbDirectory:[NSURL URLWithString:toPath]];
}

- (void)setBuildListInfo:(NSDictionary *)buildListInfo{
    if ([buildListInfo.allKeys containsObject:@"project"]) {
        _buildListInfo = buildListInfo;
        NSDictionary *projectInfo = [buildListInfo valueForKey:@"project"];
        [self setName: [projectInfo valueForKey:@"name"]];
        [self setSchemes: [projectInfo valueForKey:@"schemes"]];
        [self setTargets: [projectInfo valueForKey:@"targets"]];
        [[AppDelegate appDelegate].sessionLog appendFormat:@"\n\n======\nBuild List Info\n======\n\n %@",buildListInfo];
    }
}

@end
