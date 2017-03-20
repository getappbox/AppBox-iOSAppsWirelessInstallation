///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBClientsManager.h"
#import "DBOAuthDesktop-macOS.h"
#import "DBOAuthResult.h"
@class DBTransportDefaultConfig;
@class NSWorkspace;
@class NSViewController;

///
/// Code with platform-specific (here, macOS) dependencies.
///
/// Extends functionality of the `DBClientsManager` class.
///
@interface DBClientsManager (DesktopAuth)

///
/// Commences OAuth desktop flow from supplied view controller.
///
/// @param sharedApplication The `NSWorkspace` with which to render the OAuth flow.
/// @param controller The `NSViewController` with which to render the OAuth flow.
/// @param openURL A wrapper around app-extension unsafe `openURL` call.
/// @param browserAuth Whether to use an external web-browser to perform authorization. If set to false, then an in-app
/// webview will be used to facilitate the auth flow. The advantage of browser auth is it is safer for the end user and
/// it can leverage existing session information, which might mean the end user can avoid re-entering their Dropbox
/// login credentials. The disadvantage of browser auth is it requires navigating outside of the current app.
///
+ (void)authorizeFromControllerDesktop:(NSWorkspace * _Nonnull)sharedApplication
                            controller:(NSViewController * _Nullable)controller
                               openURL:(void (^_Nonnull)(NSURL * _Nonnull))openURL
                           browserAuth:(BOOL)browserAuth;

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
+ (void)setupWithAppKeyDesktop:(NSString * _Nonnull)appKey;

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
+ (void)setupWithTransportConfigDesktop:(DBTransportDefaultConfig * _Nullable)transportConfig;

///
/// Stores the user app key for desktop. If an access token already exists associated with the `tokenUid` key,
/// initializes an authorized shared `DBUserClient` instance. Convenience method for
/// `setupWithTransportConfigMultiUserDesktop:`.
///
/// This method should be used in the multi Dropbox user case (i.e. when it is necessary to track multiple Dropbox
/// accounts / access tokens). Here, a token uid is supplied by the client of the SDK. If there exists an access token
/// stored with that uid as a key, it is retrieved and used to instantiate a `DBUserClient` instance. This method should
/// be called from the app delegate.
///
/// @param appKey The app key of the third-party Dropbox API user app that will be associated with all API calls. To
/// create an app or to locate your app's app key, please visit the App Console here:
/// https://www.dropbox.com/developers/apps.
/// @param tokenUid The uid of the stored access token to use. This uid is returned after a successful progression
/// through the OAuth flow (via `handleRedirectURL:`) in the `DBAccessToken` field of the `DBOAuthResult` object.
///
+ (void)setupWithAppKeyMultiUserDesktop:(NSString * _Nonnull)appKey tokenUid:(NSString * _Nullable)tokenUid;

///
/// Stores the user transport config info for desktop. If an access token already exists associated with the `tokenUid`
/// key, initializes an authorized shared `DBUserClient` instance.
///
/// This method should be used in the multi Dropbox user case (i.e. when it is necessary to track multiple Dropbox
/// accounts / access tokens). Here, a token uid is supplied by the client of the SDK. If there exists an access token
/// stored with that uid as a key, it is retrieved and used to instantiate a `DBUserClient` instance. This method should
/// be called from the app delegate.
///
/// @param transportConfig A wrapper around the different parameters that can be set to change network calling behavior.
/// @param tokenUid The uid of the stored access token to use. This uid is returned after a successful progression
/// through the OAuth flow (via `handleRedirectURL:`) in the `DBAccessToken` field of the `DBOAuthResult` object.
///
+ (void)setupWithTransportConfigMultiUserDesktop:(DBTransportDefaultConfig * _Nonnull)transportConfig
                                        tokenUid:(NSString * _Nullable)tokenUid;

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
+ (void)setupWithTeamAppKeyDesktop:(NSString * _Nonnull)appKey;

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
+ (void)setupWithTeamTransportConfigDesktop:(DBTransportDefaultConfig * _Nullable)transportConfig;

///
/// Stores the team app key for desktop. If an access token already exists associated with the `tokenUid` key,
/// initializes an authorized shared `DBTeamClient` instance. Convenience method for
/// `setupWithTeamTransportConfigMultiUserDesktop:`.
///
/// This method should be used in the multi Dropbox user case (i.e. when it is necessary to track multiple Dropbox
/// accounts / access tokens). Here, a token uid is supplied by the client of the SDK. If there exists an access token
/// stored with that uid as a key, it is retrieved and used to instantiate a `DBTeamClient` instance. This method should
/// be called from the app delegate.
///
/// @param appKey The app key of the third-party Dropbox API user app that will be associated with all API calls. To
/// create an app or to locate your app's app key, please visit the App Console here:
/// https://www.dropbox.com/developers/apps.
/// @param tokenUid The uid of the stored access token to use. This uid is returned after a successful progression
/// through the OAuth flow (via `handleRedirectURLTeam:`) in the `DBAccessToken` field of the `DBOAuthResult` object.
///
+ (void)setupWithTeamAppKeyMultiUserDesktop:(NSString * _Nonnull)appKey tokenUid:(NSString * _Nullable)tokenUid;

///
/// Stores the team transport config info for desktop. If an access token already exists associated with the `tokenUid`
/// key, initializes an authorized shared `DBTeamClient` instance.
///
/// This method should be used in the multi Dropbox user case (i.e. when it is necessary to track multiple Dropbox
/// accounts / access tokens). Here, a token uid is supplied by the client of the SDK. If there exists an access token
/// stored with that uid as a key, it is retrieved and used to instantiate a `DBTeamClient` instance. This method should
/// be called from the app delegate.
///
/// @param transportConfig A wrapper around the different parameters that can be set to change network calling behavior.
/// @param tokenUid The uid of the stored access token to use. This uid is returned after a successful progression
/// through the OAuth flow (via `handleRedirectURLTeam:`) in the `DBAccessToken` field of the `DBOAuthResult` object.
///
+ (void)setupWithTeamTransportConfigMultiUserDesktop:(DBTransportDefaultConfig * _Nullable)transportConfig
                                            tokenUid:(NSString * _Nullable)tokenUid;

@end
