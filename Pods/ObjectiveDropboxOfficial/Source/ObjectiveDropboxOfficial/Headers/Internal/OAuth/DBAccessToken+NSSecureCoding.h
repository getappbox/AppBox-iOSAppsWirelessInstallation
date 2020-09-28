///
/// Copyright (c) 2020 Dropbox, Inc. All rights reserved.
///

#import "DBOAuthManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface DBAccessToken (NSSecureCoding)

/// Attempts to create a DBAccessToken by decoding the given data.
/// @param data The data to decode.
/// @return DBAccessToken object if success, otherwise nil.
+ (nullable DBAccessToken *)createTokenFromData:(NSData *)data;

/// Attempts to convert the given `DBAccessToken` to an `NSData` object.
/// @param token The token to encode.
/// @return NSData object if success, otherwise nil.
+ (nullable NSData *)covertTokenToData:(DBAccessToken *)token;

@end

NS_ASSUME_NONNULL_END
