//
//  UserData.h
//  AppBox
//
//  Created by Vineet Choudhary on 12/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserData : NSObject

+(BOOL)isGmailLoggedIn;
+(void)setIsGmailLoggedIn:(BOOL)isGmailLoggedIn;

+(NSString *)userEmail;
+(void)setUserEmail:(NSString *)userEmail;

+(NSString *)userMessage;
+(void)setUserMessage:(NSString *)userMessage;

@end
