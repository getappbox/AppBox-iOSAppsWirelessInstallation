//
//  KeychainHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "KeychainHandler.h"
static NSString *const CERTIFICATE_KEY = @"CerKey";
static NSString *const CERTIFICATE_KEY_READABLE = @"CerKeyReadable";

@implementation KeychainHandler

#pragma mark - ITC Accounts
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

#pragma mark - Keychain

+(NSString *)errorMessageForStatus:(OSStatus)status {
    CFStringRef errorMessage = SecCopyErrorMessageString(status, NULL);
    NSString *errorString = (__bridge NSString *)errorMessage;
    return errorString;
}


#pragma mark - Remove All Cache, Cookies and Credentials
+ (void)removeAllStoredCredentials{
    // Delete any cached URLrequests!
    NSURLCache *sharedCache = [NSURLCache sharedURLCache];
    [sharedCache removeAllCachedResponses];
    
    // Also delete all stored cookies!
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = [cookieStorage cookies];
    id cookie;
    for (cookie in cookies) {
        [cookieStorage deleteCookie:cookie];
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
                //NSLog(@"credentials to be removed: %@", cred);
                [[NSURLCredentialStorage sharedCredentialStorage] removeCredential:cred forProtectionSpace:urlProtectionSpace];
            }
        }
    }
}


@end
