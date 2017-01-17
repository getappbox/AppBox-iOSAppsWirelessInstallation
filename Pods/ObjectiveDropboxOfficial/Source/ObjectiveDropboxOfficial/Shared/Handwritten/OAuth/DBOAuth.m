///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBOAuth.h"
#import "DBOAuthResult.h"
#import "DBSDKKeychain.h"
#import "DBSDKReachability.h"
#import "DBSharedApplicationProtocol.h"

/// A shared instance of a `DBOAuthManager` for convenience
static DBOAuthManager *sharedOAuthManager;
static DBSDKReachability *internetReachableFoo;

#pragma mark - OAuth manager base

@interface DBOAuthManager ()

@property (nonatomic, copy) NSString * _Nullable appKey;
@property (nonatomic, copy) NSURL * _Nullable redirectURL;
@property (nonatomic, copy) NSString * _Nullable host;
@property (nonatomic, copy) NSMutableArray<NSURL *> * _Nullable urls;

@end

@implementation DBOAuthManager

#pragma mark - Shared instance accessors and mutators

+ (DBOAuthManager *)sharedOAuthManager {
  return sharedOAuthManager;
}

+ (void)sharedOAuthManager:(DBOAuthManager *)sharedManager {
  sharedOAuthManager = sharedManager;
}

#pragma mark - Constructors

- (instancetype)initWithAppKey:(NSString *)appKey {
  return [self initWithAppKey:appKey host:@"www.dropbox.com"];
}

- (instancetype)initWithAppKey:(NSString *)appKey host:(NSString *)host {
  self = [super init];
  if (self) {
    _appKey = appKey;
    _redirectURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"db-%@://2/token", _appKey]];
    _host = host;
    _urls = [NSMutableArray arrayWithObjects:_redirectURL, nil];
  }
  return self;
}

#pragma mark - Auth flow methods

- (DBOAuthResult *)handleRedirectURL:(NSURL *)url {
  // check if url is a cancel url
  if (([[url host] isEqualToString:@"1"] && [[url path] isEqualToString:@"/cancel"]) ||
      ([[url host] isEqualToString:@"2"] && [[url path] isEqualToString:@"/cancel"])) {
    return [[DBOAuthResult alloc] initWithCancel];
  }

  if (![self canHandleURL:url]) {
    return nil;
  }

  DBOAuthResult *result = [self extractFromUrl:url];

  if ([result isSuccess]) {
    [DBSDKKeychain set:result.accessToken.uid value:result.accessToken.accessToken];
  }

  return result;
}

- (void)authorizeFromSharedApplication:(id<DBSharedApplication>)sharedApplication browserAuth:(BOOL)browserAuth {
  if ([[DBSDKReachability reachabilityForInternetConnection] currentReachabilityStatus] == DBNotReachable) {
    NSString *message = @"Try again once you have an internet connection.";
    NSString *title = @"No internet connection";

    NSDictionary<NSString *, void (^)()> *buttonHandlers =
        @{ @"Retry" : ^void(){
               [self authorizeFromSharedApplication:sharedApplication browserAuth:browserAuth];
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
  NSString *title = @"SwiftyDropbox Error";

  [sharedApplication presentErrorMessage:message title:title];

  return;
}

NSURL *url = [self authURL];

if ([self checkAndPresentPlatformSpecificAuth:sharedApplication]) {
  return;
}

if (browserAuth) {
  [sharedApplication presentBrowserAuth:url];
} else {
  BOOL (^tryInterceptHandler)
  (NSURL *) = ^BOOL(NSURL *url) {
    if ([self canHandleURL:url]) {
      [sharedApplication presentExternalApp:url];
      return YES;
    } else {
      return NO;
    }
  };

  void (^cancelHandler)() = ^void() {
    NSURL *cancelUrl = [NSURL URLWithString:[NSString stringWithFormat:@"db-%@://2/cancel", _appKey]];
    [sharedApplication presentExternalApp:cancelUrl];
  };

  [sharedApplication presentWebViewAuth:url tryInterceptHandler:tryInterceptHandler cancelHandler:cancelHandler];
}
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

  components.queryItems = @[
    [NSURLQueryItem queryItemWithName:@"response_type" value:@"token"],
    [NSURLQueryItem queryItemWithName:@"client_id" value:_appKey],
    [NSURLQueryItem queryItemWithName:@"redirect_uri" value:[_redirectURL absoluteString]],
    [NSURLQueryItem queryItemWithName:@"disable_signup" value:@"true"],
  ];
  return components.URL;
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

- (DBOAuthResult *)extractFromRedirectURL:(NSURL *)url {
  NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
  NSArray *pairs = [[url fragment] componentsSeparatedByString:@"&"] ?: @[];

  for (NSString *pair in pairs) {
    NSArray *kv = [pair componentsSeparatedByString:@"="];
    [results setObject:[kv objectAtIndex:1] forKey:[kv objectAtIndex:0]];
  }

  if (results[@"error"]) {
    NSString *desc = [[results[@"error_description"] stringByReplacingOccurrencesOfString:@"+" withString:@" "]
                         stringByRemovingPercentEncoding]
                         ?: @"";

    if ([results[@"error"] isEqualToString:@"access_denied"]) {
      return [[DBOAuthResult alloc] initWithCancel];
    }
    return [[DBOAuthResult alloc] initWithError:results[@"error"] errorDescription:desc];
  } else {
    NSString *uid = results[@"uid"];
    DBAccessToken *accessToken = [[DBAccessToken alloc] initWithAccessToken:results[@"access_token"] uid:uid];
    return [[DBOAuthResult alloc] initWithSuccess:accessToken];
  }
}

- (DBOAuthResult *)extractFromUrl:(NSURL *)url {
  return [self extractFromRedirectURL:url];
}

- (BOOL)checkAndPresentPlatformSpecificAuth:(id<DBSharedApplication>)sharedApplication {
#pragma unused(sharedApplication)
  return NO;
}

#pragma mark - Keychain methods

- (BOOL)storeAccessToken:(DBAccessToken *)accessToken {
  return [DBSDKKeychain set:accessToken.uid value:accessToken.accessToken];
}

- (DBAccessToken *)getFirstAccessToken {
  NSDictionary<NSString *, DBAccessToken *> *tokens = [self getAllAccessTokens];
  NSArray *values = [tokens allValues];
  if ([values count] != 0) {
    return [values objectAtIndex:0];
  }
  return nil;
}

- (DBAccessToken *)getAccessToken:(NSString *)owner {
  NSString *accessToken = [DBSDKKeychain get:owner];
  if (accessToken != nil) {
    return [[DBAccessToken alloc] initWithAccessToken:accessToken uid:owner];
  } else {
    return nil;
  }
}

- (NSDictionary<NSString *, DBAccessToken *> *)getAllAccessTokens {
  NSArray<NSString *> *users = [DBSDKKeychain getAll];
  NSMutableDictionary<NSString *, DBAccessToken *> *result = [[NSMutableDictionary alloc] init];
  for (NSString *user in users) {
    NSString *accessToken = [DBSDKKeychain get:user];
    if (accessToken != nil) {
      result[user] = [[DBAccessToken alloc] initWithAccessToken:accessToken uid:user];
    }
  }
  return result;
}

- (BOOL)hasStoredAccessTokens {
  return [self getAllAccessTokens].count != 0;
}

- (BOOL)clearStoredAccessToken:(DBAccessToken *)token {
  return [DBSDKKeychain delete:token.uid];
}

- (BOOL)clearStoredAccessTokens {
  return [DBSDKKeychain clear];
}

@end

#pragma mark - OAuth manager base (macOS)

@implementation DBDesktopOAuthManager

@end

#pragma mark - OAuth manager base (iOS)

static NSString *kDBLinkNonce = @"dropbox.sync.nonce";

@interface DBMobileOAuthManager ()

// "re-declaring" private variables from parent (with @dynamic tag in @implementation)
@property (nonatomic, copy) NSString * _Nullable appKey;
@property (nonatomic, copy) NSURL * _Nullable redirectURL;
@property (nonatomic, copy) NSString * _Nullable host;
@property (nonatomic, copy) NSMutableArray<NSURL *> * _Nullable urls;

/// The redirect url from the mobile "direct auth" flow, wherein
/// authorization is received from an official Dropbox mobile app,
/// if one exists.
@property (nonatomic, copy) NSURL * _Nullable dauthRedirectURL;

@end

@implementation DBMobileOAuthManager

@dynamic appKey;
@dynamic redirectURL;
@dynamic host;
@dynamic urls;

- (instancetype)initWithAppKey:(NSString *)appKey {
  self = [super initWithAppKey:appKey];
  if (self) {
    _dauthRedirectURL = [NSURL URLWithString:[NSString stringWithFormat:@"db-%@://1/connect", appKey]];
    [self.urls addObject:_dauthRedirectURL];
  }
  return self;
}

- (instancetype)initWithAppKey:(NSString *)appKey host:(NSString *)host {
  self = [super initWithAppKey:appKey host:host];
  if (self) {
    _dauthRedirectURL = [NSURL URLWithString:[NSString stringWithFormat:@"db-%@://1/connect", appKey]];
    [self.urls addObject:_dauthRedirectURL];
  }
  return self;
}

- (DBOAuthResult *)extractFromUrl:(NSURL *)url {
  DBOAuthResult *result;
  if ([url.host isEqualToString:@"1"]) { // dauth
    result = [self extractfromDAuthURL:url];
  } else {
    result = [self extractFromRedirectURL:url];
  }
  return result;
}

- (BOOL)checkAndPresentPlatformSpecificAuth:(id<DBSharedApplication>)sharedApplication {
  if (![self hasApplicationQueriesSchemes]) {
    NSString *message = @"DropboxSDK: unable to link; app isn't registered to query for URL schemes dbapi-2 and "
                        @"dbapi-8-emm. In your project's Info.plist file, add a \"dbapi-2\" value and a "
                        @"\"dbapi-8-emm\" value associated with the following keys: \"Information Property List\" > "
                        @"\"LSApplicationQueriesSchemes\" > \"Item <N>\" and \"Item <N+1>\".";
    NSString *title = @"ObjectiveDropbox Error";
    [sharedApplication presentErrorMessage:message title:title];
    return YES;
  }

  NSString *scheme = [self dAuthScheme:sharedApplication];

  if (scheme != nil) {
    NSString *nonce = [[NSUUID alloc] init].UUIDString;
    [[NSUserDefaults standardUserDefaults] setObject:nonce forKey:kDBLinkNonce];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [sharedApplication presentExternalApp:[self dAuthURL:scheme nonce:nonce]];
    return YES;
  }

  return NO;
}

- (NSURL *)dAuthURL:(NSString *)scheme nonce:(NSString *)nonce {
  NSURLComponents *components = [[NSURLComponents alloc] init];
  components.scheme = scheme;
  components.host = @"1";
  components.path = @"/connect";

  if (nonce != nil) {
    NSString *state = [NSString stringWithFormat:@"oauth2:%@", nonce];
    components.queryItems = @[
      [NSURLQueryItem queryItemWithName:@"k" value:self.appKey],
      [NSURLQueryItem queryItemWithName:@"s" value:@""],
      [NSURLQueryItem queryItemWithName:@"state" value:state],
    ];
  }
  return components.URL;
}

- (NSString *)dAuthScheme:(id<DBSharedApplication>)sharedApplication {
  if ([sharedApplication canPresentExternalApp:[self dAuthURL:@"dbapi-2" nonce:nil]]) {
    return @"dbapi-2";
  } else if ([sharedApplication canPresentExternalApp:[self dAuthURL:@"dbapi-8-emm" nonce:nil]]) {
    return @"dbapi-8-emm";
  } else {
    return nil;
  }
}

- (DBOAuthResult *)extractfromDAuthURL:(NSURL *)url {
  NSString *path = url.path;
  if (path != nil) {
    if ([path isEqualToString:@"/connect"]) {
      NSMutableDictionary<NSString *, NSString *> *results = [[NSMutableDictionary alloc] init];
      NSArray<NSString *> *pairs = [url.query componentsSeparatedByString:@"&"] ?: @[];

      for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        [results setObject:[kv objectAtIndex:1] forKey:[kv objectAtIndex:0]];
      }
      NSArray<NSString *> *state = [results[@"state"] componentsSeparatedByString:@"%3A"];

      NSString *nonce = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:kDBLinkNonce];
      if (state.count == 2 && [state[0] isEqualToString:@"oauth2"] && [state[1] isEqualToString:nonce]) {
        NSString *accessToken = results[@"oauth_token_secret"];
        NSString *uid = results[@"uid"];
        return [[DBOAuthResult alloc] initWithSuccess:[[DBAccessToken alloc] initWithAccessToken:accessToken uid:uid]];
      } else {
        return [[DBOAuthResult alloc] initWithError:@"" errorDescription:@"Unable to verify link request."];
      }
    }
  }

  return nil;
}

- (BOOL)hasApplicationQueriesSchemes {
  NSArray<NSString *> *queriesSchemes =
      [[NSBundle mainBundle] objectForInfoDictionaryKey:@"LSApplicationQueriesSchemes"];
  BOOL foundApi2 = NO;
  BOOL foundApi8Emm = NO;
  for (NSString *scheme in queriesSchemes) {
    if ([scheme isEqualToString:@"dbapi-2"]) {
      foundApi2 = YES;
    } else if ([scheme isEqualToString:@"dbapi-8-emm"]) {
      foundApi8Emm = YES;
    }
    if (foundApi2 && foundApi8Emm) {
      return YES;
    }
  }
  return NO;
}

@end

#pragma mark - Access token class

@implementation DBAccessToken

- (instancetype)initWithAccessToken:(NSString *)accessToken uid:(NSString *)uid {
  self = [super init];
  if (self) {
    _accessToken = accessToken;
    _uid = uid;
  }
  return self;
}

- (NSString *)description {
  return _accessToken;
}

@end
