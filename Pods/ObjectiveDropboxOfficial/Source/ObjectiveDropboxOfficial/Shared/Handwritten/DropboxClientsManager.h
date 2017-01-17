///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

@class DropboxClient;
@class DropboxTeamClient;
@class DBOAuthResult;
@class DBTransportClient;

///
/// Dropbox Clients Manager.
///
/// This is a convenience class for the typical single user case.
///
/// To use this class, see details in the tutorial at:
/// https://github.com/dropbox/dropbox-sdk-obj-c/blob/master/README.md.
///
@interface DropboxClientsManager : NSObject

///
/// Accessor method for `DropboxClient` shared instance.
///
/// @return The `DropboxClient` shared instance.
///
+ (DropboxClient * _Nullable)authorizedClient;

///
/// Mutator method for `DropboxClient` shared instance.
///
/// @param client The updated reference to the `DropboxClient` shared
/// instance.
///
+ (void)authorizedClient:(DropboxClient * _Nullable)client;

///
/// Accessor method for `DropboxTeamClient` shared instance.
///
/// @return The `DropboxTeamClient` shared instance.
///
+ (DropboxTeamClient * _Nullable)authorizedTeamClient;

///
/// Mutator method for `DropboxTeamClient` shared instance.
///
/// @param client The updated reference to the `DropboxTeamClient` shared
/// instance.
///
+ (void)authorizedTeamClient:(DropboxTeamClient * _Nullable)client;

///
/// Reauthorizes shared user client instance with the access token retrieved from storage
/// via the supplied `tokenUid`.
///
/// In the multi Dropbox user case, this method should be called when authorizing a new user
/// after application has initially launched. For example, if an initially authorized user
/// is logged out and the app is not shutdown, and a new user is to be authorized via a
/// pre-existing access token, this method should be called.
///
/// @param tokenUid The uid of the stored access token to use to reauthorize. This uid is returned
/// after a successful progression through the OAuth flow (via `handleRedirectURL` or
/// `handleRedirectURLTeam`) in the `DBAccessToken` field of the `DBOAuthResult` object.
///
/// @returns Whether a valid token exists in storage for the supplied `tokenUid`.
///
+ (BOOL)reauthorizeClient:(NSString * _Nullable)tokenUid;

///
/// Reauthorizes shared team client instance with the access token retrieved from storage
/// via the supplied `tokenUid`.
///
/// In the multi Dropbox user case, this method should be called when authorizing a new user
/// after application has initially launched. For example, if an initially authorized user
/// is logged out and the app is not shutdown, and a new user is to be authorized via a
/// pre-existing access token, this method should be called.
///
/// @param tokenUid The uid of the stored access token to use to reauthorize. This uid is returned
/// after a successful progression through the OAuth flow (via `handleRedirectURL` or
/// `handleRedirectURLTeam`) in the `DBAccessToken` field of the `DBOAuthResult` object.
///
/// @returns Whether a valid token exists in storage for the supplied `tokenUid`.
///
+ (BOOL)reauthorizeTeamClient:(NSString * _Nullable)tokenUid;

///
/// Handles launching the SDK with a redirect url from an external source.
///
/// Used after OAuth authentication has completed. A `DropboxClient` instance
/// is initialized and the response access token is saved in the `DBKeychain`
/// class.
///
/// @param url The auth redirect url which relaunches the SDK.
///
/// @return The `DBOAuthResult` result from the authorization attempt.
///
+ (DBOAuthResult * _Nullable)handleRedirectURL:(NSURL * _Nonnull)url;

///
/// Handles launching the SDK with a redirect url from an external source.
///
/// Used after OAuth authentication has completed. A `DropboxTeamClient` instance
/// is initialized and the response access token is saved in the `DBKeychain`
/// class.
///
/// @param url The auth redirect url which relaunches the SDK.
///
/// @return The `DBOAuthResult` result from the authorization attempt.
///
+ (DBOAuthResult * _Nullable)handleRedirectURLTeam:(NSURL * _Nonnull)url;

///
/// "Unlinks" the active user / team client (or both) and clears all stored
/// access tokens in `DBKeychain`.
///
+ (void)unlinkClients;

///
/// Only "unlinks" the active user / team client (or both) but does not clear any stored
/// access tokens in `DBKeychain`.
///
+ (void)resetClients;

@end
