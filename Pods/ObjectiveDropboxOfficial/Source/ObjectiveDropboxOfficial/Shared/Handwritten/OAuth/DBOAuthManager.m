///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBOAuthManager.h"

#import "DBAccessTokenProvider+Internal.h"
#import "DBOAuthConstants.h"
#import "DBOAuthPKCESession.h"
#import "DBOAuthResult.h"
#import "DBOAuthTokenRequest.h"
#import "DBOAuthUtils.h"
#import "DBSDKConstants.h"
#import "DBSDKKeychain.h"
#import "DBSDKReachability.h"
#import "DBScopeRequest.h"
#import "DBSharedApplicationProtocol.h"

#pragma mark - Access token class

@implementation DBAccessToken

+ (DBAccessToken *)createWithLongLivedAccessToken:(NSString *)accessToken uid:(NSString *)uid {
  return [[DBAccessToken alloc] initWithAccessToken:accessToken uid:uid];
}

+ (DBAccessToken *)createWithShortLivedAccessToken:(NSString *)accessToken
                                               uid:(NSString *)uid
                                      refreshToken:(NSString *)refreshToken
                          tokenExpirationTimestamp:(NSTimeInterval)tokenExpirationTimestamp {
  return [[DBAccessToken alloc] initWithAccessToken:accessToken
                                                uid:uid
                                       refreshToken:refreshToken
                           tokenExpirationTimestamp:tokenExpirationTimestamp];
}

- (instancetype)initWithAccessToken:(NSString *)accessToken uid:(NSString *)uid {
  return [self initWithAccessToken:accessToken uid:uid refreshToken:nil tokenExpirationTimestamp:0];
}

- (instancetype)initWithAccessToken:(NSString *)accessToken
                                uid:(NSString *)uid
                       refreshToken:(nullable NSString *)refreshToken
           tokenExpirationTimestamp:(NSTimeInterval)tokenExpirationTimestamp {
  self = [super init];
  if (self) {
    _accessToken = [accessToken copy];
    _uid = [uid copy];
    _refreshToken = [refreshToken copy];
    _tokenExpirationTimestamp = tokenExpirationTimestamp;
  }
  return self;
}

/// Indicates whether the access token is short-lived.
- (BOOL)isShortLivedToken {
  return _refreshToken != nil && _tokenExpirationTimestamp > 0;
}

- (NSString *)description {
  return _accessToken;
}

#pragma mark NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  NSString *uid = [coder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(uid))];
  NSString *accessToken =
      [coder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(accessToken))];
  NSString *refreshToken =
      [coder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(refreshToken))];
  NSTimeInterval tokenExpirationTimestamp =
      [coder decodeDoubleForKey:NSStringFromSelector(@selector(tokenExpirationTimestamp))];
  if (accessToken == nil || uid == nil) {
    return nil;
  } else {
    return [self initWithAccessToken:accessToken
                                 uid:uid
                        refreshToken:refreshToken
            tokenExpirationTimestamp:tokenExpirationTimestamp];
  }
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:_uid forKey:NSStringFromSelector(@selector(uid))];
  [coder encodeObject:_accessToken forKey:NSStringFromSelector(@selector(accessToken))];
  [coder encodeObject:_refreshToken forKey:NSStringFromSelector(@selector(refreshToken))];
  [coder encodeDouble:_tokenExpirationTimestamp forKey:NSStringFromSelector(@selector(tokenExpirationTimestamp))];
}

@end

#pragma mark - OAuth manager base

@interface DBOAuthManager ()

@property (nonatomic, readwrite, weak) id<DBSharedApplication> sharedApplication;

@end

@implementation DBOAuthManager

/// A shared instance of a `DBOAuthManager` for convenience
static DBOAuthManager *s_sharedOAuthManager;

#pragma mark - Shared instance accessors and mutators

+ (DBOAuthManager *)sharedOAuthManager {
  return s_sharedOAuthManager;
}

+ (void)setSharedOAuthManager:(DBOAuthManager *)sharedOAuthManager {
  s_sharedOAuthManager = sharedOAuthManager;
}

#pragma mark - Constructors

- (instancetype)initWithAppKey:(NSString *)appKey {
  return [self initWithAppKey:appKey host:nil];
}

- (instancetype)initWithAppKey:(NSString *)appKey host:(NSString *)host {
  return [self initWithAppKey:appKey host:host redirectURL:nil];
}

- (instancetype)initWithAppKey:(NSString *)appKey host:(NSString *)host redirectURL:(NSString *)redirectURL {
  self = [super init];
  if (self) {
    if (host == nil) {
      host = @"www.dropbox.com";
    }

    _appKey = appKey;
    _redirectURL = [[NSURL alloc] initWithString:redirectURL ?: [NSString stringWithFormat:@"db-%@://2/token", appKey]];
    _cancelURL = [NSURL URLWithString:[NSString stringWithFormat:@"db-%@://2/cancel", _appKey]];
    _host = host;
    _urls = [NSMutableArray arrayWithObjects:_redirectURL, nil];
#if TARGET_OS_OSX
    _disableSignup = NO;
#else
    _disableSignup = YES;
#endif
    _webAuthShouldForceReauthentication = NO;
  }
  return self;
}

#pragma mark - Auth flow methods

- (BOOL)handleRedirectURL:(NSURL *)url completion:(DBOAuthCompletion)completion {
  // check if url is a cancel url
  if (([[url host] isEqualToString:@"1"] && [[url path] isEqualToString:@"/cancel"]) ||
      ([[url host] isEqualToString:@"2"] && [[url path] isEqualToString:@"/cancel"])) {
    completion([[DBOAuthResult alloc] initWithCancel]);
    return YES;
  }

  if ([self canHandleURL:url]) {
    [self extractFromUrl:url
              completion:^(DBOAuthResult *result) {
                if ([result isSuccess]) {
                  [self storeAccessToken:result.accessToken];
                }
                completion(result);
              }];
    return YES;
  } else {
    completion(nil);
    return NO;
  }
}

- (void)authorizeFromSharedApplication:(id<DBSharedApplication>)sharedApplication {
  [self authorizeFromSharedApplication:sharedApplication usePkce:NO scopeRequest:nil];
}

- (void)authorizeFromSharedApplication:(id<DBSharedApplication>)sharedApplication
                               usePkce:(BOOL)usePkce
                          scopeRequest:(DBScopeRequest *)scopeRequest {
  void (^cancelHandler)(void) = ^{
    [sharedApplication presentExternalApp:self->_cancelURL];
  };

  if ([[DBSDKReachability reachabilityForInternetConnection] currentReachabilityStatus] == DBNotReachable) {
    NSString *message = NSLocalizedString(@"Try again once you have an internet connection.",
                                          @"Displayed when commencing authorization flow without internet connection.");
    NSString *title = NSLocalizedString(@"No internet connection",
                                        @"Displayed when commencing authorization flow without internet connection.");

    NSDictionary<NSString *, void (^)(void)> *buttonHandlers = @{
      @"Cancel" : ^{
        cancelHandler();
      },
      @"Retry" : ^{
        [self authorizeFromSharedApplication:sharedApplication usePkce:usePkce scopeRequest:scopeRequest];
      }
    };

    [sharedApplication presentErrorMessageWithHandlers:message title:title buttonHandlers:buttonHandlers];

    return;
  }

  if (![self conformsToAppScheme]) {
    NSString *message = [NSString stringWithFormat:@"DropboxSDK: unable to link; app isn't registered for correct URL "
                                                   @"scheme (db-%@). Add this scheme to your project Info.plist file, "
                                                   @"associated with following key: \"Information Property List\" > "
                                                   @"\"URL types\" > \"Item 0\" > \"URL Schemes\" > \"Item <N>\".",
                                                   _appKey];
    NSString *title = @"DropboxSDK Error";

    [sharedApplication presentErrorMessage:message title:title];

    return;
  }

  if (usePkce) {
    _authSession = [[DBOAuthPKCESession alloc] initWithScopeRequest:scopeRequest];
  } else {
    _authSession = nil;
  }
  _sharedApplication = sharedApplication;

  NSURL *authUrl = [self authURL];

  if ([self checkAndPresentPlatformSpecificAuth:sharedApplication]) {
    return;
  }

  [sharedApplication presentAuthChannel:authUrl cancelHandler:cancelHandler];
}

- (BOOL)conformsToAppScheme {
  NSString *appScheme = [NSString stringWithFormat:@"db-%@", _appKey];

  NSArray *urlTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"] ?: @[];

  for (NSDictionary *urlType in urlTypes) {
    NSArray<NSString *> *schemes = [urlType objectForKey:@"CFBundleURLSchemes"];
    for (NSString *scheme in schemes) {
      if ([scheme isEqualToString:appScheme]) {
        return YES;
      }
    }
  }
  return NO;
}

- (NSURL *)authURL {
  NSURLComponents *components = [[NSURLComponents alloc] init];
  components.scheme = @"https";
  components.host = _host;
  components.path = @"/oauth2/authorize";

  NSMutableArray<NSURLQueryItem *> *queryItems = [@[
    [NSURLQueryItem queryItemWithName:@"client_id" value:_appKey],
    [NSURLQueryItem queryItemWithName:@"redirect_uri" value:_redirectURL.absoluteString],
    [NSURLQueryItem queryItemWithName:@"disable_signup" value:_disableSignup ? @"true" : @"false"],
    [NSURLQueryItem queryItemWithName:@"locale" value:[self db_localeIdentifier]],
  ] mutableCopy];

  if (_authSession) {
    // Code flow
    [queryItems addObjectsFromArray:[DBOAuthUtils createPkceCodeFlowParamsForAuthSession:_authSession]];
  } else {
    // Token flow
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"response_type" value:@"token"]];
  }
  // used to prevent malicious impersonation of app from web browser
  NSString *state = [[NSProcessInfo processInfo] globallyUniqueString];
  [queryItems addObject:[NSURLQueryItem queryItemWithName:kDBStateKey value:state]];
  [[NSUserDefaults standardUserDefaults] setValue:state forKey:kDBSDKCSRFKey];

  [queryItems addObject:[NSURLQueryItem queryItemWithName:@"force_reauthentication"
                                                    value:_webAuthShouldForceReauthentication ? @"true" : @"false"]];
  components.queryItems = queryItems;
  NSURL *url = components.URL;
  NSAssert(url, @"Failed to create auth url.");
  return url;
}

- (BOOL)canHandleURL:(NSURL *)url {
  for (NSURL *known in _urls) {
    if ([url.scheme isEqualToString:known.scheme] && [url.host isEqualToString:known.host] &&
        [url.path isEqualToString:known.path]) {
      return YES;
    }
  }
  return NO;
}

/// Handles redirect URL from web.
///
/// Auth results are passed back in URL query parameters.
///
/// Error result parameters looks like this:
/// @code
/// [
///     "error": "<error_name>",
///     "error_description: "<error_description>"
/// ]
/// @endcode
///
/// Success result looks like these:
///
/// 1. Code flow result
/// @code
/// [
///     "state": "<state_string>",
///     "code": "<oauth_code>"
/// ]
/// @endcode
/// 2. Token flow result
/// @code
/// [
///     "state": "<state_string>",
///     "access_token": "<oauth2_access_token>",
///     "uid": "<uid>"
/// ]
/// @endcode
- (void)extractAuthResultFromRedirectURL:(NSURL *)url completion:(DBOAuthCompletion)completion {
  NSDictionary<NSString *, NSString *> *parametersMap = nil;
  BOOL isInOAuthCodeFlow = _authSession != nil;
  if (isInOAuthCodeFlow) {
    parametersMap = [DBOAuthUtils extractOAuthResponseFromCodeFlowUrl:url];
  } else {
    parametersMap = [DBOAuthUtils extractOAuthResponseFromTokenFlowUrl:url];
  }
  if (parametersMap[kDBErrorKey]) {
    // Error case
    DBOAuthResult *result = [[DBOAuthResult alloc] initWithError:parametersMap[kDBErrorKey]
                                                errorDescription:parametersMap[kDBErrorDescriptionKey]];
    if (result.errorType == DBAuthAccessDenied) {
      // DBAuthAccessDenied happens when user taps on the "Cancel" button on web.
      result = [[DBOAuthResult alloc] initWithCancel];
    }
    completion(result);
  } else {
    // Success case
    NSString *state = parametersMap[kDBStateKey];
    NSString *storedState = [[NSUserDefaults standardUserDefaults] stringForKey:kDBSDKCSRFKey];

    // State from redirect URL should be non-nil and match stored state.
    if (state == nil || storedState == nil || ![state isEqualToString:storedState]) {
      DBOAuthResult *result = [[DBOAuthResult alloc] initWithError:@"inconsistent_state"
                                                  errorDescription:@"Auth flow failed because of inconsistent state."];
      completion(result);
    } else {
      // reset upon success
      [[NSUserDefaults standardUserDefaults] setValue:nil forKey:kDBSDKCSRFKey];

      if (_authSession && parametersMap[@"code"]) {
        // Code flow
        [self finishPkceOAuthWithAuthCode:parametersMap[@"code"]
                             codeVerifier:_authSession.pkceData.codeVerifier
                               completion:completion];
      } else if (parametersMap[kDBUidKey] && parametersMap[@"access_token"]) {
        // Token flow
        NSString *uid = parametersMap[kDBUidKey];
        DBAccessToken *accessToken =
            [DBAccessToken createWithLongLivedAccessToken:parametersMap[@"access_token"] uid:uid];
        completion([[DBOAuthResult alloc] initWithSuccess:accessToken]);
      } else {
        completion([DBOAuthResult unknownErrorWithErrorDescription:@"Invalid response."]);
      }
    }
  }
}

- (void)extractFromUrl:(NSURL *)url completion:(DBOAuthCompletion)completion {
  [self extractAuthResultFromRedirectURL:url completion:completion];
}

- (void)finishPkceOAuthWithAuthCode:(NSString *)authCode
                       codeVerifier:(NSString *)codeVerifier
                         completion:(DBOAuthCompletion)completion {
  [_sharedApplication presentLoading];
  DBOAuthTokenExchangeRequest *request =
      [[DBOAuthTokenExchangeRequest alloc] initWithOAuthCode:authCode
                                                codeVerifier:codeVerifier
                                                      appKey:_appKey
                                                      locale:[self db_localeIdentifier]
                                                 redirectUri:_redirectURL.absoluteString];
  __weak id<DBSharedApplication> sharedApplication = _sharedApplication;
  DBOAuthCompletion wrappedCompletion = ^(DBOAuthResult *result) {
    [sharedApplication dismissLoading];
    completion(result);
  };
  [request startWithCompletion:wrappedCompletion queue:dispatch_get_main_queue()];
}

- (BOOL)checkAndPresentPlatformSpecificAuth:(id<DBSharedApplication>)sharedApplication {
#pragma unused(sharedApplication)
  return NO;
}

- (NSString *)db_localeIdentifier {
  return [_locale localeIdentifier] ?: ([[NSBundle mainBundle] preferredLocalizations].firstObject ?: @"en");
}

#pragma mark - Short-lived token support.

- (void)refreshAccessToken:(DBAccessToken *)accessToken
                    scopes:(NSArray<NSString *> *)scopes
                     queue:(dispatch_queue_t)queue
                completion:(DBOAuthCompletion)completion {
  NSString *refreshToken = accessToken.refreshToken;
  if (!refreshToken) {
    completion([DBOAuthResult unknownErrorWithErrorDescription:@"Long-lived token can't be refreshed."]);
    return;
  }

  DBOAuthTokenRefreshRequest *request = [[DBOAuthTokenRefreshRequest alloc] initWithUid:accessToken.uid
                                                                           refreshToken:refreshToken
                                                                                 scopes:scopes
                                                                                 appKey:_appKey
                                                                                 locale:[self db_localeIdentifier]];
  __weak typeof(self) weakSelf = self;
  DBOAuthCompletion wrappedCompletion = ^(DBOAuthResult *result) {
    if ([result isSuccess] && result.accessToken) {
      [weakSelf storeAccessToken:result.accessToken];
    }
    completion(result);
  };
  [request startWithCompletion:wrappedCompletion queue:queue ?: dispatch_get_main_queue()];
}

- (id<DBAccessTokenProvider>)accessTokenProviderForToken:(DBAccessToken *)token {
  if ([token isShortLivedToken]) {
    return [[DBShortLivedAccessTokenProvider alloc] initWithToken:token tokenRefresher:self];
  } else {
    return [[DBLongLivedAccessTokenProvider alloc] initWithTokenString:token.accessToken];
  }
}

#pragma mark - Keychain methods

- (BOOL)storeAccessToken:(DBAccessToken *)accessToken {
  return [DBSDKKeychain storeAccessToken:accessToken];
}

- (DBAccessToken *)retrieveFirstAccessToken {
  NSDictionary<NSString *, DBAccessToken *> *tokens = [self retrieveAllAccessTokens];
  NSArray *values = [tokens allValues];
  if ([values count] != 0) {
    return [values objectAtIndex:0];
  }
  return nil;
}

- (DBAccessToken *)retrieveAccessToken:(NSString *)tokenUid {
  return [DBSDKKeychain retrieveTokenWithUid:tokenUid];
}

- (NSDictionary<NSString *, DBAccessToken *> *)retrieveAllAccessTokens {
  NSArray<NSString *> *userIds = [DBSDKKeychain retrieveAllTokenIds];
  NSMutableDictionary<NSString *, DBAccessToken *> *result = [[NSMutableDictionary alloc] init];
  for (NSString *userId in userIds) {
    DBAccessToken *token = [DBSDKKeychain retrieveTokenWithUid:userId];
    if (token) {
      result[userId] = token;
    }
  }
  return result;
}

- (BOOL)hasStoredAccessTokens {
  return [self retrieveAllAccessTokens].count != 0;
}

- (BOOL)clearStoredAccessToken:(NSString *)tokenUid {
  return [DBSDKKeychain deleteTokenWithUid:tokenUid];
}

- (BOOL)clearStoredAccessTokens {
  return [DBSDKKeychain clearAllTokens];
}

@end
