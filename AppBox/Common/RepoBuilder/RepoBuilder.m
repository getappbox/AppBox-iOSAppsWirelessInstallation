//
//  RepoBuilder.m
//  AppBox
//
//  Created by Vineet Choudhary on 07/04/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "RepoBuilder.h"

NSString * const RepoProjectKey = @"project";
NSString * const RepoSchemeKey = @"scheme";
NSString * const RepoBuildTypeKey = @"buildtype";
NSString * const RepoTeamIdKey = @"teamid";
NSString * const RepoKeepSameLinkKey = @"keepsamelink";
NSString * const RepoDropboxFolderNameKey = @"dropboxfoldername";
NSString * const RepoEmailKey = @"email";
NSString * const RepoPersonalMessageKey = @"personalmessage";

NSString * const RepoCertificateNameKey = @"name";
NSString * const RepoCertificatePasswordKey = @"password";

NSString * const RepoCertificateDirectoryName = @"cert";


@implementation RepoBuilder{
    
}

#pragma mark - Settings
+ (NSString *)isValidRepoForSettingFileAtPath:(NSString *)path Index:(NSNumber *)number {
    NSString *file = [NSString stringWithFormat:@"appbox%@.plist", (number.integerValue == 0) ? @"" : number];
    NSString *repoSettingPlist = [path stringByAppendingPathComponent:file];
    if ([[NSFileManager defaultManager] fileExistsAtPath:repoSettingPlist]) {
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Setting path = %@",repoSettingPlist]];
        return repoSettingPlist;
    }else {
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"File not found at path = %@", repoSettingPlist]];
    }
    return nil;
}

+ (XCProject *)xcProjectWithRepoPath:(NSString *)repoPath andSettingFilePath:(NSString *)settingPath {
    XCProject *project = [[XCProject alloc] init];
    
    //get project raw setting from plist
    NSDictionary *projectRawSetting = [NSDictionary dictionaryWithContentsOfFile:settingPath];
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Project Raw Setting - %@", projectRawSetting]];
    if (projectRawSetting == nil) {
        return nil;
    }
    
    //project path
    if ([projectRawSetting.allKeys containsObject:RepoProjectKey]) {
        NSString *projectPath = [repoPath stringByAppendingPathComponent:[projectRawSetting valueForKey:RepoProjectKey]];
        projectPath = [@"file://" stringByAppendingString:projectPath];
        NSURL *projectURL = [[NSURL URLWithString:projectPath] filePathURL];
        project.fullPath = projectURL;
    }
    
    //project scheme
    if ([projectRawSetting.allKeys containsObject:RepoSchemeKey]) {
        project.selectedSchemes = [projectRawSetting valueForKey:RepoSchemeKey];
    }
    
    //project build type
    if ([projectRawSetting.allKeys containsObject:RepoBuildTypeKey]) {
        project.buildType = [projectRawSetting valueForKey:RepoBuildTypeKey];
    }
    
    //project teamid
    if ([projectRawSetting.allKeys containsObject:RepoTeamIdKey]) {
        project.teamId = [projectRawSetting valueForKey: RepoTeamIdKey];
    }
    
    if ([projectRawSetting.allKeys containsObject:RepoDropboxFolderNameKey]) {
        project.keepSameLink = [projectRawSetting valueForKey:RepoKeepSameLinkKey];
    }
    
    if ([projectRawSetting.allKeys containsObject:RepoEmailKey]) {
        project.emails = [projectRawSetting valueForKey:RepoEmailKey];
    }
    
    if ([projectRawSetting.allKeys containsObject:RepoPersonalMessageKey]) {
        project.personalMessage = [projectRawSetting valueForKey:RepoPersonalMessageKey];
    }
    
    return project;
}

+ (void)setProjectSettingFromProject:(XCProject *)repoProject toProject:(XCProject *)project {
    if ([project.schemes containsObject:repoProject.selectedSchemes]) {
        project.selectedSchemes = repoProject.selectedSchemes;
        project.buildType = repoProject.buildType;
    }
    
    NSArray *allTeamIds = [KeychainHandler getAllTeamId];
    NSDictionary *team = [[allTeamIds filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.teamId = %@",repoProject.teamId]] firstObject];
    if (team != nil) {
        [project setTeamId: [team valueForKey:abTeamId]];
    }
    
    [project setEmails:repoProject.emails];
    [project setPersonalMessage:repoProject.personalMessage];
}

#pragma mark - Certificates 
    
+ (NSString *)isValidRepoForCertificateFileAtPath:(NSString *)path {
    NSString *repoCertificatePlist = [path stringByAppendingPathComponent:RepoCertificateDirectoryName];
    repoCertificatePlist = [repoCertificatePlist stringByAppendingPathComponent:@"appbox.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:repoCertificatePlist]) {
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Cert path = %@",repoCertificatePlist]];
        return repoCertificatePlist;
    }
    return nil;
}
    
+ (void)installCertificateWithDetailsInFile:(NSString *)detailsFilePath andRepoPath:(NSString *)repoPath {
    NSArray *certificateDetails = [NSArray arrayWithContentsOfFile:detailsFilePath];
    for (NSDictionary *details in certificateDetails) {
        NSString *certificate = [details valueForKey:RepoCertificateNameKey];
        NSString *password = [details valueForKey:RepoCertificatePasswordKey];
        NSString *certificatePath = [repoPath stringByAppendingPathComponent:RepoCertificateDirectoryName];
        certificatePath = [certificatePath stringByAppendingPathComponent:certificate];
        [KeychainHandler installPrivateKeyFromPath:certificatePath withPassword:password];
    }
}
    

@end
