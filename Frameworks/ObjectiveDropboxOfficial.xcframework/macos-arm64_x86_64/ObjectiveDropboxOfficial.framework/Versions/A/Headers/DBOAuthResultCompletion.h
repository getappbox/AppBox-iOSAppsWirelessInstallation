///
/// Copyright (c) 2020 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

@class DBOAuthResult;

NS_ASSUME_NONNULL_BEGIN

/// Callback block for oauth result.
typedef void (^DBOAuthCompletion)(DBOAuthResult *_Nullable);

NS_ASSUME_NONNULL_END
