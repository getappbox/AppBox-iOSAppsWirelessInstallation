///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBHandlerTypes.h"

@class DBAccessToken;

NS_ASSUME_NONNULL_BEGIN

///
/// Keychain class for storing OAuth tokens.
///
@interface DBSDKKeychain : NSObject

/// Stores DBAccessToken in the keychain.
+ (BOOL)storeAccessToken:(DBAccessToken *)accessToken;

/// Retrieves a DBAccessToken from the corresponding key (uid) from the keychain.
+ (nullable DBAccessToken *)retrieveTokenWithUid:(NSString *)uid;

/// Retrieves all token uids from the keychain.
+ (NSArray<NSString *> *)retrieveAllTokenIds;

/// Deletes the stored token value for a key (uid).
+ (BOOL)deleteTokenWithUid:(NSString *)uid;

/// Deletes all key / value pairs in the keychain.
+ (BOOL)clearAllTokens;

/// Checks if performing a v1 token migration is necessary, and if so, performs it.
+ (BOOL)checkAndPerformV1TokenMigration:(DBTokenMigrationResponseBlock)responseBlock
                                  queue:(nullable NSOperationQueue *)queue
                                 appKey:(NSString *)appKey
                              appSecret:(NSString *)appSecret;

@end

NS_ASSUME_NONNULL_END
