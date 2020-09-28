///
/// Copyright (c) 2020 Dropbox, Inc. All rights reserved.
///

#import "DBOAuthResultCompletion.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Makes a network request to `oauth2/token` to get short-lived access token.
@interface DBOAuthTokenRequest : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Designated initializer.
///
/// @param appKey The app key of the third-party Dropbox API user app that will be associated with all API calls. To
/// create an app or to locate your app's app key, please visit the App Console here:
/// https://www.dropbox.com/developers/apps.
/// @param locale User's preferred locale.
/// @param params A dictionary contains request parameters.
- (instancetype)initWithAppKey:(NSString *)appKey
                        locale:(NSString *)locale
                        params:(NSDictionary<NSString *, NSString *> *)params NS_DESIGNATED_INITIALIZER;

/// Convenience method for `startWithCompletion:queue` with queue set to the main queue.
- (void)startWithCompletion:(DBOAuthCompletion)completion;

/// Sets completion block and starts the request.
///
/// @param completion Completion block to pass back oauth result.
/// @param queue The queue where the completion block will be called from.
- (void)startWithCompletion:(DBOAuthCompletion)completion queue:(dispatch_queue_t)queue;

/// Cancels started request.
- (void)cancel;

@end

/// Request to get an access token with an auth code.
/// See [RFC6749 4.1.3](https://tools.ietf.org/html/rfc6749#section-4.1.3)
@interface DBOAuthTokenExchangeRequest : DBOAuthTokenRequest

- (instancetype)initWithAppKey:(NSString *)appKey
                        locale:(NSString *)locale
                        params:(NSDictionary<NSString *, NSString *> *)params NS_UNAVAILABLE;

///
/// Designated Initializer.
///
/// @param oauthCode OAuth code to exchange an access token.
/// @param codeVerifier Code verifier generated for the auth flow.
/// @param appKey The app key of the third-party Dropbox API user app that will be associated with all API calls. To
/// create an app or to locate your app's app key, please visit the App Console here:
/// https://www.dropbox.com/developers/apps.
/// @param locale User's preferred locale.
/// @param redirectUri Redirect uri used in the auth flow.
- (instancetype)initWithOAuthCode:(NSString *)oauthCode
                     codeVerifier:(NSString *)codeVerifier
                           appKey:(NSString *)appKey
                           locale:(NSString *)locale
                      redirectUri:(NSString *)redirectUri NS_DESIGNATED_INITIALIZER;

@end

/// Request to refresh an access token. See [RFC6749 6](https://tools.ietf.org/html/rfc6749#section-6)
@interface DBOAuthTokenRefreshRequest : DBOAuthTokenRequest

- (instancetype)initWithAppKey:(NSString *)appKey
                        locale:(NSString *)locale
                        params:(NSDictionary<NSString *, NSString *> *)params NS_UNAVAILABLE;

///
/// Designated Initializer.
///
/// @param uid The uid of the access token.
/// @param refreshToken The refresh token used to get a new short-lived access token.
/// @param scopes An array of scopes to be granted for the refreshed access token. Empty array means no changes to the
/// scopes originally granted to the access token.
/// @param appKey The app key of the third-party Dropbox API user app that will be associated with all API calls. To
/// create an app or to locate your app's app key, please visit the App Console here:
/// https://www.dropbox.com/developers/apps.
/// @param locale User's preferred locale.
- (instancetype)initWithUid:(NSString *)uid
               refreshToken:(NSString *)refreshToken
                     scopes:(NSArray<NSString *> *)scopes
                     appKey:(NSString *)appKey
                     locale:(NSString *)locale NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
