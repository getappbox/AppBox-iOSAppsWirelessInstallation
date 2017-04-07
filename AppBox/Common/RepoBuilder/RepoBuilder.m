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
NSString * const PersonalMessageKey = @"personalmessage";

@implementation RepoBuilder{
    
}

+ (NSString *)isValidRepoForSetingFileAtPath:(NSString *)path Index:(NSNumber *)number {
    NSString *file = [NSString stringWithFormat:@"appbox%@.plist", (number.integerValue == 0) ? @"" : number];
    NSString *repoSettingPlist = [path stringByAppendingPathComponent:file];
    if ([[NSFileManager defaultManager] fileExistsAtPath:repoSettingPlist]) {
        return repoSettingPlist;
    }
    return nil;
}

+ (XCProject *)xcProjectWithRepoPath:(NSString *)repoPath andSettingFilePath:(NSString *)settingPath {
    XCProject *project = [[XCProject alloc] init];
    
    //get project raw setting from plist
    NSDictionary *projectRawSetting = [NSDictionary dictionaryWithContentsOfFile:settingPath];
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
//        project.keepSameLink = [projectRawSetting valueForKey:RepoDropboxFolderNameKey];
    }
    
    if ([projectRawSetting.allKeys containsObject:RepoEmailKey]) {
        project.emails = [projectRawSetting valueForKey:RepoEmailKey];
    }
    
    if ([projectRawSetting.allKeys containsObject:PersonalMessageKey]) {
        project.personalMessage = [projectRawSetting valueForKey:PersonalMessageKey];
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



@end
