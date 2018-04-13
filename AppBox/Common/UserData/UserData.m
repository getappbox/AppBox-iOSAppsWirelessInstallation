//
//  UserData.m
//  AppBox
//
//  Created by Vineet Choudhary on 12/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "UserData.h"


@implementation UserData

#pragma mark - Email Releated -

#define UserEmail @"UserEmail"

+(NSString *)userEmail{
    NSString *userEmail = [[NSUserDefaults standardUserDefaults] stringForKey:UserEmail];
    return userEmail == nil ? abEmptyString : userEmail;
}

+(void)setUserEmail:(NSString *)userEmail{
    [[NSUserDefaults standardUserDefaults] setValue:userEmail forKey:UserEmail];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#define UserMessage @"UserMessage"

+(NSString *)userMessage{
    NSString *userMessage = [[NSUserDefaults standardUserDefaults] stringForKey:UserMessage];
    return userMessage == nil ? abEmptyString : userMessage;
}

+(void)setUserMessage:(NSString *)userMessage{
    [[NSUserDefaults standardUserDefaults] setValue:userMessage forKey:UserMessage];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#define UserSlackChannel @"UserSlackChannel"

+(NSString *)userSlackChannel {
    NSString *userSlackChannel = [[NSUserDefaults standardUserDefaults] stringForKey:UserSlackChannel];
    return userSlackChannel == nil ? abEmptyString : userSlackChannel;
}

+(void)setUserSlackChannel:(NSString *)slackChannel {
    [[NSUserDefaults standardUserDefaults] setValue:slackChannel forKey:UserSlackChannel];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#define UserHangoutChatWebHook @"UserHangoutChatWebHook"

+(NSString *)userHangoutChatWebHook {
    NSString *userHangoutChatWebHook = [[NSUserDefaults standardUserDefaults] stringForKey:UserHangoutChatWebHook];
    return userHangoutChatWebHook == nil ? abEmptyString : userHangoutChatWebHook;
}

+(void)setUserHangoutChatWebHook:(NSString *)slackChannel {
    [[NSUserDefaults standardUserDefaults] setValue:slackChannel forKey:UserHangoutChatWebHook];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#define UserMicrosoftTeamWebHook @"UserMicrosoftTeamWebHook"

+(NSString *)userMicrosoftTeamWebHook {
    NSString *userMicrosoftTeamWebHook = [[NSUserDefaults standardUserDefaults] stringForKey:UserMicrosoftTeamWebHook];
    return userMicrosoftTeamWebHook == nil ? abEmptyString : userMicrosoftTeamWebHook;
}

+(void)setUserMicrosoftTeamWebHook:(NSString *)slackChannel {
    [[NSUserDefaults standardUserDefaults] setValue:slackChannel forKey:UserMicrosoftTeamWebHook];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#define UserSlackMessage @"UserSlackMessage"

+(NSString *)userSlackMessage {
    NSString *userSlackMessage = [[NSUserDefaults standardUserDefaults] stringForKey:UserSlackMessage];
    return userSlackMessage == nil ? abEmptyString : userSlackMessage;
}

+(void)setUserSlackMessage:(NSString *)slackMessage {
    [[NSUserDefaults standardUserDefaults] setValue:slackMessage forKey:UserSlackMessage];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Default Setting -

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

#define XCodeLocation @"XCodeLocation"

+(NSURL *)xCodeLocation{
    NSString *xCodeLocation = [[NSUserDefaults standardUserDefaults] stringForKey:XCodeLocation];
    if (xCodeLocation == nil){
        xCodeLocation = abXcodeLocation;
        
    }
    return [NSURL URLWithString: xCodeLocation];
}

+(void)setXCodeLocation:(NSString *)xCodeLocation{
    [[NSUserDefaults standardUserDefaults] setValue:xCodeLocation forKey:XCodeLocation];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#define ApplicationLoaderLocation @"ApplicationLoaderLocation"

+(NSURL *)applicationLoaderLocation{
    NSString *alLocation = [[NSUserDefaults standardUserDefaults] stringForKey:ApplicationLoaderLocation];
    if (alLocation == nil) {
        alLocation = abApplicationLoaderAppLocation;
    }
    return [NSURL URLWithString: alLocation];
}

+(void)setApplicationLoaderLocation:(NSString *)alLocation{
    [[NSUserDefaults standardUserDefaults] setValue:alLocation forKey:ApplicationLoaderLocation];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Dropbox -

#define DropboxUsedSpace @"DropboxUsedSpace"

+(NSNumber *)dropboxUsedSpace{
    return @([[NSUserDefaults standardUserDefaults] doubleForKey:DropboxUsedSpace]);
}

+(void)setDropboxUsedSpace:(NSNumber *)usedSpace{
    [[NSUserDefaults standardUserDefaults] setInteger:usedSpace.integerValue forKey:DropboxUsedSpace];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#define DropboxAvailableSpace @"DropboxAvailableSpace"

+(NSNumber *)dropboxAvailableSpace{
    return @([[NSUserDefaults standardUserDefaults] doubleForKey:DropboxAvailableSpace]);
}

+(void)setDropboxAvailableSpace:(NSNumber *)availableSpace{
    [[NSUserDefaults standardUserDefaults] setInteger:availableSpace.integerValue forKey:DropboxAvailableSpace];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - ExportOption Plist Values -

#define UploadSymbols @"uploadSymbols"
+(BOOL)uploadSymbols{
    return [[NSUserDefaults standardUserDefaults] boolForKey:UploadSymbols];
}

+(void)setUploadSymbols:(BOOL)uploadSymbol{
    [[NSUserDefaults standardUserDefaults] setBool:uploadSymbol forKey:UploadSymbols];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#define UploadBitcode @"uploadBitcode"
+(BOOL)uploadBitcode{
    return [[NSUserDefaults standardUserDefaults] boolForKey:UploadBitcode];
}

+(void)setUploadBitcode:(BOOL)uploadBitcode{
    [[NSUserDefaults standardUserDefaults] setBool:uploadBitcode forKey:UploadBitcode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#define CompileBitcode @"compileBitcode"
+(BOOL)compileBitcode{
    return [[NSUserDefaults standardUserDefaults] boolForKey:CompileBitcode];
}

+(void)setCompileBitcode:(BOOL)compileBitcode{
    [[NSUserDefaults standardUserDefaults] setBool:compileBitcode forKey:CompileBitcode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - AppBox Installation Page Settings -
#define DonwloadIPAEnable @"DonwloadIPAEnable"
+(BOOL)downloadIPAEnable{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DonwloadIPAEnable];
}

+(void)setDownloadIPAEnable:(BOOL)downloadIPA{
    [[NSUserDefaults standardUserDefaults] setBool:downloadIPA forKey:DonwloadIPAEnable];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#define MoreDetailsEnable @"MoreDetailsEnable"
+(BOOL)moreDetailsEnable{
    return [[NSUserDefaults standardUserDefaults] boolForKey:MoreDetailsEnable];
}

+(void)setMoreDetailsEnable:(BOOL)moreDetails{
    [[NSUserDefaults standardUserDefaults] setBool:moreDetails forKey:MoreDetailsEnable];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - App Settings -
#define AppSettingIsFirstTime @"AppSettingIsFirstTime"
+(BOOL)isFirstTime{
    return ![[NSUserDefaults standardUserDefaults] boolForKey:AppSettingIsFirstTime];
}

+(void)setIsFirstTime:(BOOL)isFirstTime{
    [[NSUserDefaults standardUserDefaults] setBool:isFirstTime forKey:AppSettingIsFirstTime];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSString *)appSettingIsFirstTimeAfterUpdate{
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
    return [NSString stringWithFormat:@"AppSettingIsFirstTimeAfterUpdate%@", versionString];
}

+(BOOL)isFirstTimeAfterUpdate{
    return ![[NSUserDefaults standardUserDefaults] boolForKey:[self appSettingIsFirstTimeAfterUpdate]];
}

+(void)setIsFirstTimeAfterUpdate:(BOOL)isFirstTime{
    [[NSUserDefaults standardUserDefaults] setBool:isFirstTime forKey:[self appSettingIsFirstTimeAfterUpdate]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Chunk Size -
#define UploadChunkSize @"UploadChunkSize"
+(NSInteger)uploadChunkSize{
    NSInteger chunkSize = [[NSUserDefaults standardUserDefaults] integerForKey:UploadChunkSize];
    return chunkSize > 0 ? chunkSize : 100;
}

+(void)setUploadChunkSize:(NSInteger)chunkSize{
    [[NSUserDefaults standardUserDefaults] setInteger:chunkSize forKey:UploadChunkSize];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - CI Settings -
#define DebugLogEnable @"DebugLogEnable"
+(BOOL)debugLog{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DebugLogEnable];
}

+(void)setEnableDebugLog:(BOOL)debugLog{
    [[NSUserDefaults standardUserDefaults] setBool:debugLog forKey:DebugLogEnable];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#define UpdateAlertEnable @"UpdateAlertEnable"
+(BOOL)updateAlertEnable{
    return [[NSUserDefaults standardUserDefaults] boolForKey:UpdateAlertEnable];
}

+(void)setUpdateAlertEnable:(BOOL)updateAlert{
    [[NSUserDefaults standardUserDefaults] setBool:updateAlert forKey:UpdateAlertEnable];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
