//
//  UserData.h
//  AppBox
//
//  Created by Vineet Choudhary on 12/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserData : NSObject

// Default emails and message
+(NSString *)userEmail;
+(void)setUserEmail:(NSString *)userEmail;
+(NSString *)userMessage;
+(void)setUserMessage:(NSString *)userMessage;

// Slack, Hangout Chat and Microsoft Team Webhooks
+(NSString *)userSlackChannel;
+(void)setUserSlackChannel:(NSString *)slackChannel;
+(NSString *)userSlackMessage;
+(void)setUserSlackMessage:(NSString *)slackMessage;
+(NSString *)userHangoutChatWebHook;
+(void)setUserHangoutChatWebHook:(NSString *)slackChannel;
+(NSString *)userMicrosoftTeamWebHook;
+(void)setUserMicrosoftTeamWebHook:(NSString *)slackChannel;

// Default build location
+(NSURL *)buildLocation;
+(void)setBuildLocation:(NSURL *)buildLocation;

// Default Xcode location
+(NSURL *)xCodeLocation;
+(void)setXCodeLocation:(NSString *)xCodeLocation;

// Default Application Loader Location
+(NSURL *)applicationLoaderLocation;
+(void)setApplicationLoaderLocation:(NSString *)alLocation;

// Dropbox Used and Available Space
+(NSNumber *)dropboxUsedSpace;
+(NSNumber *)dropboxAvailableSpace;
+(void)setDropboxUsedSpace:(NSNumber *)usedSpace;
+(void)setDropboxAvailableSpace:(NSNumber *)availableSpace;

//xcodebuild and app store upload settings
+(BOOL)uploadSymbols;
+(void)setUploadSymbols:(BOOL)uploadSymbol;
+(BOOL)uploadBitcode;
+(void)setUploadBitcode:(BOOL)uploadBitcode;
+(BOOL)compileBitcode;
+(void)setCompileBitcode:(BOOL)compileBitcode;
    
//AppBox Installation page settings
+(BOOL)downloadIPAEnable;
+(void)setDownloadIPAEnable:(BOOL)downloadIPA;
+(BOOL)moreDetailsEnable;
+(void)setMoreDetailsEnable:(BOOL)moreDetails;
+(BOOL)showPreviousVersions;
+(void)setShowPreviousVersions:(BOOL)previousVersion;

//AppBox user check
+(BOOL)isFirstTime;
+(void)setIsFirstTime:(BOOL)isFirstTime;
+(BOOL)isFirstTimeAfterUpdate;
+(void)setIsFirstTimeAfterUpdate:(BOOL)isFirstTime;

//AppBox Dropbox Upload Setting
+(NSInteger)uploadChunkSize;
+(void)setUploadChunkSize:(NSInteger)chunkSize;

//AppBox CI Settings
+(BOOL)debugLog;
+(void)setEnableDebugLog:(BOOL)debugLog;
+(BOOL)updateAlertEnable;
+(void)setUpdateAlertEnable:(BOOL)updateAlert;
+(NSString *)defaultCIEmail;
+(void)setDefaultCIEmail:(NSString *)email;
+(NSString *)ciSubjectPrefix;
+(void)setCISubjectPrefix:(NSString *)prefix;
+(NSString *)keychainPath;
+(void)setKeychainPath:(NSString *)path;
+(NSString *)keychainPassword;
+(void)setKeychainPassword:(NSString *)password;
+(NSString *)xcodeVersionPath;
+(void)setXcodeVersionPath:(NSString *)xcodeVersionPath;

@end
