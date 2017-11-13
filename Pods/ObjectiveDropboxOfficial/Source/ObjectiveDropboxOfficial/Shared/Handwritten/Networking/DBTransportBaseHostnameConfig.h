///
/// Copyright (c) 2017 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///
/// Configuration class that defines the different hostnames that the Dropbox SDK uses
///
@interface DBTransportBaseHostnameConfig : NSObject

@property (nonatomic, readonly, copy) NSString *meta;
@property (nonatomic, readonly, copy) NSString *api;
@property (nonatomic, readonly, copy) NSString *content;
@property (nonatomic, readonly, copy) NSString *notify;

///
/// Default constructor.
///
/// @return An initialized instance of hostname configurations with default values set for all hostnames
///
- (instancetype)init;

///
/// Constructor that takes in a set of custom hostnames to use for api calls.
///
/// @param meta the hostname to metaserver
/// @param api the hostname to api server
/// @param content the hostname to content server
/// @param notify the hostname to notify server
///
/// @return An initialized instance with the provided hostname configuration
///
- (instancetype)initWithMeta:(NSString *)meta api:(NSString *)api content:(NSString *)content notify:(NSString *)notify;

///
/// Returns the prefix to use for API calls to the given route type.
///
/// @param routeType the type of route to get a prefix for.
/// Currently the valid values are: "api", "content", and "notify".
///
/// @return An absolute URL prefix, typically "https://<hostname>/2" or nil if an invalid route type is provided.
///
- (nullable NSString *)apiV2PrefixWithRouteType:(NSString *)routeType;

@end

NS_ASSUME_NONNULL_END
