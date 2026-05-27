///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBClientsManager.h"
#import "DBOAuthDesktop-macOS.h"
#import "DBOAuthResult.h"

@class DBScopeRequest;
@class DBTransportDefaultConfig;
@class NSWorkspace;
@class NSViewController;

@protocol DBLoadingStatusDelegate;

NS_ASSUME_NONNULL_BEGIN

///
/// Code with platform-specific (here, macOS) dependencies.
///
/// Extends functionality of the `DBClientsManager` class.
///
@interface DBClientsManager (DesktopAuth)

///
/// Commences OAuth desktop flow from supplied view controller.
///
/// This method should no longer be used.
/// Long-lived access tokens are deprecated. See
/// https://dropbox.tech/developers/migrating-app-permissions-and-access-tokens.
/// Please use `authorizeFromControllerDesktopV2` instead.
///
/// @param sharedApplication The `NSWorkspace` with which to render the OAuth flow.
/// @param controller The `NSViewController` with which to render the OAuth flow. The controller reference is weakly
/// held.
/// @param openURL A wrapper around app-extension unsafe `openURL` call.
///
+ (void)authorizeFromControllerDesktop:(NSWorkspace *)sharedApplication
                            controller:(nullable NSViewController *)controller
                               openURL:(void (^_Nonnull)(NSURL *))openURL
    __deprecated_msg("This method was used for long-lived access tokens, which are now deprecated. Please use "
                     "`authorizeFromControllerDesktopV2` instead.");

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
/// @param sharedApplication The `NSWorkspace` with which to render the OAuth flow.
/// @param controller The `NSViewController` with which to render the OAuth flow. The controller reference is weakly
/// held.
/// @param loadingStatusDelegate An optional delegate to handle loading experience during auth flow.
/// e.g. Show a loading spinner and block user interaction while loading/waiting.
/// @param openURL A wrapper around app-extension unsafe `openURL` call.
/// @param scopeRequest Request contains information of scopes to be obtained.
///
+ (void)authorizeFromControllerDesktopV2:(NSWorkspace *)sharedApplication
                              controller:(nullable NSViewController *)controller
                   loadingStatusDelegate:(nullable id<DBLoadingStatusDelegate>)loadingStatusDelegate
                                 openURL:(void (^_Nonnull)(NSURL *))openURL
                            scopeRequest:(nullable DBScopeRequest *)scopeRequest;

///
/// Stores the user app key for desktop. If any access token already exists, initializes an authorized shared
/// `DBUserClient` instance. Convenience method for `setupWithTransportConfigDesktop:`.
///
/// This method should be used in the single Dropbox user case. If any stored OAuth tokens exist, one will arbitrarily
/// be retrieved and used to authenticate API calls. Use `setupWithTransportConfig:`, if additional customization of
/// network calling parameters is necessary. This method should be called from the app delegate.
///
/// @param appKey The app key of the third-party Dropbox API user app that will be associated with all API calls. To
/// create an app or to locate your app's app key, please visit the App Console here:
/// https://www.dropbox.com/developers/apps.
///
+ (void)setupWithAppKeyDesktop:(NSString *)appKey;

///
/// Stores the user transport config info for desktop. If any access token already exists, initializes an authorized
/// shared `DBUserClient` instance.
///
/// This method should be used in the single Dropbox user case. If any stored OAuth tokens exist, one will arbitrarily
/// be retrieved and used to authenticate API calls. You can customize some network calling parameters using the
/// different `DBTransportDefaultConfig` constructors. This method should be called from the app delegate.
///
/// @param transportConfig A wrapper around the different parameters that can be set to change network calling behavior.
///
+ (void)setupWithTransportConfigDesktop:(nullable DBTransportDefaultConfig *)transportConfig;

///
/// Stores the team app key for desktop. If any access token already exists, initializes an authorized shared
/// `DBTeamClient` instance. Convenience method for `setupWithTeamTransportConfigDesktop:`.
///
/// This method should be used in the single Dropbox user case. If any stored OAuth tokens exist, one will arbitrarily
/// be retrieved and used to authenticate API calls. Use `setupWithTeamTransportConfig:`, if additional customization of
/// network calling parameters is necessary. This method should be called from the app delegate.
///
/// @param appKey The app key of the third-party Dropbox API user app that will be associated with all API calls. To
/// create an app or to locate your app's app key, please visit the App Console here:
/// https://www.dropbox.com/developers/apps.
///
+ (void)setupWithTeamAppKeyDesktop:(NSString *)appKey;

///
/// Stores the team transport config info for desktop. If any access token already exists, initializes an authorized
/// shared `DBTeamClient` instance.
///
/// This method should be used in the single Dropbox user case. If any stored OAuth tokens exist, one will arbitrarily
/// be retrieved and used to authenticate API calls. You can customize some network calling parameters using the
/// different `DBTransportDefaultConfig` constructors. This method should be called from the app delegate.
///
/// @param transportConfig A wrapper around the different parameters that can be set to change network calling behavior.
///
+ (void)setupWithTeamTransportConfigDesktop:(nullable DBTransportDefaultConfig *)transportConfig;

@end

NS_ASSUME_NONNULL_END
