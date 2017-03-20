///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBTransportBaseClient.h"

/// Used by internal classes of `DBTransportBaseClient`
@interface DBTransportBaseClient (Internal)

- (NSDictionary * _Nonnull)headersWithRouteInfo:(NSDictionary<NSString *, NSString *> * _Nonnull)routeAttributes
                                   accessToken:(NSString * _Nonnull)accessToken
                                 serializedArg:(NSString * _Nonnull)serializedArg;

- (NSDictionary * _Nonnull)headersWithRouteInfo:(NSDictionary<NSString *, NSString *> * _Nonnull)routeAttributes
                                   accessToken:(NSString * _Nonnull)accessToken
                                 serializedArg:(NSString * _Nonnull)serializedArg
                               byteOffsetStart:(NSNumber * _Nullable)byteOffsetStart
                                 byteOffsetEnd:(NSNumber * _Nullable)byteOffsetEnd;

+ (NSURLRequest * _Nonnull)requestWithHeaders:(NSDictionary * _Nonnull)httpHeaders
                                         url:(NSURL * _Nonnull)url
                                     content:(NSData * _Nullable)content
                                      stream:(NSInputStream * _Nullable)stream;

+ (NSURL * _Nonnull)urlWithRoute:(DBRoute * _Nonnull)route;

+ (NSData * _Nonnull)serializeDataWithRoute:(DBRoute * _Nonnull)route routeArg:(id<DBSerializable> _Nonnull)arg;

+ (NSString * _Nonnull)serializeStringWithRoute:(DBRoute * _Nonnull)route routeArg:(id<DBSerializable> _Nonnull)arg;

+ (DBRequestError * _Nullable)dBRequestErrorWithErrorData:(NSData * _Nullable)errorData
                                             clientError:(NSError * _Nullable)clientError
                                              statusCode:(int)statusCode
                                             httpHeaders:(NSDictionary * _Nullable)httpHeaders;

+ (id _Nullable)routeErrorWithRoute:(DBRoute * _Nullable)route data:(NSData * _Nullable)data statusCode:(int)statusCode;

+ (id _Nullable)routeResultWithRoute:(DBRoute * _Nullable)route
                                data:(NSData * _Nullable)data
                  serializationError:(NSError * _Nullable * _Nullable)serializationError;

+ (BOOL)statusCodeIsRouteError:(int)statusCode;

+ (NSString * _Nullable)caseInsensitiveLookupWithKey:(NSString * _Nullable)lookupKey
                                         dictionary:(NSDictionary<id, id> * _Nullable)dictionary;

+ (NSString * _Nonnull)sdkVersion;

+ (NSString * _Nonnull)defaultUserAgent;

@end
