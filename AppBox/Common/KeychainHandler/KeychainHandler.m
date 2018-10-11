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

    [certficates enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableDictionary *certProperties = [self getPlainCertificate:obj];
        
        //Get cert values
        NSString *teamId = [certProperties objectForKey:abTeamId];
        NSString *teamName = [certProperties objectForKey:abTeamName];
        NSString *fullName = [certProperties objectForKey:abFullName];
        
        //filter developer, distribution cert and valid team id
        if (![teamId containsString:@" "] && teamId.length == abTeamIdLength &&
            ([fullName.lowercaseString containsString:abiPhoneDistribution] || [fullName.lowercaseString containsString:abiPhoneDeveloper])){
            
            //better name
            fullName = [NSString stringWithFormat:@"%@ (%@)",teamName, teamId];
            [certProperties setValue:fullName forKey:abFullName];
            
            
            //Check existing team id
            NSPredicate *existingTeam = [NSPredicate predicateWithFormat:@"SELF.teamId = %@ AND SELF.teamName = %@ AND SELF.fullName = %@",teamId, teamName, fullName];
            [ABLog log:@"filter - %@",[plainCertifcates filteredArrayUsingPredicate:existingTeam]];
            
            //Filter invalid cert
            if ([plainCertifcates filteredArrayUsingPredicate:existingTeam].count == 0){
                
                //add certificates
                [plainCertifcates addObject:certProperties];
            }
        }
    }];
    
    [plainCertifcates sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return ([[obj1 valueForKey:abFullName] isLessThan: [obj2 valueForKey:abFullName]]) ? NSOrderedAscending : NSOrderedDescending;
    }];
    return plainCertifcates;
}

+ (NSArray *)allKeychainCertificatesWithError:(NSError *__autoreleasing *)error{
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
    [sectionKeys setObject:abFullName forKeyedSubscript:((__bridge id)kSecOIDCommonName)];
    return [self getCertificateDetails:certificate withSectionIdKey:(__bridge id)kSecOIDX509V1SubjectName withSectionKeys:sectionKeys];
}

+(NSMutableDictionary *)getCertificateDetails:(id)certificate withSectionIdKey:(id)section withSectionKeys:(NSDictionary *)sectionKeys{
    NSMutableDictionary *plainCertificate = [NSMutableDictionary new];
    id sectionValue = [self valueWithCertificate:certificate key:section];
    if([sectionValue isKindOfClass:[NSArray class]]){
        for (id subjectDetail in sectionValue) {
            for (id key in [sectionKeys allKeys]) {
                id label = subjectDetail[(__bridge id)kSecPropertyKeyLabel];
                id value = subjectDetail[(__bridge id)kSecPropertyKeyValue];
                if([label isEqualToString:key]){
                    [plainCertificate setObject:value forKey:[sectionKeys valueForKey:key]];
                }
            }
        }
    }
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

#pragma mark - Install Certificates
+ (void)installPrivateKeyFromPath:(NSString *)path withPassword:(NSString *)password {
    NSMutableArray *arguments = [[NSMutableArray alloc] initWithObjects:path, nil];
    if (password != nil && password.length > 0){
        [arguments addObject: password];
    }
    [TaskHandler runTaskWithName:@"InstallPrivateKey" andArgument:arguments taskLaunch:^(NSTask *task) {
        
    } outputStream:^(NSTask *task, NSString *output) {
        NSLog(@"%@", output);
    }];
}

#pragma mark - Keychain

+(void)lockAllKeychain {
    SecKeychainLockAll();
}

+(NSString *)unlockKeyChain:(NSString *)path withPassword:(NSString *)password {
    char const *charPassword = [password cStringUsingEncoding:NSUTF8StringEncoding];
    SecKeychainRef keychainRef = NULL;
    OSStatus status = 0;
    if (path == nil || path.length == 0)
    {
        status = SecKeychainCopyDefault(&keychainRef);
    }
    else if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        char const *charKeychainPath = [path cStringUsingEncoding:NSUTF8StringEncoding];
        status = SecKeychainOpen(charKeychainPath, &keychainRef);
    }
    else
    {
        return @"Keychain file not found.";
    }
    
    status = SecKeychainLock(keychainRef);
    status = SecKeychainUnlock(keychainRef, (UInt32)strlen(charPassword), charPassword, YES);
    
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
