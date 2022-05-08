//
//  UserData.m
//  AppBox
//
//  Created by Vineet Choudhary on 12/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "UserData.h"


@implementation UserData

//MARK: - Logged In User
+(BOOL)isLoggedIn {
	return [DBClientsManager authorizedClients] && ([DBClientsManager authorizedClients].count > 0);
}

#define LoggedInUserEmail @"LoggedInUserEmail"
+(NSString *)loggedInUserEmail {
	NSString *userEmail = [[NSUserDefaults standardUserDefaults] stringForKey:LoggedInUserEmail];
	return userEmail == nil ? abEmptyString : userEmail;
}

+(void)setLoggedInUserEmail:(NSString *)loggedInUserEmail {
	[[NSUserDefaults standardUserDefaults] setValue:loggedInUserEmail forKey:LoggedInUserEmail];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

#define LoggedInUserDisplayName @"LoggedInUserDisplayName"
+(NSString *)loggedInUserDisplayName {
	NSString *displayName = [[NSUserDefaults standardUserDefaults] stringForKey:LoggedInUserDisplayName];
	return displayName == nil ? abEmptyString : displayName;
}

+(void)setLoggedInUserDisplayName:(NSString *)loggedInUserDisplayName {
	[[NSUserDefaults standardUserDefaults] setValue:loggedInUserDisplayName forKey:LoggedInUserDisplayName];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

//MARK: - Dropbox -

#define DropboxUsedSpace @"DropboxUsedSpace"

+(NSNumber *)dropboxUsedSpace{
	return @([[NSUserDefaults standardUserDefaults] doubleForKey:DropboxUsedSpace]);
}

+(void)setDropboxUsedSpace:(NSNumber *)usedSpace{
	[[NSUserDefaults standardUserDefaults] setInteger:usedSpace.integerValue forKey:DropboxUsedSpace];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

//MARK: - Preferences...
//MARK: - Email Releated -

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

#define DropboxAvailableSpace @"DropboxAvailableSpace"

+(NSNumber *)dropboxAvailableSpace{
    return @([[NSUserDefaults standardUserDefaults] doubleForKey:DropboxAvailableSpace]);
}

+(void)setDropboxAvailableSpace:(NSNumber *)availableSpace{
    [[NSUserDefaults standardUserDefaults] setInteger:availableSpace.integerValue forKey:DropboxAvailableSpace];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

//MARK: - AppBox Installation Page Settings -
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

#define ShowPreviousVersions @"ShowPreviousVersions"
+(BOOL)showPreviousVersions{
    return [[NSUserDefaults standardUserDefaults] boolForKey:ShowPreviousVersions];
}

+(void)setShowPreviousVersions:(BOOL)previousVersion{
    [[NSUserDefaults standardUserDefaults] setBool:previousVersion forKey:ShowPreviousVersions];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


//MARK: - App Settings -
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

//MARK: - Chunk Size -
#define UploadChunkSize @"UploadChunkSize"
+(NSInteger)uploadChunkSize{
    NSInteger chunkSize = [[NSUserDefaults standardUserDefaults] integerForKey:UploadChunkSize];
    return chunkSize > 0 ? chunkSize : 100;
}

+(void)setUploadChunkSize:(NSInteger)chunkSize{
    [[NSUserDefaults standardUserDefaults] setInteger:chunkSize forKey:UploadChunkSize];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

//MARK: - CI Settings -
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
