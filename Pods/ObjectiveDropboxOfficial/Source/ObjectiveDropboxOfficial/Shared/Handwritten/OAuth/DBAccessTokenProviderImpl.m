///
/// Copyright (c) 2020 Dropbox, Inc. All rights reserved.
///

#import "DBAccessTokenProvider+Internal.h"

#import "DBOAuthResult.h"

@implementation DBLongLivedAccessTokenProvider

@synthesize accessToken = _accessToken;

- (instancetype)initWithTokenString:(NSString *)tokenString {
  self = [super init];
  if (self) {
    _accessToken = tokenString;
  }
  return self;
}

- (void)refreshAccessTokenIfNecessary:(DBOAuthCompletion)completion {
  // Complete with empty result, because it doesn't need a refresh.
  completion(nil);
}

@end

@interface DBShortLivedAccessTokenProvider ()

@property (nonatomic, strong) DBAccessToken *token;
@property (nonatomic, strong) id<DBAccessTokenRefreshing> tokenRefresher;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) NSMutableArray<DBOAuthCompletion> *completionBlocks;

@end

@implementation DBShortLivedAccessTokenProvider

- (instancetype)initWithToken:(DBAccessToken *)token tokenRefresher:(id<DBAccessTokenRefreshing>)tokenRefresher {
  self = [super init];
  if (self) {
    _token = token;
    _tokenRefresher = tokenRefresher;
    dispatch_queue_attr_t qosAttribute =
        dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT, QOS_CLASS_USER_INITIATED, 0);
    _queue = dispatch_queue_create("com.dropbox.dropbox_sdk_obj_c.DBShortLivedAccessTokenProvider.queue", qosAttribute);
    _completionBlocks = [NSMutableArray new];
  }
  return self;
}

- (NSString *)accessToken {
  __block NSString *tokenString = nil;
  dispatch_sync(_queue, ^{
    tokenString = _token.accessToken;
  });
  return tokenString;
}

- (void)refreshAccessTokenIfNecessary:(DBOAuthCompletion)completion {
  dispatch_barrier_async(_queue, ^{
    if (![self db_shouldRefresh]) {
      completion(nil);
      return;
    }

    // Ensure subsequent calls don't initiate more refresh requests, if one is in progress.
    BOOL refreshInProgress = [self db_refreshInProgress];
    [self->_completionBlocks addObject:completion];
    if (!refreshInProgress) {
      __weak typeof(self) weakSelf = self;
      [self->_tokenRefresher refreshAccessToken:self->_token
                                         scopes:@[]
                                          queue:nil
                                     completion:^(DBOAuthResult *result) {
                                       [weakSelf db_handleRefreshResult:result];
                                     }];
    }
  });
}

/// Refresh if it's about to expire (5 minutes from expiration) or already expired.
- (BOOL)db_shouldRefresh {
  NSTimeInterval expirationTimestamp = _token.tokenExpirationTimestamp;
  if (expirationTimestamp == 0) {
    return NO;
  }

  NSDate *fiveMinutesBeforeExpire = [NSDate dateWithTimeIntervalSince1970:expirationTimestamp - 300];
  BOOL dateHasPassed = fiveMinutesBeforeExpire.timeIntervalSinceNow < 0;
  return dateHasPassed;
}

- (BOOL)db_refreshInProgress {
  return _completionBlocks.count > 0;
}

- (void)db_handleRefreshResult:(DBOAuthResult *)result {
  dispatch_barrier_async(_queue, ^{
    if ([result isSuccess] && result.accessToken) {
      self->_token = result.accessToken;
    }
    for (DBOAuthCompletion block in self->_completionBlocks) {
      block(result);
    }
    [self->_completionBlocks removeAllObjects];
  });
}

@end
