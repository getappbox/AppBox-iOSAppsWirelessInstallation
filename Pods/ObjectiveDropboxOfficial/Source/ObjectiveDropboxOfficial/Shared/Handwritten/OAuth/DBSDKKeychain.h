///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBHandlerTypes.h"

///
/// Keychain class for storing OAuth tokens.
///
@interface DBSDKKeychain : NSObject

/// Stores a key / value pair in the keychain.
+ (BOOL)storeValueWithKey:(NSString * _Nonnull)key value:(NSString * _Nonnull)value;

/// Retrieves a value from the corresponding key from the keychain.
+ (NSString * _Nullable)retrieveTokenWithKey:(NSString * _Nonnull)key;

/// Retrieves all key / value pairs from the keychain.
+ (NSArray<NSString *> * _Nonnull)retrieveAllTokens;

/// Deletes a key / value pair in the keychain.
+ (BOOL)deleteTokenWithKey:(NSString * _Nonnull)key;

/// Deletes all key / value pairs in the keychain.
+ (BOOL)clearAllTokens;

/// Checks if performing a v1 token migration is necessary, and if so, performs it.
+ (void)checkAndPerformV1TokenMigration:(DBTokenMigrationResponseBlock _Nonnull)responseBlock
                                  queue:(NSOperationQueue * _Nullable)queue
                                 appKey:(NSString * _Nonnull)appKey
                              appSecret:(NSString * _Nonnull)appSecret;

@end
