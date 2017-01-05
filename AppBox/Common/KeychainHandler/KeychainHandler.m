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
#pragma mark - Get Team Id
+ (NSArray *)getAllTeamId{
    NSError *error = nil;
    NSArray *certficates = [self allKeychainCertificatesWithError:&error];
    NSMutableArray *plainCertifcates = [[NSMutableArray alloc] init];
    NSMutableArray *tempTeamIds = [[NSMutableArray alloc] init];
    ////////
    [certficates enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableDictionary *certProperties = [self getPlainCertificate:obj];
        if([certProperties objectForKey:abTeamId])
        [plainCertifcates addObject:certProperties];
    }];
    NSMutableDictionary *dict = [plainCertifcates mutableCopy];
    NSLog(@"Plan certificates %@",dict);
    ////////////////////
    plainCertifcates = [NSMutableArray new];
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
+ (NSArray *)allKeychainCertificatesWithError:(NSError *__autoreleasing *)error
{
    NSDictionary *options = @{(__bridge id)kSecClass: (__bridge id)kSecClassCertificate,
                              (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitAll};
    CFArrayRef certs = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)options, (CFTypeRef *)&certs);
    NSArray *certificates = CFBridgingRelease(certs);
    if (status != errSecSuccess || !certs) {
        return nil;
    }
    return certificates;
}
+ (NSMutableDictionary *)getPlainCertificate:(id)certificate{
    NSMutableDictionary *plainCertificate = [NSMutableDictionary new];
    [plainCertificate addEntriesFromDictionary:[self getSubjectNameDetailsFromCertificate:certificate]];
    [plainCertificate addEntriesFromDictionary:[self getIssuerDetailsFromCertificate:certificate]];
    return plainCertificate;
}
+(NSMutableDictionary *)getIssuerDetailsFromCertificate:(id)certificate{
    NSMutableDictionary *sectionKeys = [NSMutableDictionary new];
    [sectionKeys setObject:abExpiryDate forKey:((__bridge id)kSecOIDX509V1ValidityNotAfter)];
//    [sectionKeys setObject:abTeamId forKey:((__bridge id)kSecOIDOrganizationalUnitName)];
    return [self getCertificateDetails:certificate withSectionIdKey:(__bridge id)kSecOIDX509V1IssuerName withSectionKeys:sectionKeys];
}
+(NSMutableDictionary *)getSubjectNameDetailsFromCertificate:(id)certificate{
    NSMutableDictionary *sectionKeys = [NSMutableDictionary new];
    [sectionKeys setObject:abTeamName forKey:((__bridge id)kSecOIDOrganizationName)];
    [sectionKeys setObject:abTeamId forKey:((__bridge id)kSecOIDOrganizationalUnitName)];
    return [self getCertificateDetails:certificate withSectionIdKey:(__bridge id)kSecOIDX509V1SubjectName withSectionKeys:sectionKeys];
}
+(NSMutableDictionary *)getCertificateDetails:(id)certificate withSectionIdKey:(id)section withSectionKeys:(NSDictionary *)sectionKeys{
    NSMutableDictionary *plainCertificate = [NSMutableDictionary new];
    id sectionValue = [self valueWithCertificate:certificate key:section];
    if([sectionValue isKindOfClass:[NSArray class]]){
        for (id subjectDetail in sectionValue) {
            for (id key in [sectionKeys allKeys]) {
                id label = subjectDetail[(__bridge id)kSecPropertyKeyLabel];
                NSLog(@"Key %@ Cerificate label %@",key,label);
                if([label isEqualToString:key])
                {
                    id value = subjectDetail[(__bridge id)kSecPropertyKeyValue];
                    [plainCertificate setObject:value forKey:[sectionKeys valueForKey:key]];
                }
            }
        }
    }
    NSLog(@"Section values %@",sectionValue);
    return plainCertificate;
}
+(NSArray *)keysNeedToExtract{
    return @[
             @{@"OrganizationUnitName":(__bridge id)kSecOIDOrganizationalUnitName,
               @"OrganizationName":(__bridge id)kSecOIDOrganizationName
                 },
             ];
}
+ (id)valueWithCertificate:(id)certificate key:(id)key{
    return [self valuesWithCertificate:certificate keys:@[key] error:nil][key][(__bridge id)kSecPropertyKeyValue];
}

+ (NSDictionary *)valuesWithCertificate:(id)certificate keys:(NSArray *)keys error:(NSError **)error{
    CFErrorRef e = NULL;
    NSDictionary *result = CFBridgingRelease(SecCertificateCopyValues((__bridge SecCertificateRef)certificate, (__bridge CFArrayRef)keys, &e));
    if (error) *error = CFBridgingRelease(e);
    return result;
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
