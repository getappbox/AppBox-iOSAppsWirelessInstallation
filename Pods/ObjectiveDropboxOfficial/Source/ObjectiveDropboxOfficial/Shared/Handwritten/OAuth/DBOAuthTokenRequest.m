///
/// Copyright (c) 2020 Dropbox, Inc. All rights reserved.
///

#import "DBOAuthTokenRequest.h"

#import "DBOAuthManager.h"
#import "DBOAuthResult.h"
#import "DBSDKConstants.h"
#import "DBTransportBaseConfig.h"
#import "DBTransportBaseHostnameConfig.h"

#pragma mark - DBOAuthTokenRequest

@interface DBOAuthTokenRequest ()

@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) DBOAuthTokenRequest *retainSelf;
@property (nonatomic, copy) DBOAuthCompletion completion;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation DBOAuthTokenRequest

- (instancetype)initWithAppKey:(NSString *)appKey
                        locale:(NSString *)locale
                        params:(NSDictionary<NSString *, NSString *> *)params {
  self = [super init];
  if (self) {
    _task = [self db_createTokenRequestTaskWithParams:params appKey:appKey locale:locale];
  }
  return self;
}

- (void)startWithCompletion:(DBOAuthCompletion)completion {
  [self startWithCompletion:completion queue:dispatch_get_main_queue()];
}

- (void)startWithCompletion:(DBOAuthCompletion)completion queue:(dispatch_queue_t)queue {
#pragma unused(queue)
  _retainSelf = self;
  _completion = [completion copy];
  _queue = nil;
  [_task resume];
}

- (void)cancel {
  [_task cancel];
  _retainSelf = nil;
}

- (NSURLSessionDataTask *)db_createTokenRequestTaskWithParams:(NSDictionary<NSString *, NSString *> *)params
                                                       appKey:(NSString *)appKey
                                                       locale:(NSString *)locale {
  NSURLComponents *urlComponents = [NSURLComponents new];
  urlComponents.scheme = @"https";
  urlComponents.host = [[DBTransportBaseHostnameConfig alloc] init].api;
  urlComponents.path = @"/oauth2/token";
  NSURL *url = urlComponents.URL;
  NSAssert(url, @"Unable to create oauth2/token url");

  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
  NSMutableDictionary<NSString *, NSString *> *allParams = [params mutableCopy];
  [allParams addEntriesFromDictionary:@{ @"locale" : locale, @"client_id" : appKey }];
  NSMutableArray<NSString *> *paramsArray = [NSMutableArray new];
  for (NSString *key in allParams.allKeys) {
    [paramsArray addObject:[NSString stringWithFormat:@"%@=%@", key, allParams[key]]];
  }
  NSString *paramsString = [paramsArray componentsJoinedByString:@"&"];
  NSData *paramsData = [paramsString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];

  request.HTTPMethod = @"POST";
  request.HTTPBody = paramsData;
  [request addValue:[DBTransportBaseConfig defaultUserAgent] forHTTPHeaderField:@"User-Agent"];
  [request addValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];

  __weak typeof(self) weakSelf = self;
  return [[NSURLSession sharedSession] dataTaskWithRequest:request
                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                           [weakSelf db_handleResponse:response data:data error:error];
                                         }];

  return [[NSURLSession sharedSession] dataTaskWithRequest:request];
}

- (void)db_handleResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *)error {
#pragma unused(response)
  DBOAuthResult *result = nil;
  if (error) {
    // Network error
    result = [DBOAuthResult unknownErrorWithErrorDescription:error.localizedDescription];
  } else {
    // No network error, parse response data
    NSDictionary<NSString *, id> *resultDict = [self db_resultDictionaryFromData:data];
    result = [self db_extractResultFromDict:resultDict];
  }

  dispatch_queue_t queue = _queue ?: dispatch_get_main_queue();
  dispatch_async(queue, ^{
    self->_completion(result);
  });
  _retainSelf = nil;
}

- (NSDictionary<NSString *, id> *)db_resultDictionaryFromData:(NSData *)data {
  if (data == nil) {
    return nil;
  }
  id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
  if ([json isKindOfClass:[NSDictionary<NSString *, id> class]]) {
    return json;
  } else {
    return nil;
  }
}

- (DBOAuthResult *)db_extractResultFromDict:(NSDictionary<NSString *, id> *)dict {
  // Interpret success result if any.
  DBOAuthResult *successResult = [self db_extractSuccessResultFromDict:dict];
  if (successResult) {
    return successResult;
  }

  // Interpret error if any.
  DBOAuthResult *errorResult = [self db_extractErrorResultFromDict:dict];
  if (errorResult) {
    return errorResult;
  }

  return [DBOAuthResult unknownErrorWithErrorDescription:@"Invalid response."];
}

/// Converts error to OAuth2Error as per [RFC6749 5.2](https://tools.ietf.org/html/rfc6749#section-5.2)
- (DBOAuthResult *)db_extractErrorResultFromDict:(NSDictionary<NSString *, id> *)dict {
  id errorCode = dict[@"error"];
  if (!errorCode) {
    return nil;
  }
  id errorDescription = dict[@"error_description"];
  if ([errorCode isKindOfClass:[NSString class]] && [errorDescription isKindOfClass:[NSString class]]) {
    return [[DBOAuthResult alloc] initWithError:errorCode errorDescription:errorDescription];
  } else {
    return [DBOAuthResult unknownErrorWithErrorDescription:nil];
  }
}

- (DBOAuthResult *)db_extractSuccessResultFromDict:(NSDictionary<NSString *, id> *)dict {
#pragma unused(dict)
  NSAssert(NO, @"Subclasses must implement this method");
  return nil;
}

@end

#pragma mark - DBOAuthTokenExchangeRequest

@implementation DBOAuthTokenExchangeRequest

- (instancetype)initWithOAuthCode:(NSString *)oauthCode
                     codeVerifier:(NSString *)codeVerifier
                           appKey:(NSString *)appKey
                           locale:(NSString *)locale
                      redirectUri:(NSString *)redirectUri {
  NSDictionary<NSString *, NSString *> *paramsDict = @{
    @"grant_type" : @"authorization_code",
    @"code" : oauthCode,
    @"code_verifier" : codeVerifier,
    @"redirect_uri" : redirectUri
  };
  return [super initWithAppKey:appKey locale:locale params:paramsDict];
}

/// Handle access token result as per [RFC6749 4.1.4](https://tools.ietf.org/html/rfc6749#section-4.1.4)
/// And an additional Dropbox uid parameter.
- (DBOAuthResult *)db_extractSuccessResultFromDict:(NSDictionary<NSString *, id> *)dict {
  id tokenType = dict[@"token_type"];
  id accessToken = dict[@"access_token"];
  id refreshToken = dict[@"refresh_token"];
  id userId = dict[@"uid"];
  id expiresIn = dict[@"expires_in"];

  BOOL valid =
      [tokenType isKindOfClass:[NSString class]] && [@"bearer" caseInsensitiveCompare:tokenType] == NSOrderedSame;
  valid = valid && [accessToken isKindOfClass:[NSString class]];
  valid = valid && [refreshToken isKindOfClass:[NSString class]];
  valid = valid && [userId isKindOfClass:[NSString class]];
  valid = valid && [expiresIn isKindOfClass:[NSNumber class]];

  if (valid) {
    NSTimeInterval tokenExpirationTimestamp =
        [[[NSDate new] dateByAddingTimeInterval:((NSNumber *)expiresIn).doubleValue] timeIntervalSince1970];
    DBAccessToken *token = [DBAccessToken createWithShortLivedAccessToken:accessToken
                                                                      uid:userId
                                                             refreshToken:refreshToken
                                                 tokenExpirationTimestamp:tokenExpirationTimestamp];
    ;
    return [[DBOAuthResult alloc] initWithSuccess:token];
  } else {
    return nil;
  }
}

@end

#pragma mark - DBOAuthTokenRefreshRequest

@interface DBOAuthTokenRefreshRequest ()

@property (nonatomic, copy, nonnull) NSString *uid;
@property (nonatomic, copy, nonnull) NSString *refreshToken;

@end

@implementation DBOAuthTokenRefreshRequest

- (instancetype)initWithUid:(NSString *)uid
               refreshToken:(NSString *)refreshToken
                     scopes:(NSArray<NSString *> *)scopes
                     appKey:(NSString *)appKey
                     locale:(NSString *)locale {
  NSMutableDictionary<NSString *, NSString *> *paramsDict = [@{
    @"grant_type" : @"refresh_token",
    @"refresh_token" : refreshToken,
  } mutableCopy];
  if (scopes.count > 0) {
    paramsDict[@"scope"] = [scopes componentsJoinedByString:@" "];
  }
  self = [super initWithAppKey:appKey locale:locale params:paramsDict];
  if (self) {
    _uid = uid;
    _refreshToken = refreshToken;
  }
  return self;
}

/// Handle refresh result as per [RFC6749 5.1](https://tools.ietf.org/html/rfc6749#section-5.1)
- (DBOAuthResult *)db_extractSuccessResultFromDict:(NSDictionary<NSString *, id> *)dict {
  id tokenType = dict[@"token_type"];
  id accessToken = dict[@"access_token"];
  id expiresIn = dict[@"expires_in"];

  BOOL valid =
      [tokenType isKindOfClass:[NSString class]] && [@"bearer" caseInsensitiveCompare:tokenType] == NSOrderedSame;
  valid = valid && [accessToken isKindOfClass:[NSString class]];
  valid = valid && [expiresIn isKindOfClass:[NSNumber class]];

  if (valid) {
    NSTimeInterval tokenExpirationTimestamp =
        [[[NSDate new] dateByAddingTimeInterval:((NSNumber *)expiresIn).doubleValue] timeIntervalSince1970];
    DBAccessToken *token = [DBAccessToken createWithShortLivedAccessToken:accessToken
                                                                      uid:_uid
                                                             refreshToken:_refreshToken
                                                 tokenExpirationTimestamp:tokenExpirationTimestamp];
    ;
    return [[DBOAuthResult alloc] initWithSuccess:token];
  } else {
    return nil;
  }
}

@end
