///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

///
/// Keychain class for storing OAuth tokens.
///
@interface DBSDKKeychain : NSObject

/// Stores a key / value pair in the keychain.
+ (BOOL)set:(NSString *)key value:(NSString *)value;

/// Retrieves a value from the corresponding key
/// from the keychain.
+ (NSString *)get:(NSString *)key;

/// Retrieves all key / value pairs from the keychain.
+ (NSArray<NSString *> *)getAll;

/// Deletes a key / value pair in the keychain.
+ (BOOL) delete:(NSString *)key;

/// Deletes all key / value pairs in the keychain.
+ (BOOL)clear;

@end
