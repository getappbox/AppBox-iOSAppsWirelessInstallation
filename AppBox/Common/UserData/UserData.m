//
//  UserData.m
//  AppBox
//
//  Created by Vineet Choudhary on 12/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "UserData.h"


@implementation UserData

#pragma mark - Gmail Logged In
#define GmailLoggedIn @"GmailLoggedIn"

+(BOOL)isGmailLoggedIn{
    return [[NSUserDefaults standardUserDefaults] boolForKey:GmailLoggedIn];
}

+(void)setIsGmailLoggedIn:(BOOL)isGmailLoggedIn{
    [[NSUserDefaults standardUserDefaults] setBool:isGmailLoggedIn forKey:GmailLoggedIn];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Email Releated
#define UserEmail @"UserEmail"
#define UserMessage @"UserMessage"

+(NSString *)userEmail{
    NSString *userEmail = [[NSUserDefaults standardUserDefaults] stringForKey:UserEmail];
    return userEmail == nil ? abEmptyString : userEmail;
}

+(void)setUserEmail:(NSString *)userEmail{
    [[NSUserDefaults standardUserDefaults] setValue:userEmail forKey:UserEmail];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSString *)userMessage{
    NSString *userMessage = [[NSUserDefaults standardUserDefaults] stringForKey:UserMessage];
    return userMessage == nil ? abEmptyString : userMessage;
}

+(void)setUserMessage:(NSString *)userMessage{
    [[NSUserDefaults standardUserDefaults] setValue:userMessage forKey:UserMessage];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Default Setting
#define BuildLocation @"BuildLocation"

+(NSURL *)buildLocation{
    NSURL *buildLocation = [[NSUserDefaults standardUserDefaults] URLForKey:BuildLocation];
    if (buildLocation == nil){
        buildLocation = [NSURL URLWithString:[abBuildLocation stringByExpandingTildeInPath]];
    }
    return buildLocation;
}

+(void)setBuildLocation:(NSURL *)buildLocation{
    [[NSUserDefaults standardUserDefaults] setURL:buildLocation forKey:BuildLocation];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Dropbox
#define DropboxUsedSpace @"DropboxUsedSpace"
#define DropboxAvailableSpace @"DropboxAvailableSpace"

+(NSNumber *)dropboxUsedSpace{
    return @([[NSUserDefaults standardUserDefaults] doubleForKey:DropboxUsedSpace]);
}

+(void)setDropboxUsedSpace:(NSNumber *)usedSpace{
    [[NSUserDefaults standardUserDefaults] setInteger:usedSpace.integerValue forKey:DropboxUsedSpace];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSNumber *)dropboxAvailableSpace{
    return @([[NSUserDefaults standardUserDefaults] doubleForKey:DropboxAvailableSpace]);
}

+(void)setDropboxAvailableSpace:(NSNumber *)availableSpace{
    [[NSUserDefaults standardUserDefaults] setInteger:availableSpace.integerValue forKey:DropboxAvailableSpace];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


@end
