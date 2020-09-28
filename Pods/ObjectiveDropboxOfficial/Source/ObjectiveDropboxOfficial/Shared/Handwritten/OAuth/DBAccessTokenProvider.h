///
/// Copyright (c) 2020 Dropbox, Inc. All rights reserved.
///

#import "DBOAuthResultCompletion.h"

NS_ASSUME_NONNULL_BEGIN

/// Protocol for objects that provide an access token and offer a way to refresh (short-lived) token.
@protocol DBAccessTokenProvider <NSObject>

/// Returns an access token for making user auth API calls.
@property (nonatomic, readonly) NSString *accessToken;

/// This refreshes the access token if it's expired or about to expire.
/// The refresh result will be passed back via the completion block.
- (void)refreshAccessTokenIfNecessary:(DBOAuthCompletion)completion;

@end

NS_ASSUME_NONNULL_END
