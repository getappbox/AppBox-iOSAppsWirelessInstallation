///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBCOMMONPathRoot.h"
#import "DBTransportBaseHostnameConfig.h"

NS_ASSUME_NONNULL_BEGIN

///
/// Configuration class for `DBTransportBaseClient`.
///
@interface DBTransportBaseConfig : NSObject

/// The consumer app key associated with the app that is integrating with the Dropbox API. Here, app key is used for
/// querying endpoints the have "app auth" authentication type.
@property (nonatomic, readonly, copy, nullable) NSString *appKey;

/// The consumer app secret associated with the app that is integrating with the Dropbox API. Here, app key is used for
/// querying endpoints the have "app auth" authentication type.
@property (nonatomic, readonly, copy, nullable) NSString *appSecret;

/// The hostname configuration used for various networking requests.
@property (nonatomic, readonly, copy, nullable) DBTransportBaseHostnameConfig *hostnameConfig;

/// The redirect url used for oauth flow
@property (nonatomic, readonly, copy, nullable) NSString *redirectURL;

/// The user agent associated with all networking requests. Used for server logging.
@property (nonatomic, readonly, copy, nullable) NSString *userAgent;

/// An additional authentication header field used when a team app with the appropriate permissions "performs" user API
/// actions on behalf of a team member.
@property (nonatomic, readonly, copy, nullable) NSString *asMemberId;

/// The value of path root object which will be used as Dropbox-Api-Path-Root header.
@property (nonatomic, readonly, copy, nullable) DBCOMMONPathRoot *pathRoot;

/// Additional HTTP headers to be injected into each client request.
@property (nonatomic, readonly, copy, nullable) NSDictionary<NSString *, NSString *> *additionalHeaders;

/// @return A default user agent string.
+ (NSString *)defaultUserAgent;

///
/// Convenience constructor.
///
/// @param appKey The consumer app key associated with the app that is integrating with the Dropbox API. Here, app key
/// is used for querying endpoints the have "app auth" authentication type.
/// @param userAgent The user agent associated with all networking requests. Used for server logging.
///
/// @return An initialized instance.
///
- (instancetype)initWithAppKey:(nullable NSString *)appKey userAgent:(nullable NSString *)userAgent;

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
- (instancetype)initWithAppKey:(nullable NSString *)appKey
                     appSecret:(nullable NSString *)appSecret
                     userAgent:(nullable NSString *)userAgent;

///
/// Convenience constructor.
///
/// @param appKey The consumer app key associated with the app that is integrating with the Dropbox API. Here, app key
/// is used for querying endpoints the have "app auth" authentication type.
/// @param appSecret The consumer app secret associated with the app that is integrating with the Dropbox API. Here, app
/// key is used for querying endpoints the have "app auth" authentication type.
/// @param userAgent The user agent associated with all networking requests. Used for server logging.
/// @param hostnameConfig A set of custom hostnames to use for networking requests.
///
/// @return An initialized instance.
- (instancetype)initWithAppKey:(nullable NSString *)appKey
                     appSecret:(nullable NSString *)appSecret
                     userAgent:(nullable NSString *)userAgent
                hostnameConfig:(DBTransportBaseHostnameConfig *)hostnameConfig;
///
/// Convenience constructor.
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
- (instancetype)initWithAppKey:(nullable NSString *)appKey
                     appSecret:(nullable NSString *)appSecret
                     userAgent:(nullable NSString *)userAgent
                    asMemberId:(nullable NSString *)asMemberId;

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
/// @param additionalHeaders Additional HTTP headers to be injected into each client request.
///
/// @return An initialized instance.
///
- (instancetype)initWithAppKey:(nullable NSString *)appKey
                     appSecret:(nullable NSString *)appSecret
                     userAgent:(nullable NSString *)userAgent
                    asMemberId:(nullable NSString *)asMemberId
             additionalHeaders:(nullable NSDictionary<NSString *, NSString *> *)additionalHeaders;

///
/// Full constructor, with debug hostname override.
///
/// @param appKey The consumer app key associated with the app that is integrating with the Dropbox API. Here, app key
/// is used for querying endpoints the have "app auth" authentication type.
/// @param appSecret The consumer app secret associated with the app that is integrating with the Dropbox API. Here, app
/// key is used for querying endpoints the have "app auth" authentication type.
/// @param hostnameConfig A set of custom hostnames to use for networking requests. Only useful for debugging purposes.
/// @param userAgent The user agent associated with all networking requests. Used for server logging.
/// @param asMemberId An additional authentication header field used when a team app with the appropriate permissions
/// "performs" user API actions on behalf of a team member.
/// @param additionalHeaders Additional HTTP headers to be injected into each client request.
///
/// @return An initialized instance.
///
- (instancetype)initWithAppKey:(nullable NSString *)appKey
                     appSecret:(nullable NSString *)appSecret
                hostnameConfig:(nullable DBTransportBaseHostnameConfig *)hostnameConfig
                     userAgent:(nullable NSString *)userAgent
                    asMemberId:(nullable NSString *)asMemberId
             additionalHeaders:(nullable NSDictionary<NSString *, NSString *> *)additionalHeaders;

///
/// Full constructor, with debug hostname and redirectURL override.
///
/// @param appKey The consumer app key associated with the app that is integrating with the Dropbox API. Here, app key
/// is used for querying endpoints the have "app auth" authentication type.
/// @param appSecret The consumer app secret associated with the app that is integrating with the Dropbox API. Here, app
/// key is used for querying endpoints the have "app auth" authentication type.
/// @param hostnameConfig A set of custom hostnames to use for networking requests. Only useful for debugging purposes.
/// @param redirectURL The redirect url used for oauth flow.
/// @param userAgent The user agent associated with all networking requests. Used for server logging.
/// @param asMemberId An additional authentication header field used when a team app with the appropriate permissions
/// "performs" user API actions on behalf of a team member.
/// @param pathRoot The value of path root object which will be used as Dropbox-Api-Path-Root header.
/// @param additionalHeaders Additional HTTP headers to be injected into each client request.
///
/// @return An initialized instance.
///
- (instancetype)initWithAppKey:(nullable NSString *)appKey
                     appSecret:(nullable NSString *)appSecret
                hostnameConfig:(nullable DBTransportBaseHostnameConfig *)hostnameConfig
                   redirectURL:(nullable NSString *)redirectURL
                     userAgent:(nullable NSString *)userAgent
                    asMemberId:(nullable NSString *)asMemberId
                      pathRoot:(nullable DBCOMMONPathRoot *)pathRoot
             additionalHeaders:(nullable NSDictionary<NSString *, NSString *> *)additionalHeaders;

@end

NS_ASSUME_NONNULL_END
