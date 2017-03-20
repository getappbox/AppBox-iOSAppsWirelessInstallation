///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

///
/// Configuration class for `DBTransportBaseClient`.
///
@interface DBTransportBaseConfig : NSObject

/// The consumer app key associated with the app that is integrating with the Dropbox API. Here, app key is used for
/// querying endpoints the have "app auth" authentication type.
@property (nonatomic, readonly, copy) NSString * _Nullable appKey;

/// The consumer app secret associated with the app that is integrating with the Dropbox API. Here, app key is used for
/// querying endpoints the have "app auth" authentication type.
@property (nonatomic, readonly, copy) NSString * _Nullable appSecret;

/// The user agent associated with all networking requests. Used for server logging.
@property (nonatomic, readonly, copy) NSString * _Nonnull userAgent;

/// An additional authentication header field used when a team app with the appropriate permissions "performs" user API
/// actions on behalf of a team member.
@property (nonatomic, readonly, copy) NSString * _Nullable asMemberId;

///
/// Convenience constructor.
///
/// @param appKey The consumer app key associated with the app that is integrating with the Dropbox API. Here, app key
/// is used for querying endpoints the have "app auth" authentication type.
/// @param userAgent The user agent associated with all networking requests. Used for server logging.
///
/// @return An initialized instance.
///
- (nonnull instancetype)initWithAppKey:(NSString * _Nonnull)appKey userAgent:(NSString * _Nullable)userAgent;

///
/// Convenience constructor.
///
/// @param appKey The consumer app key associated with the app that is integrating with the Dropbox API. Here, app key
/// is used for querying endpoints the have "app auth" authentication type.
/// @param appSecret The consumer app secret associated with the app that is integrating with the Dropbox API. Here, app
/// key is used for querying endpoints the have "app auth" authentication type.
/// @param userAgent The user agent associated with all networking requests. Used for server logging.
///
/// @return An initialized instance.
///
- (nonnull instancetype)initWithAppKey:(NSString * _Nonnull)appKey
                             appSecret:(NSString * _Nullable)appSecret
                             userAgent:(NSString * _Nullable)userAgent;

///
/// Full constructor.
///
/// @param appKey The consumer app key associated with the app that is integrating with the Dropbox API. Here, app key
/// is used for querying endpoints the have "app auth" authentication type.
/// @param appSecret The consumer app secret associated with the app that is integrating with the Dropbox API. Here, app
/// key is used for querying endpoints the have "app auth" authentication type.
/// @param userAgent The user agent associated with all networking requests. Used for server logging.
/// @param asMemberId An additional authentication header field used when a team app with the appropriate permissions
/// "performs" user API actions on behalf of a team member.
///
/// @return An initialized instance.
///
- (nonnull instancetype)initWithAppKey:(NSString * _Nonnull)appKey
                             appSecret:(NSString * _Nullable)appSecret
                             userAgent:(NSString * _Nullable)userAgent
                            asMemberId:(NSString * _Nullable)asMemberId;

@end
