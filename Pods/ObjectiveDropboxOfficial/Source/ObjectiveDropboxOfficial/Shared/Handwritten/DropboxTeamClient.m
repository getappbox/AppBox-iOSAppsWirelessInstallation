///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DropboxClient.h"
#import "DropboxTeamClient.h"

@implementation DropboxTeamClient

- (instancetype)initWithAccessToken:(NSString *)accessToken {
  DBTransportClient *transportClient = [[DBTransportClient alloc] initWithAccessToken:accessToken];
  self = [super initWithTransportClient:transportClient];
  if (self != nil) {
    _transportClient = transportClient;
    _accessToken = accessToken;
  }
  return self;
}

- (instancetype)initWithTransportClient:(DBTransportClient *)transportClient {
  self = [super initWithTransportClient:transportClient];
  if (self != nil) {
    _transportClient = transportClient;
    _accessToken = transportClient.accessToken;
  }
  return self;
}

- (DropboxClient *)asMember:(NSString *)memberId {
  return [[DropboxClient alloc] initWithAccessToken:self.accessToken selectUser:memberId];
}

@end
