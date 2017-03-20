///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

@class DBTransportBaseConfig;

@interface DBTransportBaseClient : NSObject

/// The Dropbox OAuth2 access token used to make requests.
@property (nonatomic, copy) NSString * _Nullable accessToken;

/// The user agent associated with all networking requests. Used for server logging.
@property (nonatomic, readonly, copy) NSString * _Nonnull userAgent;

/// The consumer app key associated with the app that is integrating with the Dropbox API. Here, app key is used for
/// querying endpoints the have "app auth" authentication type.
@property (nonatomic, readonly, copy) NSString * _Nullable appKey;

/// The consumer app secret associated with the app that is integrating with the Dropbox API. Here, app key is used for
/// querying endpoints the have "app auth" authentication type.
@property (nonatomic, readonly, copy) NSString * _Nullable appSecret;

/// An additional authentication header field used when a team app with the appropriate permissions "performs" user API
/// actions on behalf of a team member.
@property (nonatomic, readonly, copy) NSString * _Nullable asMemberId;

///
/// Full constructor.
///
/// @param accessToken The Dropbox OAuth2 access token used to make requests.
/// @param transportConfig A wrapper around the different parameters that can be set to change network calling behavior.
/// `DBTransportDefaultConfig` offers a number of different constructors to customize networking settings.
///
/// @return An initialized instance.
///
- (nonnull instancetype)initWithAccessToken:(NSString * _Nonnull)accessToken
                            transportConfig:(DBTransportBaseConfig * _Nonnull)transportConfig;

@end
