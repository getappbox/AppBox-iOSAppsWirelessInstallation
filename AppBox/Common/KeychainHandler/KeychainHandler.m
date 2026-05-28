//
//  KeychainHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "KeychainHandler.h"
#import <Security/Security.h>

// Raw SecItem attribute keys, identical to the values SAMKeychain exposed.
NSString *const kSAMKeychainAccountKey = @"acct";
NSString *const kSAMKeychainLabelKey = @"labl";

static NSString *const CERTIFICATE_KEY = @"CerKey";
static NSString *const CERTIFICATE_KEY_READABLE = @"CerKeyReadable";

@implementation KeychainHandler

//MARK: - Accounts

+ (NSArray<NSDictionary *> *)accountsForService:(NSString *)service {
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    if (service) {
        query[(__bridge id)kSecAttrService] = service;
    }
    query[(__bridge id)kSecReturnAttributes] = (__bridge id)kCFBooleanTrue;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitAll;

    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status != errSecSuccess) {
        if (result) {
            CFRelease(result);
        }
        return @[];
    }

    NSArray *accounts = (__bridge_transfer NSArray *)result;
    return accounts ?: @[];
}

//MARK: - ITC Accounts
+ (NSArray *)getAllITCAccounts {
    NSMutableArray *filteredITCAccounts = [[NSMutableArray alloc] init];
//    NSArray *itcAccounts = [SAMKeychain accountsForService:abiTunesConnectService];
//    for (NSDictionary *account in itcAccounts) {
//        if ([account.allKeys containsObject:kSAMKeychainAccountKey]) {
//            [filteredITCAccounts addObject:account];
//        }
//    }
    return filteredITCAccounts;
}

//MARK: - Keychain

+(NSString *)errorMessageForStatus:(OSStatus)status {
    CFStringRef errorMessage = SecCopyErrorMessageString(status, NULL);
    NSString *errorString = (__bridge_transfer NSString *)errorMessage;
    return errorString;
}


//MARK: - Remove All Cache, Cookies and Credentials
+ (void)removeAllStoredCredentials{
    // Delete any cached URLrequests!
    NSURLCache *sharedCache = [NSURLCache sharedURLCache];
    [sharedCache removeAllCachedResponses];
    
    // Also delete all stored cookies!
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = [cookieStorage cookies];
    for (NSHTTPCookie *cookie in cookies) {
        [cookieStorage deleteCookie:cookie];
    }
    
    // Remove app-specific keychain items
    NSDictionary *keychainQuery = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword
    };
    OSStatus keychainStatus = SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
    if (keychainStatus != errSecSuccess && keychainStatus != errSecItemNotFound) {
        DDLogWarn(@"Failed to clear keychain items: %@", [self errorMessageForStatus:keychainStatus]);
    }

    NSDictionary *credentialsDict = [[NSURLCredentialStorage sharedCredentialStorage] allCredentials];
    if ([credentialsDict count] > 0) {
        // the credentialsDict has NSURLProtectionSpace objs as keys and dicts of userName => NSURLCredential
        NSEnumerator *protectionSpaceEnumerator = [credentialsDict keyEnumerator];
        id urlProtectionSpace;
        // iterate over all NSURLProtectionSpaces
        while (urlProtectionSpace = [protectionSpaceEnumerator nextObject]) {
            NSEnumerator *userNameEnumerator = [[credentialsDict objectForKey:urlProtectionSpace] keyEnumerator];
            id userName;
            // iterate over all usernames for this protectionspace, which are the keys for the actual NSURLCredentials
            while (userName = [userNameEnumerator nextObject]) {
                NSURLCredential *cred = [[credentialsDict objectForKey:urlProtectionSpace] objectForKey:userName];
                [[NSURLCredentialStorage sharedCredentialStorage] removeCredential:cred forProtectionSpace:urlProtectionSpace];
            }
        }
    }
}


@end
