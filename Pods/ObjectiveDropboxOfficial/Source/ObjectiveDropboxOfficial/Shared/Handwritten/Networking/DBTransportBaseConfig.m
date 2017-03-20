///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBTransportBaseConfig.h"

@implementation DBTransportBaseConfig

- (instancetype)initWithAppKey:(NSString *)appKey userAgent:(NSString *)userAgent {
  return [self initWithAppKey:appKey appSecret:nil userAgent:userAgent];
}

- (instancetype)initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret userAgent:(NSString *)userAgent {
  return [self initWithAppKey:appKey appSecret:appSecret userAgent:userAgent asMemberId:nil];
}

- (instancetype)initWithAppKey:(NSString *)appKey
                     appSecret:(NSString *)appSecret
                     userAgent:(NSString *)userAgent
                    asMemberId:(NSString *)asMemberId {
  if (self = [super init]) {
    _userAgent = userAgent;
    _appKey = appKey;
    _appSecret = appSecret;
    _asMemberId = asMemberId;
  }
  return self;
}

@end
