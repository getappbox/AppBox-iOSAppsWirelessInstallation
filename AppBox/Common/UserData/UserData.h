//
//  UserData.h
//  AppBox
//
//  Created by Vineet Choudhary on 12/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserData : NSObject

+(NSString *)userEmail;
+(void)setUserEmail:(NSString *)userEmail;
+(NSString *)userMessage;
+(void)setUserMessage:(NSString *)userMessage;

+(NSString *)userSlackChannel;
+(void)setUserSlackChannel:(NSString *)slackChannel;
+(NSString *)userSlackMessage;
+(void)setUserSlackMessage:(NSString *)slackMessage;
+(NSString *)userHangoutChatWebHook;
+(void)setUserHangoutChatWebHook:(NSString *)slackChannel;
+(NSString *)userMicrosoftTeamWebHook;
+(void)setUserMicrosoftTeamWebHook:(NSString *)slackChannel;

+(NSURL *)buildLocation;
+(void)setBuildLocation:(NSURL *)buildLocation;

+(NSURL *)xCodeLocation;
+(void)setXCodeLocation:(NSString *)xCodeLocation;

+(NSURL *)applicationLoaderLocation;
+(void)setApplicationLoaderLocation:(NSString *)alLocation;

+(NSNumber *)dropboxUsedSpace;
+(NSNumber *)dropboxAvailableSpace;
+(void)setDropboxUsedSpace:(NSNumber *)usedSpace;
+(void)setDropboxAvailableSpace:(NSNumber *)availableSpace;

+(BOOL)uploadSymbols;
+(void)setUploadSymbols:(BOOL)uploadSymbol;
+(BOOL)uploadBitcode;
+(void)setUploadBitcode:(BOOL)uploadBitcode;
+(BOOL)compileBitcode;
+(void)setCompileBitcode:(BOOL)compileBitcode;
+(BOOL)downloadIPAEnable;
+(void)setDownloadIPAEnable:(BOOL)downloadIPA;
+(BOOL)moreDetailsEnable;
+(void)setMoreDetailsEnable:(BOOL)moreDetails;
+(BOOL)showPreviousVersions;
+(void)setShowPreviousVersions:(BOOL)previousVersion;

+(BOOL)isFirstTime;
+(void)setIsFirstTime:(BOOL)isFirstTime;
+(BOOL)isFirstTimeAfterUpdate;
+(void)setIsFirstTimeAfterUpdate:(BOOL)isFirstTime;

+(NSInteger)uploadChunkSize;
+(void)setUploadChunkSize:(NSInteger)chunkSize;

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

@end
