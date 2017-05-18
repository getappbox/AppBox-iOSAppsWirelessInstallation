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

+(NSURL *)buildLocation;
+(void)setBuildLocation:(NSURL *)buildLocation;

+(NSString *)xCodeLocation;
+(void)setXCodeLocation:(NSString *)xCodeLocation;

+(NSNumber *)dropboxUsedSpace;
+(NSNumber *)dropboxAvailableSpace;
+(void)setDropboxUsedSpace:(NSNumber *)usedSpace;
+(void)setDropboxAvailableSpace:(NSNumber *)availableSpace;

@end
