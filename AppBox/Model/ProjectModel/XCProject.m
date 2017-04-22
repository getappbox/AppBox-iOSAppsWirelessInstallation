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
    [mailString appendFormat:@"&link=%@",self.appShortShareableURL.absoluteString];
    [mailString appendFormat:@"&devmsg=%@",message];
    return mailString;
}

-(void)createManifestWithIPAURL:(NSURL *)ipaURL completion:(void(^)(NSURL *manifestURL))completion{
    NSMutableDictionary *assetsDict = [[NSMutableDictionary alloc] init];
    [assetsDict setValue:self.ipaFileDBShareableURL.absoluteString forKey:@"url"];
    [assetsDict setValue:@"software-package" forKey:@"kind"];
    
    NSMutableDictionary *metadataDict = [[NSMutableDictionary alloc] init];
    [metadataDict setValue:@"software" forKey:@"kind"];
    [metadataDict setValue:self.name forKey:@"title"];
    [metadataDict setValue:self.identifer forKey:@"bundle-identifier"];
    [metadataDict setValue:[self.version stringByAppendingFormat:@" (%@)", self.build] forKey:@"bundle-version"];
    
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

- (void)setName:(NSString *)name{
    _name = [name stringByReplacingOccurrencesOfString:@" " withString:abEmptyString];
}

- (void)setFullPath:(NSURL *)fullPath{
    _fullPath = fullPath;
    [self setRootDirectory: [Common getFileDirectoryForFilePath:fullPath]];
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

    //Bundle directory path
    NSString *bundlePath = [NSString stringWithFormat:@"/%@",self.identifer];
    [self setBundleDirectory:[NSURL URLWithString:bundlePath]];
    [self upadteDbDirectoryByBundleDirectory];
}

- (void)upadteDbDirectoryByBundleDirectory{
    //Build URL for DropBox
    NSString *toPath = [self.bundleDirectory.absoluteString stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-ver%@(%@)-%@",self.name,self.version,self.build,self.uuid]];
    [self setDbDirectory:[NSURL URLWithString:toPath]];
    [self setDbIPAFullPath:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@.ipa",toPath,self.name]]];
    [self setDbManifestFullPath:[NSURL URLWithString:[NSString stringWithFormat:@"%@/manifest.plist",toPath]]];
    [self setDbAppInfoJSONFullPath:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",self.bundleDirectory,abAppInfoFileName]]];
}

- (void)setBuildListInfo:(NSDictionary *)buildListInfo{
    if ([buildListInfo.allKeys containsObject:@"project"]) {
        _buildListInfo = buildListInfo;
        NSDictionary *projectInfo = [buildListInfo valueForKey:@"project"];
        [self setName: [projectInfo valueForKey:@"name"]];
        [self setSchemes: [projectInfo valueForKey:@"schemes"]];
        [self setTargets: [projectInfo valueForKey:@"targets"]];
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"\n\n======\nBuild List Info\n======\n\n %@",buildListInfo]];
    }
}

@end
