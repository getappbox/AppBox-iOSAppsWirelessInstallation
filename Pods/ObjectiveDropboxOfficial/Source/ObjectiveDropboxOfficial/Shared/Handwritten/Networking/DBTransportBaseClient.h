///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBCOMMONPathRoot.h"
#import <Foundation/Foundation.h>

@class DBTransportBaseConfig;
@protocol DBAccessTokenProvider;

NS_ASSUME_NONNULL_BEGIN

@interface DBTransportBaseClient : NSObject

/// The Dropbox OAuth2 access token provider used to make requests.
@property (nonatomic, readonly, nullable) id<DBAccessTokenProvider> accessTokenProvider;

/// Identifies a unique Dropbox account. Used for the multi Dropbox account case where client objects are each
/// associated with a particular Dropbox account.
@property (nonatomic, readonly, copy) NSString *tokenUid;

/// The user agent associated with all networking requests. Used for server logging.
@property (nonatomic, readonly, copy) NSString *userAgent;

/// The consumer app key associated with the app that is integrating with the Dropbox API. Here, app key is used for
/// querying endpoints the have "app auth" authentication type.
@property (nonatomic, readonly, copy, nullable) NSString *appKey;

/// The consumer app secret associated with the app that is integrating with the Dropbox API. Here, app key is used for
/// querying endpoints the have "app auth" authentication type.
@property (nonatomic, readonly, copy, nullable) NSString *appSecret;

/// An additional authentication header field used when a team app with the appropriate permissions "performs" user API
/// actions on behalf of a team member.
@property (nonatomic, readonly, copy, nullable) NSString *asMemberId;

/// The value of path root object which will be used as Dropbox-Api-Path-Root header.
@property (nonatomic, readonly, copy, nullable) DBCOMMONPathRoot *pathRoot;

/// Additional HTTP headers to be injected into each client request.
@property (nonatomic, readonly, copy, nullable) NSDictionary<NSString *, NSString *> *additionalHeaders;

/// Set YES to use a faster, experimental ASCII encoding implementation. Default = NO.
@property (atomic, class) BOOL useFastAsciiEncoding;

///
/// Convenience initializer.
///
/// @param accessToken The Dropbox OAuth2 access token used to make requests.
/// @param tokenUid Identifies a unique Dropbox account. Used for the multi Dropbox account case where client objects
/// are each associated with a particular Dropbox account.
/// @param transportConfig A wrapper around the different parameters that can be set to change network calling behavior.
/// `DBTransportDefaultConfig` offers a number of different constructors to customize networking settings.
///
/// @return An initialized instance.
///
- (instancetype)initWithAccessToken:(nullable NSString *)accessToken
                           tokenUid:(nullable NSString *)tokenUid
                    transportConfig:(DBTransportBaseConfig *)transportConfig;

///
/// Designated initializer.
///
/// @param accessTokenProvider The `DBAccessTokenProvider` that provides a Dropbox OAuth2 access token
/// used to make requests.
/// @param tokenUid Identifies a unique Dropbox account. Used for the multi Dropbox account case where client objects
/// are each associated with a particular Dropbox account.
/// @param transportConfig A wrapper around the different parameters that can be set to change network calling behavior.
/// `DBTransportDefaultConfig` offers a number of different constructors to customize networking settings.
///
/// @return An initialized instance.
///
- (instancetype)initWithAccessTokenProvider:(nullable id<DBAccessTokenProvider>)accessTokenProvider
                                   tokenUid:(nullable NSString *)tokenUid
                            transportConfig:(DBTransportBaseConfig *)transportConfig NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
