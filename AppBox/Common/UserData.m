//
//  UserData.m
//  AppBox
//
//  Created by Vineet Choudhary on 12/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "UserData.h"

#define GmailLoggedIn @"GmailLoggedIn"
#define UserEmail @"UserEmail"
#define UserMessage @"UserMessage"

@implementation UserData

//Gmail Logged In
+(BOOL)isGmailLoggedIn{
    return [[NSUserDefaults standardUserDefaults] boolForKey:GmailLoggedIn];
}

+(void)setIsGmailLoggedIn:(BOOL)isGmailLoggedIn{
    [[NSUserDefaults standardUserDefaults] setBool:isGmailLoggedIn forKey:GmailLoggedIn];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

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


@end
