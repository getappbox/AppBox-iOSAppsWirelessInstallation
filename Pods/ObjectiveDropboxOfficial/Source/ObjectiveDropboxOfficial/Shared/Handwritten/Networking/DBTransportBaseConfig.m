///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBTransportBaseConfig.h"

#import "DBSDKConstants.h"

@implementation DBTransportBaseConfig

+ (NSString *)defaultUserAgent {
  return [NSString stringWithFormat:@"%@/%@", kDBSDKDefaultUserAgentPrefix, kDBSDKVersion];
}

- (instancetype)initWithAppKey:(NSString *)appKey userAgent:(NSString *)userAgent {
  return [self initWithAppKey:appKey appSecret:nil userAgent:userAgent];
}

- (instancetype)initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret userAgent:(NSString *)userAgent {
  return [self initWithAppKey:appKey appSecret:appSecret userAgent:userAgent asMemberId:nil];
}

- (instancetype)initWithAppKey:(nullable NSString *)appKey
                     appSecret:(nullable NSString *)appSecret
                     userAgent:(nullable NSString *)userAgent
                hostnameConfig:(DBTransportBaseHostnameConfig *)hostnameConfig {
  return [self initWithAppKey:appKey
                    appSecret:appSecret
               hostnameConfig:hostnameConfig
                    userAgent:userAgent
                   asMemberId:nil
            additionalHeaders:nil];
}

- (instancetype)initWithAppKey:(NSString *)appKey
                     appSecret:(NSString *)appSecret
                     userAgent:(NSString *)userAgent
                    asMemberId:(NSString *)asMemberId {
  return
      [self initWithAppKey:appKey appSecret:appSecret userAgent:userAgent asMemberId:asMemberId additionalHeaders:nil];
}

- (instancetype)initWithAppKey:(NSString *)appKey
                     appSecret:(NSString *)appSecret
                     userAgent:(NSString *)userAgent
                    asMemberId:(NSString *)asMemberId
             additionalHeaders:(NSDictionary<NSString *, NSString *> *)additionalHeaders {
  return [self initWithAppKey:appKey
                    appSecret:appSecret
               hostnameConfig:nil
                    userAgent:userAgent
                   asMemberId:asMemberId
            additionalHeaders:additionalHeaders];
}

- (instancetype)initWithAppKey:(NSString *)appKey
                     appSecret:(NSString *)appSecret
                hostnameConfig:(DBTransportBaseHostnameConfig *)hostnameConfig
                     userAgent:(NSString *)userAgent
                    asMemberId:(NSString *)asMemberId
             additionalHeaders:(NSDictionary<NSString *, NSString *> *)additionalHeaders {
  return [self initWithAppKey:appKey
                    appSecret:appSecret
               hostnameConfig:hostnameConfig
                  redirectURL:nil
                    userAgent:userAgent
                   asMemberId:asMemberId
                     pathRoot:nil
            additionalHeaders:additionalHeaders];
}

- (instancetype)initWithAppKey:(NSString *)appKey
                     appSecret:(NSString *)appSecret
                hostnameConfig:(DBTransportBaseHostnameConfig *)hostnameConfig
                   redirectURL:(NSString *)redirectURL
                     userAgent:(NSString *)userAgent
                    asMemberId:(NSString *)asMemberId
                      pathRoot:(nullable DBCOMMONPathRoot *)pathRoot
             additionalHeaders:(NSDictionary<NSString *, NSString *> *)additionalHeaders {
  if (self = [super init]) {
    _userAgent = userAgent;
    _appKey = appKey;
    _appSecret = appSecret;
    _redirectURL = redirectURL;
    _hostnameConfig = hostnameConfig;
    _asMemberId = asMemberId;
    _pathRoot = pathRoot;
    _additionalHeaders = additionalHeaders;
  }
  return self;
}

@end
