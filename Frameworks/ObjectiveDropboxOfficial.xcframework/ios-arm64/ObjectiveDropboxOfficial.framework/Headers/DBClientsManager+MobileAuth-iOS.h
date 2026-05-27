///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBClientsManager.h"

@class DBScopeRequest;
@class DBTransportDefaultConfig;
@class UIApplication;
@class UIViewController;

@protocol DBLoadingStatusDelegate;

NS_ASSUME_NONNULL_BEGIN

///
/// Code with platform-specific (here, iOS) dependencies.
///
/// Extends functionality of the `DBClientsManager` class.
///
@interface DBClientsManager (MobileAuth)

///
/// Commences OAuth mobile flow from supplied view controller.
///
/// This starts a "token" flow.
///
/// This method should no longer be used.
/// Long-lived access tokens are deprecated. See
/// https://dropbox.tech/developers/migrating-app-permissions-and-access-tokens.
/// Please use `authorizeFromControllerV2` instead.
///
/// @param sharedApplication The `UIApplication` with which to render the OAuth flow.
/// @param controller The `UIViewController` with which to render the OAuth flow. Please ensure that this is the
/// top-most view controller, so that the authorization view displays correctly. The controller reference is weakly
/// held.
/// @param openURL A wrapper around app-extension unsafe `openURL` call.
///
+ (void)authorizeFromController:(UIApplication *)sharedApplication
                     controller:(nullable UIViewController *)controller
                        openURL:(void (^_Nonnull)(NSURL *))openURL
    __deprecated_msg("This method was used for long-lived access tokens, which are now deprecated. Please use "
                     "`authorizeFromControllerV2` instead.");

///
/// Commences OAuth mobile flow from supplied view controller.
///
/// This starts the OAuth 2 Authorization Code Flow with PKCE.
/// PKCE allows "authorization code" flow without "client_secret"
/// It enables "native application", which is ensafe to hardcode client_secret in code, to use "authorization code".
/// PKCE is more secure than "token" flow. If authorization code is compromised during
/// transmission, it can't be used to exchange for access token without random generated
/// code_verifier, which is stored inside this SDK.
///
/// @param sharedApplication The `UIApplication` with which to render the OAuth flow.
/// @param controller The `UIViewController` with which to render the OAuth flow. Please ensure that this is the
/// top-most view controller, so that the authorization view displays correctly. The controller reference is weakly
/// held.
/// @param loadingStatusDelegate An optional delegate to handle loading experience during auth flow.
/// e.g. Show a loading spinner and block user interaction while loading/waiting.
/// If a delegate is not provided, the SDK will show a default loading spinner when necessary.
/// @param openURL A wrapper around app-extension unsafe `openURL` call.
/// @param scopeRequest Request contains information of scopes to be obtained.
///
+ (void)authorizeFromControllerV2:(UIApplication *)sharedApplication
                       controller:(nullable UIViewController *)controller
            loadingStatusDelegate:(nullable id<DBLoadingStatusDelegate>)loadingStatusDelegate
                          openURL:(void (^_Nonnull)(NSURL *))openURL
                     scopeRequest:(nullable DBScopeRequest *)scopeRequest;

///
/// Stores the user app key. If any access token already exists, initializes an authorized shared `DBUserClient`
/// instance. Convenience method for `setupWithTransportConfig:`.
///
/// This method should be used in the single Dropbox user case. If any stored OAuth tokens exist, one will arbitrarily
/// be retrieved and used to authenticate API calls. Use `setupWithTransportConfig:`, if additional customization of
/// network calling parameters is necessary. This method should be called from the app delegate.
///
/// @param appKey The app key of the third-party Dropbox API user app that will be associated with all API calls. To
/// create an app or to locate your app's app key, please visit the App Console here:
/// https://www.dropbox.com/developers/apps.
///
+ (void)setupWithAppKey:(NSString *)appKey;

///
/// Stores the user transport config info. If any access token already exists, initializes an authorized shared
/// `DBUserClient` instance.
///
/// This method should be used in the single Dropbox user case. If any stored OAuth tokens exist, one will arbitrarily
/// be retrieved and used to authenticate API calls. You can customize some network calling parameters using the
/// different `DBTransportDefaultConfig` constructors. This method should be called from the app delegate.
///
/// @param transportConfig A wrapper around the different parameters that can be set to change network calling behavior.
///
+ (void)setupWithTransportConfig:(nullable DBTransportDefaultConfig *)transportConfig;

///
/// Stores the team app key. If any access token already exists, initializes an authorized shared `DBTeamClient`
/// instance. Convenience method for `setupWithTeamTransportConfig:`.
///
/// This method should be used in the single Dropbox user case. If any stored OAuth tokens exist, one will arbitrarily
/// be retrieved and used to authenticate API calls. Use `setupWithTeamTransportConfig:`, if additional customization of
/// network calling parameters is necessary. This method should be called from the app delegate.
///
/// @param appKey The app key of the third-party Dropbox API user app that will be associated with all API calls. To
/// create an app or to locate your app's app key, please visit the App Console here:
/// https://www.dropbox.com/developers/apps.
///
+ (void)setupWithTeamAppKey:(NSString *)appKey;

///
/// Stores the team transport config info. If any access token already exists, initializes an authorized shared
/// `DBTeamClient` instance.
///
/// This method should be used in the single Dropbox user case. If any stored OAuth tokens exist, one will arbitrarily
/// be retrieved and used to authenticate API calls. You can customize some network calling parameters using the
/// different `DBTransportDefaultConfig` constructors. This method should be called from the app delegate.
///
/// @param transportConfig A wrapper around the different parameters that can be set to change network calling behavior.
///
+ (void)setupWithTeamTransportConfig:(nullable DBTransportDefaultConfig *)transportConfig;

@end

NS_ASSUME_NONNULL_END
