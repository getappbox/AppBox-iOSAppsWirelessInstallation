//
//  KeychainHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "KeychainHandler.h"

@implementation KeychainHandler

#pragma mark - Get Team Id
+ (NSArray *)getAllTeamId{
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  (__bridge id)kCFBooleanTrue, (__bridge id)kSecReturnAttributes,
                                  (__bridge id)kSecMatchLimitAll, (__bridge id)kSecMatchLimit,
                                  nil];
    
    [query setObject:(__bridge id)kSecClassCertificate forKey:(__bridge id)kSecClass];
    CFTypeRef result = NULL;
    SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    NSArray *certficates = CFBridgingRelease(result);
    NSMutableArray *plainCertifcates = [[NSMutableArray alloc] init];
    NSMutableArray *tempTeamIds = [[NSMutableArray alloc] init];
    [certficates enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableDictionary *certProperties = [[NSMutableDictionary alloc] init];
        NSString *certLabel = [obj valueForKey:(NSString *)kSecAttrLabel];
        NSArray *certComponent = [certLabel componentsSeparatedByString:@": "];
        if (certComponent.count == 2 &&
            ([[[certComponent firstObject] lowercaseString] isEqualToString:abiPhoneDistribution] ||
             [[[certComponent firstObject] lowercaseString] isEqualToString:abiPhoneDeveloper])){
                NSArray *certDetailsComponent = [[certComponent lastObject] componentsSeparatedByString:@" ("];
                if (certDetailsComponent.count == 2){
                    NSString *teamId = [[certDetailsComponent lastObject] stringByReplacingOccurrencesOfString:@")" withString:abEmptyString];
                    [certProperties setValue:certLabel forKey:abFullName];
                    [certProperties setValue:[certComponent lastObject] forKey:abTeamName];
                    [certProperties setObject:teamId forKey:abTeamId];
                    if ([teamId containsString:@" "]){
                        
                    }
                    if (![tempTeamIds containsObject:teamId] && ![teamId containsString:@" "]){
                        [tempTeamIds addObject:teamId];
                        [plainCertifcates addObject:certProperties];
                    }
                }
            }
    }];
    [plainCertifcates sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 valueForKey:abTeamId] > [obj2 valueForKey:abTeamId];
    }];
    return plainCertifcates;
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
