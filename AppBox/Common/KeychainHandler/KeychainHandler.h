//
//  KeychainHandler.h
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Keychain attribute dictionary keys, matching the raw `SecItem` attribute
/// keys previously vended by SAMKeychain (kept for source compatibility).
extern NSString *const kSAMKeychainAccountKey;
extern NSString *const kSAMKeychainLabelKey;

@interface KeychainHandler : NSObject

/// Returns the attribute dictionaries for every generic-password keychain item
/// stored under `service`. Replaces `+[SAMKeychain accountsForService:]`.
+ (NSArray<NSDictionary *> *)accountsForService:(NSString *)service;
+ (NSArray *)getAllITCAccounts;
+ (void)removeAllStoredCredentials;
+ (NSString *)errorMessageForStatus:(OSStatus)status;
@end
