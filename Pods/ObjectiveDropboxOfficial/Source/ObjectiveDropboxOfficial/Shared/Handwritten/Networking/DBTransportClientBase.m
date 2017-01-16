//
//  DBTransportClientBase.m
//  ObjectiveDropboxOfficial
//
//  Created by Stephen Cobbe on 12/1/16.
//  Copyright © 2016 Dropbox. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DBAUTHAccessError.h"
#import "DBAUTHAuthError.h"
#import "DBAUTHRateLimitError.h"
#import "DBRequestErrors.h"
#import "DBStoneBase.h"
#import "DBTransportClientBase.h"

static NSString const * _Nonnull const kVersion = @"2.0.6";
static NSString const *const kDefaultUserAgentPrefix = @"OfficialDropboxObjCSDKv2";
NSDictionary<NSString *, NSString *> *baseHosts = nil;

#pragma mark - Internal serialization helpers

@implementation DBTransportClientBase

+ (void)initialize {
  baseHosts = @{
    @"api" : @"https://api.dropbox.com/2",
    @"content" : @"https://api-content.dropbox.com/2",
    @"notify" : @"https://notify.dropboxapi.com/2",
  };
}

- (instancetype)init:(NSString *)selectUser
           userAgent:(NSString *)userAgent
              appKey:(NSString *)appKey
           appSecret:(NSString *)appSecret {
  self = [super init];
  if (self) {
    NSString *defaultUserAgent = [NSString stringWithFormat:@"%@/%@", kDefaultUserAgentPrefix, kVersion];

    _selectUser = selectUser;
    _userAgent = userAgent ? [[userAgent stringByAppendingString:@"/"] stringByAppendingString:defaultUserAgent]
                           : defaultUserAgent;
    _appKey = appKey;
    _appSecret = appSecret;
  }
  return self;
}

- (NSDictionary *)headersWithRouteInfo:(NSDictionary<NSString *, NSString *> *)routeAttributes
                           accessToken:(NSString *)accessToken
                         serializedArg:(NSString *)serializedArg {
  NSString *routeStyle = routeAttributes[@"style"];
  NSString *routeHost = routeAttributes[@"host"];
  NSString *routeAuth = routeAttributes[@"auth"];

  NSMutableDictionary<NSString *, NSString *> *headers = [[NSMutableDictionary alloc] init];
  [headers setObject:_userAgent forKey:@"User-Agent"];

  BOOL noauth = [routeHost isEqualToString:@"notify"];

  if (!noauth) {
    if (_selectUser) {
      [headers setObject:_selectUser forKey:@"Dropbox-Api-Select-User"];
    }

    if (routeAuth && [routeAuth isEqualToString:@"app"]) {
      if (!_appKey || !_appSecret) {
        NSLog(@"App key and/or secret not properly configured. Use custom `DBTransportClient` instance to set.");
      }
      NSString *authString = [NSString stringWithFormat:@"%@:%@", _appKey, _appSecret];
      NSData *authData = [authString dataUsingEncoding:NSUTF8StringEncoding];
      [headers setObject:[NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:0]]
                  forKey:@"Authorization"];
    } else {
      [headers setObject:[NSString stringWithFormat:@"Bearer %@", accessToken] forKey:@"Authorization"];
    }
  }

  if ([routeStyle isEqualToString:@"rpc"]) {
    if (serializedArg) {
      [headers setObject:@"application/json" forKey:@"Content-Type"];
    }
  } else if ([routeStyle isEqualToString:@"upload"]) {
    [headers setObject:@"application/octet-stream" forKey:@"Content-Type"];
    if (serializedArg) {
      [headers setObject:serializedArg forKey:@"Dropbox-API-Arg"];
    }
  } else if ([routeStyle isEqualToString:@"download"]) {
    if (serializedArg) {
      [headers setObject:serializedArg forKey:@"Dropbox-API-Arg"];
    }
  }

  return headers;
}

+ (NSURLRequest *)requestWithHeaders:(NSDictionary *)httpHeaders
                                 url:(NSURL *)url
                             content:(NSData *)content
                              stream:(NSInputStream *)stream {
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
  for (NSString *key in httpHeaders) {
    [request addValue:httpHeaders[key] forHTTPHeaderField:key];
  }
  request.HTTPMethod = @"POST";
  if (content) {
    request.HTTPBody = content;
  }
  if (stream) {
    request.HTTPBodyStream = stream;
  }
  return request;
}

+ (NSURL *)urlWithRoute:(DBRoute *)route {
  return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@", baseHosts[route.attrs[@"host"]], route.namespace_,
                                                         route.name]];
}

+ (NSData *)serializeArgData:(DBRoute *)route routeArg:(id<DBSerializable>)arg {
  if (!arg) {
    return nil;
  }

  if (route.arraySerialBlock) {
    NSArray *serializedArray = route.arraySerialBlock(arg);
    return [[self class] jsonDataWithJsonObj:serializedArray];
  }

  NSDictionary *serializedDict = [[arg class] serialize:arg];
  return [[self class] jsonDataWithJsonObj:serializedDict];
}

+ (NSString *)serializeArgString:(DBRoute *)route routeArg:(id<DBSerializable>)arg {
  if (!arg) {
    return nil;
  }
  NSData *jsonData = [self serializeArgData:route routeArg:arg];
  NSString *asciiEscapedStr = [[self class] asciiEscapeWithString:[[self class] utf8StringWithData:jsonData]];
  NSMutableString *filteredStr = [[NSMutableString alloc] initWithString:asciiEscapedStr];
  [filteredStr replaceOccurrencesOfString:@"\\/"
                               withString:@"/"
                                  options:NSLiteralSearch
                                    range:NSMakeRange(0, [filteredStr length])];
  return filteredStr;
}

+ (NSData *)jsonDataWithJsonObj:(id)jsonObj {
  if (!jsonObj) {
    return nil;
  }

  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObj options:0 error:&error];

  if (!jsonData) {
    NSLog(@"Error serializing dictionary: %@", error.localizedDescription);
    return nil;
  } else {
    return jsonData;
  }
}

+ (NSString *)utf8StringWithData:(NSData *)jsonData {
  return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

+ (NSString *)asciiEscapeWithString:(NSString *)string {
  NSMutableString *result = [[NSMutableString alloc] init];
  for (NSUInteger i = 0; i < string.length; i++) {
    NSString *substring = [string substringWithRange:NSMakeRange(i, 1)];
    if ([substring canBeConvertedToEncoding:NSASCIIStringEncoding]) {
      [result appendString:substring];
    } else {
      [result appendFormat:@"\\u%04x", [string characterAtIndex:i]];
    }
  }
  return result;
}

+ (DBRequestError *)dBRequestErrorWithErrorData:(NSData *)errorData
                                    clientError:(NSError *)clientError
                                     statusCode:(int)statusCode
                                    httpHeaders:(NSDictionary *)httpHeaders {
  DBRequestError *dbxError;

  if (clientError) {
    return [[DBRequestError alloc] initAsClientError:clientError];
  }

  if (statusCode == 200) {
    return nil;
  }

  NSDictionary *deserializedData = [self deserializeHttpData:errorData];

  NSString *requestId = httpHeaders[@"X-Dropbox-Request-Id"];
  NSString *errorContent;
  if (deserializedData) {
    if (deserializedData[@"error_summary"]) {
      errorContent = deserializedData[@"error_summary"];
    } else if (deserializedData[@"error"]) {
      errorContent = deserializedData[@"error"];
    } else {
      errorContent = errorData ? [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding] : nil;
    }
  } else {
    errorContent = errorData ? [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding] : nil;
  }

  if (statusCode >= 500 && statusCode < 600) {
    dbxError =
        [[DBRequestError alloc] initAsInternalServerError:requestId statusCode:@(statusCode) errorContent:errorContent];
  } else if (statusCode == 400) {
    dbxError =
        [[DBRequestError alloc] initAsBadInputError:requestId statusCode:@(statusCode) errorContent:errorContent];
  } else if (statusCode == 401) {
    DBAUTHAuthError *authError = [DBAUTHAuthErrorSerializer deserialize:deserializedData[@"error"]];
    dbxError = [[DBRequestError alloc] initAsAuthError:requestId
                                            statusCode:@(statusCode)
                                          errorContent:errorContent
                                   structuredAuthError:authError];
  } else if (statusCode == 403) {
    DBAUTHAccessError *accessError = [DBAUTHAccessErrorSerializer deserialize:deserializedData[@"error"]];
    dbxError = [[DBRequestError alloc] initAsAccessError:requestId
                                              statusCode:@(statusCode)
                                            errorContent:errorContent
                                   structuredAccessError:accessError];
  } else if (statusCode == 429) {
    DBAUTHRateLimitError *rateLimitError = [DBAUTHRateLimitErrorSerializer deserialize:deserializedData[@"error"]];
    NSString *retryAfter = httpHeaders[@"Retry-After"];
    double retryAfterSeconds = retryAfter.doubleValue;
    dbxError = [[DBRequestError alloc] initAsRateLimitError:requestId
                                                 statusCode:@(statusCode)
                                               errorContent:errorContent
                                   structuredRateLimitError:rateLimitError
                                                    backoff:@(retryAfterSeconds)];
  } else if ([[self class] statusCodeIsRouteError:statusCode]) {
    dbxError = [[DBRequestError alloc] initAsHttpError:requestId statusCode:@(statusCode) errorContent:errorContent];
  } else {
    dbxError = [[DBRequestError alloc] initAsHttpError:requestId statusCode:@(statusCode) errorContent:errorContent];
  }

  return dbxError;
}

+ (id)routeErrorWithRouteData:(DBRoute *)route data:(NSData *)data statusCode:(int)statusCode {
  if (!data) {
    return nil;
  }
  id routeError;
  NSDictionary *deserializedData = [self deserializeHttpData:data];
  if ([[self class] statusCodeIsRouteError:statusCode]) {
    routeError = [route.errorType deserialize:deserializedData[@"error"]];
  }
  return routeError;
}

+ (NSDictionary *)deserializeHttpData:(NSData *)data {
  if (!data) {
    return nil;
  }
  NSError *error;
  return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
}

+ (id)routeResultWithRouteData:(DBRoute *)route data:(NSData *)data serializationError:(NSError **)serializationError {
  if (!route.resultType) {
    return nil;
  }
  id jsonData =
      [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:serializationError];
  if (*serializationError) {
    return nil;
  }

  if (route.resultType) {
    if (route.arrayDeserialBlock) {
      return route.arrayDeserialBlock(jsonData);
    }
    return [(Class)route.resultType deserialize:jsonData];
  }

  return nil;
}

+ (BOOL)statusCodeIsRouteError:(int)statusCode {
  return statusCode == 409;
}

+ (NSString *)caseInsensitiveLookup:(NSString *)lookupKey dictionary:(NSDictionary<id, id> *)dictionary {
  for (id key in dictionary) {
    NSString *keyString = (NSString *)key;
    if ([keyString.lowercaseString isEqualToString:lookupKey.lowercaseString]) {
      return (NSString *)dictionary[key];
    }
  }
  return nil;
}

@end
