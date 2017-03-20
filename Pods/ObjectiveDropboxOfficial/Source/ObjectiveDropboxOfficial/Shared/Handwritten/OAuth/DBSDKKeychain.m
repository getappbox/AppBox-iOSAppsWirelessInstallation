///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Security/Security.h>

#import "DBAUTHRoutes.h"
#import "DBAUTHTokenFromOAuth1Error.h"
#import "DBAUTHTokenFromOAuth1Result.h"
#import "DBClientsManager+Protected.h"
#import "DBRequestErrors.h"
#import "DBSDKKeychain.h"
#import "DBTransportDefaultConfig.h"
#import "DBUserClient.h"

static NSString *kAccessibilityMigrationOccurredKey = @"KeychainAccessibilityMigration";
static NSString *kV1TokenMigrationOccurredKeyBase = @"KeychainV1TokenMigration-%@";

static NSString *kV2KeychainServiceKeyBase = @"%@.dropbox.authv2";

static NSString *kV1ConsumerAppKeyKey = @"kMPOAuthCredentialConsumerKey";
static NSString *kV1UserCredentialsKey = @"kDBDropboxUserCredentials";
static NSString *kV1UserIdKey = @"kDBDropboxUserId";
static NSString *kV1UserAccessTokenKey = @"kMPOAuthCredentialAccessToken";
static NSString *kV1UserAccessTokenSecretKey = @"kMPOAuthCredentialAccessTokenSecret";

static NSString *kV1SyncKeychainServiceKeyBase = @"%@.dropbox-sync.auth";
static NSString *kV1SyncAccountCredentialsKey = @"accounts";
static NSString *kV1SyncUserIdKey = @"userId";
static NSString *kV1SyncUserAccessTokenKey = @"token";
static NSString *kV1SyncUserAccessTokenSecretKey = @"tokenSecret";

#if TARGET_OS_IPHONE
static NSString *kV1IOSKeychainServiceKeyBase = @"%@.dropbox.auth";
static NSString *kV1IOSUnknownUserIdKey = @"unknown";
#elif !TARGET_OS_IPHONE
static NSString *kV1OSXKeychainServiceKeyBase = @"%@";
static const char *kV1OSXAccountName = "Dropbox";
#endif

@implementation DBSDKKeychain

+ (void)initialize {
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    [[self class] checkAccessibilityMigration];
  });
}

+ (BOOL)storeValueWithKey:(NSString *)key value:(NSString *)value {
  NSData *encoding = [value dataUsingEncoding:NSUTF8StringEncoding];
  if (encoding) {
    return [self storeDataValueWithKey:key value:encoding];
  } else {
    return NO;
  }
}

+ (NSString *)retrieveTokenWithKey:(NSString *)key {
  NSData *data = [self lookupTokenDataWithKey:key];
  if (data != nil) {
    return [NSString stringWithUTF8String:[data bytes]];
  } else {
    return nil;
  }
}

+ (NSArray<NSString *> *)retrieveAllTokens {
  NSMutableDictionary<id, id> *query = [DBSDKKeychain
      queryWithDict:@{(id)kSecReturnAttributes : (id)kCFBooleanTrue, (id)kSecMatchLimit : (id)kSecMatchLimitAll}];
  CFDataRef dataResult = nil;
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&dataResult);

  NSMutableArray<NSString *> *results = [NSMutableArray new];

  if (status == noErr) {
    NSData *data = (__bridge NSData *)dataResult;
    NSArray<NSDictionary<NSString *, id> *> *dataResultDict = (NSArray<NSDictionary<NSString *, id> *> *)data ?: @[];
    for (NSDictionary<NSString *, id> *dict in dataResultDict) {
      [results addObject:(id)dict[(NSString *)kSecAttrAccount]];
    }
  }
  return results;
}

+ (BOOL)deleteTokenWithKey:(NSString *)key {
  NSMutableDictionary<id, id> *query = [DBSDKKeychain queryWithDict:@{(id)kSecAttrAccount : key}];
  return SecItemDelete((__bridge CFDictionaryRef)query) == noErr;
}

+ (BOOL)clearAllTokens {
  NSMutableDictionary<id, id> *query = [DBSDKKeychain queryWithDict:@{}];
  return SecItemDelete((__bridge CFDictionaryRef)query) == noErr;
}

+ (BOOL)storeDataValueWithKey:(NSString *)key value:(NSData *)value {
  NSMutableDictionary<id, id> *query =
      [DBSDKKeychain queryWithDict:@{(id)kSecAttrAccount : key, (id)kSecValueData : value}];
  SecItemDelete((__bridge CFDictionaryRef)query);
  return SecItemAdd((__bridge CFDictionaryRef)query, nil) == noErr;
}

+ (NSData *)lookupTokenDataWithKey:(NSString *)key {
  NSMutableDictionary<id, id> *query = [DBSDKKeychain queryWithDict:@{
    (id)kSecAttrAccount : key,
    (id)kSecReturnData : (id)kCFBooleanTrue,
    (id)kSecMatchLimit : (id)kSecMatchLimitOne
  }];

  CFDataRef dataResult = nil;
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&dataResult);

  if (status == noErr) {
    return (__bridge NSData *)dataResult;
  }
  return nil;
}

+ (NSMutableDictionary<id, id> *)queryWithDict:(NSDictionary<NSString *, id> *)query {
  NSMutableDictionary<id, id> *queryResult = [query mutableCopy];
  NSString *bundleId = [NSBundle mainBundle].bundleIdentifier ?: @"";

  [queryResult setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
  [queryResult setObject:(id)[NSString stringWithFormat:kV2KeychainServiceKeyBase, bundleId]
                  forKey:(id)kSecAttrService];
  [queryResult setObject:(id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly forKey:(id)kSecAttrAccessible];

  return queryResult;
}

+ (void)checkAccessibilityMigration {
  NSUserDefaults *Defaults = [NSUserDefaults standardUserDefaults];
  BOOL MigrationOccurred = [[Defaults stringForKey:kAccessibilityMigrationOccurredKey] boolValue];

  if (!MigrationOccurred) {
    NSMutableDictionary<id, id> *query = [NSMutableDictionary new];
    NSString *bundleId = [NSBundle mainBundle].bundleIdentifier ?: @"";
    [query setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    [query setObject:(id)[NSString stringWithFormat:kV2KeychainServiceKeyBase, bundleId] forKey:(id)kSecAttrService];

    NSDictionary<id, id> *attributesToUpdate =
        @{(id)kSecAttrAccessible : (id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly};
    SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributesToUpdate);
    [Defaults setObject:@"YES" forKey:kAccessibilityMigrationOccurredKey];
  }
}

+ (void)checkAndPerformV1TokenMigration:(DBTokenMigrationResponseBlock)responseBlock
                                  queue:(NSOperationQueue *)queue
                                 appKey:(NSString *)appKey
                              appSecret:(NSString *)appSecret {
  NSOperationQueue *queueToUse = queue ?: [NSOperationQueue mainQueue];

  NSUserDefaults *Defaults = [NSUserDefaults standardUserDefaults];
  NSString *migrationOccurredLookupKey = [NSString stringWithFormat:kV1TokenMigrationOccurredKeyBase, appKey];
  BOOL MigrationOccurred = [[Defaults stringForKey:migrationOccurredLookupKey] boolValue];

  if (!MigrationOccurred) {
    NSMutableArray<NSArray<NSString *> *> *v1TokensData = [NSMutableArray new];

#if TARGET_OS_IPHONE
    NSArray<NSArray<NSString *> *> *v1TokensDataIOSCore = [[self class] v1TokensDataIOSCore];
    NSArray<NSArray<NSString *> *> *v1TokensDataIOSSync = [[self class] v1TokensDataIOSSync];

    [v1TokensData addObjectsFromArray:v1TokensDataIOSCore];
    [v1TokensData addObjectsFromArray:v1TokensDataIOSSync];

#elif !TARGET_OS_IPHONE
    NSArray<NSArray<NSString *> *> *v1TokensDataOSXCore = [[self class] v1TokensDataOSXCore];
    NSArray<NSArray<NSString *> *> *v1TokensDataOSXSync = [[self class] v1TokensDataOSXSync];

    [v1TokensData addObjectsFromArray:v1TokensDataOSXCore];
    [v1TokensData addObjectsFromArray:v1TokensDataOSXSync];
#endif

    if ([v1TokensData count] != 0) {
      [[NSOperationQueue new] addOperationWithBlock:^{
        [[self class] convertV1TokenToV2:v1TokensData
                                  appKey:appKey
                               appSecret:appSecret
                           responseBlock:responseBlock
                                   queue:queueToUse];
      }];
    }
  } else {
    [queueToUse addOperationWithBlock:^{
      responseBlock(NO, NO, @[]);
    }];
  }
}

#if TARGET_OS_IPHONE
+ (NSArray<NSArray<NSString *> *> *)v1TokensDataIOSCore {
  NSMutableArray<NSArray<NSString *> *> *v1TokensData = [NSMutableArray new];

  NSMutableDictionary<id, id> *query = [NSMutableDictionary new];
  NSString *bundleId = [NSBundle mainBundle].bundleIdentifier ?: @"";
  [query setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
  [query setObject:(id)[NSString stringWithFormat:kV1IOSKeychainServiceKeyBase, bundleId] forKey:(id)kSecAttrService];
  [query setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnAttributes];
  [query setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
  [query setObject:(id)kSecMatchLimitAll forKey:(id)kSecMatchLimit];

  CFDataRef dataResult = nil;
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&dataResult);

  if (status == noErr) {
    NSData *data = (__bridge NSData *)dataResult;
    NSArray<NSDictionary<NSString *, id> *> *dataResultDict = (NSArray<NSDictionary<NSString *, id> *> *)data ?: @[];
    for (NSDictionary<NSString *, id> *dict in dataResultDict) {
      NSData *foundData = dict[(NSString *)kSecValueData];
      if (foundData) {
        NSDictionary *unarchivedFoundData = [NSKeyedUnarchiver unarchiveObjectWithData:foundData];
        NSString *retrievedAppKey = unarchivedFoundData[kV1ConsumerAppKeyKey];
        NSArray<NSDictionary<NSString *, id> *> *credentialsList = unarchivedFoundData[kV1UserCredentialsKey];
        for (NSDictionary<NSString *, id> *credential in credentialsList) {
          NSString *uid = credential[kV1UserIdKey];
          NSString *accessToken = credential[kV1UserAccessTokenKey];
          NSString *accessTokenSecret = credential[kV1UserAccessTokenSecretKey];

          if (uid && accessToken && accessTokenSecret && retrievedAppKey) {
            // really old versions of the v1 SDK stored tokens without a
            // corresponding user id, so should be skipped
            if (![uid isEqualToString:kV1IOSUnknownUserIdKey]) {
              NSArray<NSString *> *tokenData = @[ uid, accessToken, accessTokenSecret, retrievedAppKey ];
              [v1TokensData addObject:tokenData];
            }
          }
        }
      }
    }
  }
  return v1TokensData;
}

+ (NSArray<NSArray<NSString *> *> *)v1TokensDataIOSSync {
  NSMutableArray<NSArray<NSString *> *> *v1TokensData = [NSMutableArray new];

  NSMutableDictionary<id, id> *query = [NSMutableDictionary new];
  NSString *bundleId = [NSBundle mainBundle].bundleIdentifier ?: @"";
  [query setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
  [query setObject:(id)[NSString stringWithFormat:kV1SyncKeychainServiceKeyBase, bundleId] forKey:(id)kSecAttrService];
  [query setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnAttributes];
  [query setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
  [query setObject:(id)kSecMatchLimitAll forKey:(id)kSecMatchLimit];

  CFDataRef dataResult = nil;
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&dataResult);

  if (status == noErr) {
    NSData *data = (__bridge NSData *)dataResult;
    NSArray<NSDictionary<NSString *, id> *> *dataResultDict = (NSArray<NSDictionary<NSString *, id> *> *)data ?: @[];
    for (NSDictionary<NSString *, id> *dict in dataResultDict) {
      NSData *foundData = dict[(NSString *)kSecValueData];
      if (foundData) {
        NSDictionary *credentialsDictionary =
            [NSKeyedUnarchiver unarchiveObjectWithData:foundData][kV1SyncAccountCredentialsKey];
        for (NSString *credentialKey in credentialsDictionary) {
          NSArray<NSDictionary<NSString *, id> *> *credentialList = credentialsDictionary[credentialKey];
          for (NSDictionary<NSString *, id> *credential in credentialList) {
            NSString *uid = credential[kV1SyncUserIdKey];
            NSString *accessToken = credential[kV1SyncUserAccessTokenKey];
            NSString *accessTokenSecret = credential[kV1SyncUserAccessTokenSecretKey];

            if (uid && accessToken && accessTokenSecret && credentialKey) {
              NSArray<NSString *> *tokenData = @[ uid, accessToken, accessTokenSecret, credentialKey ];
              [v1TokensData addObject:tokenData];
            }
          }
        }
      }
    }
  }
  return v1TokensData;
}
#endif

#if !TARGET_OS_IPHONE
+ (NSArray<NSArray<NSString *> *> *)v1TokensDataOSXCore {
  NSMutableArray<NSArray<NSString *> *> *v1TokensData = [NSMutableArray new];

  NSString *keychainId =
      [NSString stringWithFormat:kV1OSXKeychainServiceKeyBase,
                                 [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]];
  const char *v1ServiceName = [keychainId UTF8String];

  UInt32 dataLen = 0;
  void *pData = nil;
  SecKeychainItemRef itemRef = nil;
  OSStatus status =
      SecKeychainFindGenericPassword(nil, (int32_t)strlen(v1ServiceName), v1ServiceName,
                                     (int32_t)strlen(kV1OSXAccountName), kV1OSXAccountName, &dataLen, &pData, &itemRef);

  if (status == noErr) {
    NSData *foundData = [NSData dataWithBytes:pData length:dataLen];

    NSDictionary *unarchivedFoundData = [NSKeyedUnarchiver unarchiveObjectWithData:foundData];
    NSString *retrievedAppKey = unarchivedFoundData[kV1ConsumerAppKeyKey];

    NSArray<NSDictionary<NSString *, id> *> *credentialsList = unarchivedFoundData[kV1UserCredentialsKey];
    for (NSDictionary<NSString *, id> *credential in credentialsList) {
      NSString *uid = credential[kV1UserIdKey];
      NSString *accessToken = credential[kV1UserAccessTokenKey];
      NSString *accessTokenSecret = credential[kV1UserAccessTokenSecretKey];

      if (uid && accessToken && accessTokenSecret && retrievedAppKey) {
        NSArray<NSString *> *tokenData = @[ uid, accessToken, accessTokenSecret, retrievedAppKey ];
        [v1TokensData addObject:tokenData];
      }
    }
  }

  if (pData) {
    SecKeychainItemFreeContent(nil, pData);
  }

  return v1TokensData;
}

+ (NSArray<NSArray<NSString *> *> *)v1TokensDataOSXSync {
  NSMutableArray<NSArray<NSString *> *> *v1TokensData = [NSMutableArray new];

  NSString *keychainId =
      [NSString stringWithFormat:kV1SyncKeychainServiceKeyBase,
                                 [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]];
  const char *v1ServiceName = [keychainId UTF8String];

  UInt32 dataLen = 0;
  void *pData = nil;
  SecKeychainItemRef itemRef = nil;
  OSStatus status =
      SecKeychainFindGenericPassword(nil, (int32_t)strlen(v1ServiceName), v1ServiceName,
                                     (int32_t)strlen(kV1OSXAccountName), kV1OSXAccountName, &dataLen, &pData, &itemRef);

  if (status == noErr) {
    NSData *data = [NSData dataWithBytes:pData length:dataLen];
    NSDictionary *credentialsDictionary =
        [NSKeyedUnarchiver unarchiveObjectWithData:data][kV1SyncAccountCredentialsKey];
    for (NSString *credentialKey in credentialsDictionary) {
      NSArray<NSDictionary<NSString *, id> *> *credentialList = credentialsDictionary[credentialKey];
      for (NSDictionary<NSString *, id> *credential in credentialList) {
        NSString *uid = credential[kV1SyncUserIdKey];
        NSString *accessToken = credential[kV1SyncUserAccessTokenKey];
        NSString *accessTokenSecret = credential[kV1SyncUserAccessTokenSecretKey];

        if (uid && accessToken && accessTokenSecret && credentialKey) {
          NSArray<NSString *> *tokenData = @[ uid, accessToken, accessTokenSecret, credentialKey ];
          [v1TokensData addObject:tokenData];
        }
      }
    }
  }

  if (pData) {
    SecKeychainItemFreeContent(nil, pData);
  }

  return v1TokensData;
}
#endif

+ (void)convertV1TokenToV2:(NSMutableArray<NSArray<NSString *> *> *)v1TokensData
                    appKey:(NSString *)appKey
                 appSecret:(NSString *)appSecret
             responseBlock:(DBTokenMigrationResponseBlock)responseBlock
                     queue:(NSOperationQueue *)queue {
  DBTransportDefaultConfig *transportConfig =
      [[DBTransportDefaultConfig alloc] initWithAppKey:appKey appSecret:appSecret];
  DBUserClient *unauthorizedClient = [[DBUserClient alloc] initAsUnauthorizedClientWithTransportConfig:transportConfig];

  dispatch_group_t tokenConvertGroup = dispatch_group_create();

  __block BOOL shouldRetry = NO;
  NSLock *shouldRetryLock = [NSLock new];

  __block BOOL invalidAppKeyOrSecret = NO;
  NSLock *invalidAppKeyOrSecretLock = [NSLock new];

  NSMutableDictionary<NSString *, NSString *> *tokenConversionResults = [NSMutableDictionary new];
  NSLock *tokenConversionResultsLock = [NSLock new];

  NSMutableArray<NSArray<NSString *> *> * _Nonnull unsuccessfullyMigratedTokenData = [NSMutableArray new];
  NSLock *unsuccessfullyMigratedTokenDataLock = [NSLock new];

  for (NSArray<NSString *> *v1TokenData in v1TokensData) {
    if ([v1TokenData count] != 4) {
      continue;
    }

    NSString *uid = v1TokenData[0];
    NSString *accessToken = v1TokenData[1];
    NSString *accessTokenSecret = v1TokenData[2];
    NSString *retrievedAppKey = v1TokenData[3];

    if (![retrievedAppKey isEqualToString:appKey]) {
      [invalidAppKeyOrSecretLock lock];
      invalidAppKeyOrSecret = YES;
      [invalidAppKeyOrSecretLock unlock];

      [unsuccessfullyMigratedTokenDataLock lock];
      [unsuccessfullyMigratedTokenData addObject:v1TokenData];
      [unsuccessfullyMigratedTokenDataLock unlock];

      continue;
    }

    dispatch_group_enter(tokenConvertGroup);
    [[unauthorizedClient.authRoutes tokenFromOauth1:accessToken oauth1TokenSecret:accessTokenSecret]
        setResponseBlock:^(DBAUTHTokenFromOAuth1Result *result, DBAUTHTokenFromOAuth1Error *routeError,
                           DBRequestError *error) {
#pragma unused(routeError)
          if (result) {
            NSString *oauth2Token = result.oauth2Token;
            [tokenConversionResultsLock lock];
            [tokenConversionResults setObject:oauth2Token forKey:uid];
            [tokenConversionResultsLock unlock];
          } else {
            if ([error isClientError]) {
              NSError *clientError = error.nsError.userInfo[NSUnderlyingErrorKey];
              if ([clientError.domain isEqualToString:(NSString *)kCFErrorDomainCFNetwork]) {
                // retry for connectivity errors
                [shouldRetryLock lock];
                shouldRetry = YES;
                [shouldRetryLock unlock];
              }
            } else if ([error isBadInputError]) {
              [invalidAppKeyOrSecretLock lock];
              invalidAppKeyOrSecret = YES;
              [invalidAppKeyOrSecretLock unlock];
            }

            [unsuccessfullyMigratedTokenDataLock lock];
            [unsuccessfullyMigratedTokenData addObject:v1TokenData];
            [unsuccessfullyMigratedTokenDataLock unlock];
          }
          dispatch_group_leave(tokenConvertGroup);
        }
                   queue:[NSOperationQueue new]];
  }

  // wait for all token conversion calls to complete and then update the keychain, and call the response block
  dispatch_group_notify(tokenConvertGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    if (!shouldRetry) {
      for (NSString *uid in tokenConversionResults) {
        [[self class] storeValueWithKey:uid value:[tokenConversionResults objectForKey:uid]];
      }
      NSUserDefaults *Defaults = [NSUserDefaults standardUserDefaults];
      [Defaults setObject:@"YES" forKey:[NSString stringWithFormat:kV1TokenMigrationOccurredKeyBase, appKey]];
    }
    [queue addOperationWithBlock:^{
      responseBlock(shouldRetry, invalidAppKeyOrSecret, unsuccessfullyMigratedTokenData);
    }];
  });
}

@end
