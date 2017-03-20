///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBUserBaseClient.h"

@class DBTransportDefaultConfig;

///
/// Dropbox User API Client.
///
/// This is the SDK user's primary interface with the Dropbox API. Routes can be accessed via each "namespace" object in
/// the instance fields of its parent, `DBUserBaseClient`. To see a full list of the User API endpoints available,
/// please visit: https://www.dropbox.com/developers/documentation/http/documentation.
///
@interface DBUserClient : DBUserBaseClient

///
/// Convenience constructor.
///
/// Uses standard network configuration parameters.
///
/// @param accessToken The Dropbox OAuth2 access token used to make requests.
///
/// @return An initialized instance.
///
- (nonnull instancetype)initWithAccessToken:(NSString * _Nonnull)accessToken;

///
/// Constructor for initializing an "unauthorized" client.
///
/// This "unauthorized" client can be used to query endpoints that do not require an OAuth 2.0 access token as part of
/// the authorization.
///
/// @param transportConfig A wrapper around the different parameters that can be set to change network calling behavior.
/// `DBTransportDefaultConfig` offers a number of different constructors to customize networking settings.
///
/// @return An initialized instance.
///
- (nonnull instancetype)initAsUnauthorizedClientWithTransportConfig:(DBTransportDefaultConfig * _Nonnull)transportConfig;

///
/// Full constructor.
///
/// @param transportConfig A wrapper around the different parameters that can be set to change network calling behavior.
/// `DBTransportDefaultConfig` offers a number of different constructors to customize networking settings.
///
/// @return An initialized instance.
///
- (nonnull instancetype)initWithAccessToken:(NSString * _Nonnull)accessToken
                            transportConfig:(DBTransportDefaultConfig * _Nullable)transportConfig;

///
/// Updates access token used to make API requests.
///
/// @param accessToken The updated access token with which to make API calls.
///
- (void)updateAccessToken:(NSString * _Nonnull)accessToken;

///
/// Returns whether the client is authorized.
///
/// @return Whether the client currently has a non-nil OAuth 2.0 access token.
///
- (BOOL)isAuthorized;

@end
