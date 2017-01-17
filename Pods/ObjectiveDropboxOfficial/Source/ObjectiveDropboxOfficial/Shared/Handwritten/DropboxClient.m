///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBBase.h"
#import "DBTransportClient.h"
#import "DropboxClient.h"

@implementation DropboxClient

- (instancetype)initWithAccessToken:(NSString *)accessToken {
  DBTransportClient *transportClient = [[DBTransportClient alloc] initWithAccessToken:accessToken];
  self = [super initWithTransportClient:transportClient];
  if (self != nil) {
    _transportClient = transportClient;
  }
  return self;
}

- (instancetype)initWithAccessToken:(NSString *)accessToken selectUser:(NSString *)selectUser {
  DBTransportClient *transportClient =
      [[DBTransportClient alloc] initWithAccessToken:accessToken selectUser:selectUser];
  self = [super initWithTransportClient:transportClient];
  if (self != nil) {
    _transportClient = transportClient;
  }
  return self;
}

- (instancetype)initWithTransportClient:(DBTransportClient *)transportClient {
  self = [super initWithTransportClient:transportClient];
  if (self != nil) {
    _transportClient = transportClient;
  }
  return self;
}

@end
