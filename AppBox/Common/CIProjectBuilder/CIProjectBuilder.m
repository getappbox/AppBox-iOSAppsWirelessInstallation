//
//  RepoBuilder.m
//  AppBox
//
//  Created by Vineet Choudhary on 07/04/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "CIProjectBuilder.h"

//Project
NSString * const RepoProjectKey = @"project";
NSString * const RepoSchemeKey = @"scheme";
NSString * const RepoBuildTypeKey = @"buildtype";
NSString * const RepoTeamIdKey = @"teamid";
NSString * const RepoKeepSameLinkKey = @"keepsamelink";
NSString * const RepoDropboxFolderNameKey = @"dropboxfoldername";
NSString * const RepoEmailKey = @"email";
NSString * const RepoPersonalMessageKey = @"personalmessage";

//xcode
NSString * const XcodeVersionKey = @"xcode";
NSString * const XcodeVersionIdentifier = @"{VERSION}";

//Certificate
NSString * const RepoCertificateNameKey = @"name";
NSString * const RepoCertificatePasswordKey = @"password";
NSString * const RepoCertificateDirectoryName = @"cert";

//iTunesConnect
NSString *const RepoITCEmail = @"itcemail";
NSString *const RepoITCPassword = @"itcpassword";

@implementation CIProjectBuilder{
    
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
    XCProject *project = [[XCProject alloc] initEmpty];
    
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
        NSURL *projectURL = [NSURL fileURLWithPath:projectPath];
        project.projectFullPath = projectURL;
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
    
    //Dropbox folder name
    if ([projectRawSetting.allKeys containsObject:RepoDropboxFolderNameKey]) {
        project.keepSameLink = [projectRawSetting valueForKey:RepoKeepSameLinkKey];
    }
    
    //xcode version
    if ([projectRawSetting.allKeys containsObject:XcodeVersionKey] && [UserData xcodeVersionPath]) {
        NSString *xcodeVersion = [projectRawSetting valueForKey:XcodeVersionKey];
        NSString *xcodeVersionPath = [[UserData xcodeVersionPath] stringByReplacingOccurrencesOfString:XcodeVersionIdentifier withString:xcodeVersion];
        [project setAlPath:[XCHandler checkALPath:xcodeVersionPath]];
        [project setXcodePath:[XCHandler checkXCodePath:xcodeVersionPath]];
    }
    
    //Emails
    if ([projectRawSetting.allKeys containsObject:RepoEmailKey]) {
        [project setEmails:[projectRawSetting valueForKey:RepoEmailKey]];
    }
    
    
    //Email Personal Message
    if ([projectRawSetting.allKeys containsObject:RepoPersonalMessageKey]) {
        project.personalMessage = [projectRawSetting valueForKey:RepoPersonalMessageKey];
    }
    
    
    //Replace current settings from command line arguments
    [[self class] setCommonArgumentsToProject:project];
    
    
    //app-store and itcmail check
    bool isAppStoreBuild = (project.buildType != nil && [project.buildType isEqualToString: BuildTypeAppStore]);
    if (isAppStoreBuild && ![projectRawSetting.allKeys containsObject:RepoITCEmail]) {
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"AppStore Connect Account email not available in appbox.plist. You need to add \"%@\" key with AppStore Connect Account email id in appbox.plist. Read more here - %@", RepoITCEmail, abCICDAppStore]];
        exit(abExitCodeITCMailNotFound);
    }
    
    //itcemail
    if (isAppStoreBuild && [projectRawSetting.allKeys containsObject:RepoITCEmail]) {
        project.itcUserName = [projectRawSetting valueForKey:RepoITCEmail];
        if ([MailHandler isAllValidEmail:project.itcUserName]) {
            NSString *password = [SAMKeychain passwordForService:abiTunesConnectService account:project.itcUserName];
            if (password == nil || password.length == 0) {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"iTunes Connect Account %@ not available in keychain. Please add account in AppBox first. Read more here - %@", project.itcUserName, abCICDAppStore]];
                exit(abExitCodeForInvalidITCAccount);
            } else {
                project.itcPasswod = password;
            }
        } else if (project.itcUserName.length > 0) {
            [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"iTunes Connect Account %@ not a valid email. Please enter a valid email address.", project.itcUserName]];
            exit(abExitCodeForInvalidITCAccount);
        }
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
    
    [project setItcUserName:repoProject.itcUserName];
    [project setItcPasswod:repoProject.itcPasswod];
    
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

#pragma mark - IPA
+ (XCProject *)xcProjectWithIPAPath:(NSString *)ipaPath {
    XCProject *project = [[XCProject alloc] initEmpty];
    project.ipaFullPath = [NSURL fileURLWithPath:ipaPath];
    [[self class] setCommonArgumentsToProject:project];
    return project;
}


#pragma mark - Common Arguments
+(void)setCommonArgumentsToProject:(XCProject *)project {
    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    [ABLog log:@"All Command Line Arguments = %@",arguments];
    for (NSString *argument in arguments) {
        //Project Scheme
        if ([argument containsString:abArgsScheme]) {
            NSArray *components = [argument componentsSeparatedByString:abArgsScheme];
            [ABLog log:@"Scheme Components = %@",components];
            if (components.count == 2) {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Changing project scheme to %@ from %@", [components lastObject], project.selectedSchemes]];
                project.selectedSchemes = [components lastObject];
            } else {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Invalid Scheme Argument %@",arguments]];
                exit(abExitCodeForInvalidCommand);
            }
        }
        
        //Project Build Type
        else if ([argument containsString:abArgsBuildType]) {
            NSArray *components = [argument componentsSeparatedByString:abArgsBuildType];
            [ABLog log:@"BuildType Components = %@",components];
            if (components.count == 2) {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Changing project build type to %@ from %@", [components lastObject], project.buildType]];
                project.buildType = [components lastObject];
            } else {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Invalid BuildType Argument %@",arguments]];
                exit(abExitCodeForInvalidCommand);
            }
        }
        
        //Project Team Id
        else if ([argument containsString:abArgsTeamId]) {
            NSArray *components = [argument componentsSeparatedByString:abArgsTeamId];
            [ABLog log:@"TeamId Components = %@",components];
            if (components.count == 2) {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Changing project TeamId to %@ from %@", [components lastObject], project.teamId]];
                project.teamId = [components lastObject];
            } else {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Invalid TeamId Argument %@",arguments]];
                exit(abExitCodeForInvalidCommand);
            }
        }
        
        //Project Emails
        else if ([argument containsString:abArgsEmails]) {
            NSArray *components = [argument componentsSeparatedByString:abArgsEmails];
            [ABLog log:@"Email Components = %@", components];
            if (components.count == 2) {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Changing project Emails to %@ from %@", [components lastObject], project.emails]];
                project.emails = [components lastObject];
            } else {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Invalid Emails Argument %@",arguments]];
                exit(abExitCodeForInvalidCommand);
            }
        }
        
        //Project Personal Messages
        else if ([argument containsString:abArgsPersonalMessage]) {
            NSArray *components = [argument componentsSeparatedByString:abArgsPersonalMessage];
            [ABLog log:@"Personal Message Components = %@", components];
            if (components.count == 2) {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Changing project personal message to %@ from %@", [components lastObject], project.personalMessage]];
                project.personalMessage = [components lastObject];
            } else {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Invalid Personal Message Argument %@",arguments]];
                exit(abExitCodeForInvalidCommand);
            }
        }
        
        //Project Personal Messages
        else if ([argument containsString:abArgsKeepSameLink]) {
            NSArray *components = [argument componentsSeparatedByString:abArgsKeepSameLink];
            [ABLog log:@"Keep Same Links Components = %@", components];
            if (components.count == 2) {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Changing project personal message to %@ from %@", [components lastObject], project.personalMessage]];
                project.keepSameLink = [[components lastObject] isEqualToString:@"0"] ? @0 : @1;
            } else {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Invalid Personal Message Argument %@",arguments]];
                exit(abExitCodeForInvalidCommand);
            }
        }
        
        //Project dropbox folder name
        else if ([argument containsString:abArgsDropBoxFolderName]) {
            NSArray *components = [argument componentsSeparatedByString:abArgsDropBoxFolderName];
            [ABLog log:@"Dropbox folder Components = %@", components];
            if (components.count == 2) {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Changing Dropbox folder name to %@ from %@", [components lastObject], project.personalMessage]];
                //project.db = [components lastObject];
            } else {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Invalid Dropbox Folder Name Argument %@",arguments]];
                exit(abExitCodeForInvalidCommand);
            }
        }
        
        //Email and Email Subject Prefix
        NSMutableSet *emails = [[NSMutableSet alloc] init];
        
        if ([UserData defaultCIEmail].length > 0) {
            [emails addObjectsFromArray:[[UserData defaultCIEmail] componentsSeparatedByString:@","]];
        }
        
        if (project.emails && project.emails.length > 0) {
            [emails addObjectsFromArray:[project.emails componentsSeparatedByString:@","]];
        }
        
        [emails removeObject:@""];
        if (emails.count > 0) {
            project.subjectPrefix = [UserData ciSubjectPrefix];
            project.emails = [emails.allObjects componentsJoinedByString:@","];
        }
        
    }
}

@end

