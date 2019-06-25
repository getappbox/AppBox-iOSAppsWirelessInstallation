///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBSerializableProtocol.h"
#import "DBTransportBaseClient.h"

@class DBRequestError;
@class DBRoute;

NS_ASSUME_NONNULL_BEGIN

/// Used by internal classes of `DBTransportBaseClient`
@interface DBTransportBaseClient (Internal)

- (NSDictionary *)headersWithRouteInfo:(NSDictionary<NSString *, NSString *> *)routeAttributes
                         serializedArg:(NSString *)serializedArg;

- (NSDictionary *)headersWithRouteInfo:(NSDictionary<NSString *, NSString *> *)routeAttributes
                         serializedArg:(NSString *)serializedArg
                       byteOffsetStart:(nullable NSNumber *)byteOffsetStart
                         byteOffsetEnd:(nullable NSNumber *)byteOffsetEnd;

+ (NSMutableURLRequest *)requestWithHeaders:(NSDictionary *)httpHeaders
                                        url:(NSURL *)url
                                    content:(nullable NSData *)content
                                     stream:(nullable NSInputStream *)stream;

- (NSURL *)urlWithRoute:(DBRoute *)route;

+ (NSData *)serializeDataWithRoute:(DBRoute *)route routeArg:(id<DBSerializable>)arg;

+ (NSString *)serializeStringWithRoute:(DBRoute *)route routeArg:(id<DBSerializable>)arg;

+ (NSString *)asciiEscapeWithString:(NSString *)string;

+ (nullable DBRequestError *)dBRequestErrorWithErrorData:(nullable NSData *)errorData
                                             clientError:(nullable NSError *)clientError
                                              statusCode:(int)statusCode
                                             httpHeaders:(nullable NSDictionary *)httpHeaders;

+ (nullable id)routeErrorWithRoute:(nullable DBRoute *)route data:(nullable NSData *)data statusCode:(int)statusCode;

+ (nullable id)routeResultWithRoute:(nullable DBRoute *)route
                               data:(nullable NSData *)data
                 serializationError:(NSError *_Nullable *_Nullable)serializationError;

+ (BOOL)statusCodeIsRouteError:(int)statusCode;

/**
 *  This method performs a lookup for the passed in @p lookupKey on the given @p headerFieldsDictionary. However, since
 *  HTTP header field keys are case insensitive, it compares the keys in the dictionary to @p lookupKey in a case
 *  insensitive way.
 *
 *  @param lookupKey              The key that we want to fetch from the header dictionary. Irrespective of case
 *  @param headerFieldsDictionary HTTP headers fiels dictionary (e.g. the result of calling allHeaderFields in an
 *                                NSHTTPURLResponse instance)
 *
 *  @return The value corresponding to the passed in @p lookupKey or nil if none is found.
 */
+ (nullable id)caseInsensitiveLookupWithKey:(nullable NSString *)lookupKey
                     headerFieldsDictionary:(nullable NSDictionary<id, id> *)headerFieldsDictionary;

+ (NSString *)sdkVersion;

+ (NSString *)defaultUserAgent;

@end

NS_ASSUME_NONNULL_END
