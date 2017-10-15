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

+(BOOL)isFirstTime;
+(void)setIsFirstTime:(BOOL)isFirstTime;

@end
