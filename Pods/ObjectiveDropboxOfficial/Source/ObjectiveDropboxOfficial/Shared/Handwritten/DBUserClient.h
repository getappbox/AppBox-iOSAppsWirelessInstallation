///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBCOMMONPathRoot.h"
#import "DBUserBaseClient.h"

@class DBTransportDefaultClient;
@class DBTransportDefaultConfig;
@protocol DBAccessTokenProvider;
@class DBAccessToken;
@class DBOAuthManager;

NS_ASSUME_NONNULL_BEGIN

///
/// Dropbox User API Client for all endpoints with auth type "user".
///
/// This is the SDK user's primary interface with the Dropbox API. Routes can be accessed via each "namespace" object in
/// the instance fields of its parent, `DBUserBaseClient`. To see a full list of the User API endpoints available,
/// please visit: https://www.dropbox.com/developers/documentation/http/documentation.
///
@interface DBUserClient : DBUserBaseClient

/// Identifies a unique Dropbox account. Used for the multi Dropbox account case where client objects are each
/// associated with a particular Dropbox account.
@property (nonatomic, readonly, copy, nullable) NSString *tokenUid;

///
/// Convenience initializer.
///
/// Uses standard network configuration parameters.
///
/// @param accessToken The Dropbox OAuth 2.0 access token used to make requests.
///
/// @return An initialized instance.
///
- (instancetype)initWithAccessToken:(NSString *)accessToken;

///
/// Convenience initializer.
///
/// @param accessToken The Dropbox OAuth 2.0 access token used to make requests.
/// @param transportConfig A wrapper around the different parameters that can be set to change network calling behavior.
/// `DBTransportDefaultConfig` offers a number of different constructors to customize networking settings.
///
/// @return An initialized instance.
///
- (instancetype)initWithAccessToken:(NSString *)accessToken
                    transportConfig:(nullable DBTransportDefaultConfig *)transportConfig;

///
/// Convenience initializer.
///
/// @param accessToken The (long-lived) Dropbox OAuth 2.0 access token used to make requests.
/// @param tokenUid Identifies a unique Dropbox account. Used for the multi Dropbox account case where client objects
/// are each associated with a particular Dropbox account.
/// @param transportConfig A wrapper around the different parameters that can be set to change network calling behavior.
/// `DBTransportDefaultConfig` offers a number of different constructors to customize networking settings.
///
/// @return An initialized instance.
///
- (instancetype)initWithAccessToken:(NSString *)accessToken
                           tokenUid:(nullable NSString *)tokenUid
                    transportConfig:(nullable DBTransportDefaultConfig *)transportConfig;

///
/// Convenience initializer.
///
/// @param accessTokenProvider A `DBAccessTokenProvider` that provides access token and token refresh functionality.
/// @param tokenUid Identifies a unique Dropbox account. Used for the multi Dropbox account case where client objects
/// are each associated with a particular Dropbox account.
/// @param transportConfig A wrapper around the different parameters that can be set to change network calling behavior.
/// `DBTransportDefaultConfig` offers a number of different constructors to customize networking settings.
///
/// @return An initialized instance.
///
- (instancetype)initWithAccessTokenProvider:(id<DBAccessTokenProvider>)accessTokenProvider
                                   tokenUid:(nullable NSString *)tokenUid
                            transportConfig:(nullable DBTransportDefaultConfig *)transportConfig;

///
/// Convenience initializer.
///
/// @param accessToken An access token object.
/// @param oauthManager The oauthManager instance.
/// @param transportConfig A wrapper around the different parameters that can be set to change network calling behavior.
/// `DBTransportDefaultConfig` offers a number of different constructors to customize networking settings.
///
/// @return An initialized instance.
///
- (instancetype)initWithAccessToken:(DBAccessToken *)accessToken
                       oauthManager:(DBOAuthManager *)oauthManager
                    transportConfig:(nullable DBTransportDefaultConfig *)transportConfig;

/// Designated initializer.
///
/// @param client A `DBTransportDefaultClient` used to make network requests.
///
/// @return An initialized instance.
///
- (instancetype)initWithTransportClient:(DBTransportDefaultClient *)client NS_DESIGNATED_INITIALIZER;

///
/// Returns a `DBUserClient` instance that can be used to make API calls with given path root value.
/// @param pathRoot Value of the path root object which will be used as Dropbox-Api-Path-Root header.
///
/// @return An initialized User API client instance.
///
- (DBUserClient *)withPathRoot:(DBCOMMONPathRoot *)pathRoot;

///
/// Returns the current access token used to make API requests.
///
- (nullable NSString *)accessToken;

///
/// Returns whether the client is authorized.
///
/// @return Whether the client currently has a non-nil OAuth 2.0 access token.
///
- (BOOL)isAuthorized;

@end

NS_ASSUME_NONNULL_END
