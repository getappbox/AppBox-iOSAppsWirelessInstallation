//
//  KeychainHandler.h
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeychainHandler : NSObject

+ (NSArray *)getAllTeamId;
+ (void)removeAllStoredCredentials;
+ (void)installPrivateKeyFromPath:(NSString *)path withPassword:(NSString *)password;

+(void)lockAllKeychain;
+(NSString *)errorMessageForStatus:(OSStatus)status;
+(OSStatus)unlockKeyChain:(NSString *)path withPassword:(NSString *)password;

@end
