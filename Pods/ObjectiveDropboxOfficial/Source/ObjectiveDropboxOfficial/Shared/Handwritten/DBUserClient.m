///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBTransportDefaultClient.h"
#import "DBTransportDefaultConfig.h"
#import "DBUserClient.h"

@implementation DBUserClient {
  DBTransportDefaultClient *_transportClient;
}

- (instancetype)initWithAccessToken:(NSString *)accessToken {
  return [self initWithAccessToken:accessToken transportConfig:nil];
}

- (instancetype)initAsUnauthorizedClientWithTransportConfig:(DBTransportDefaultConfig *)transportConfig {
  DBTransportDefaultClient *transportClient =
      [[DBTransportDefaultClient alloc] initWithAccessToken:nil transportConfig:transportConfig];
  if (self = [super initWithTransportClient:transportClient]) {
    _transportClient = transportClient;
  }
  return self;
}

- (instancetype)initWithAccessToken:(NSString *)accessToken
                    transportConfig:(DBTransportDefaultConfig *)transportConfig {
  DBTransportDefaultClient *transportClient =
      [[DBTransportDefaultClient alloc] initWithAccessToken:accessToken transportConfig:transportConfig];
  if (self = [super initWithTransportClient:transportClient]) {
    _transportClient = transportClient;
  }
  return self;
}

- (void)updateAccessToken:(NSString *)accessToken {
  _transportClient.accessToken = accessToken;
}

- (BOOL)isAuthorized {
  return _transportClient.accessToken != nil;
}

@end
