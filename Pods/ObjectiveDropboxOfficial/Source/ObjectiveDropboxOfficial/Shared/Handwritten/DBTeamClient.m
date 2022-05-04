///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBTeamClient.h"

#import "DBAccessTokenProvider.h"
#import "DBOAuthManager+Protected.h"
#import "DBTransportDefaultClient.h"
#import "DBTransportDefaultConfig.h"
#import "DBUserClient.h"

@implementation DBTeamClient

- (instancetype)initWithAccessToken:(NSString *)accessToken {
  return [self initWithAccessToken:accessToken transportConfig:nil];
}

- (instancetype)initWithAccessToken:(NSString *)accessToken
                    transportConfig:(DBTransportDefaultConfig *)transportConfig {
  return [self initWithAccessToken:accessToken tokenUid:nil transportConfig:transportConfig];
}

- (instancetype)initWithAccessToken:(NSString *)accessToken
                           tokenUid:(NSString *)tokenUid
                    transportConfig:(DBTransportDefaultConfig *)transportConfig {
  DBTransportDefaultClient *transportClient = [[DBTransportDefaultClient alloc] initWithAccessToken:accessToken
                                                                                           tokenUid:tokenUid
                                                                                    transportConfig:transportConfig];
  return [self initWithTransportClient:transportClient];
}

- (instancetype)initWithAccessTokenProvider:(id<DBAccessTokenProvider>)accessTokenProvider
                                   tokenUid:(NSString *)tokenUid
                            transportConfig:(DBTransportDefaultConfig *)transportConfig {
  DBTransportDefaultClient *transportClient =
      [[DBTransportDefaultClient alloc] initWithAccessTokenProvider:accessTokenProvider
                                                           tokenUid:tokenUid
                                                    transportConfig:transportConfig];
  return [self initWithTransportClient:transportClient];
}

- (instancetype)initWithAccessToken:(DBAccessToken *)accessToken
                       oauthManager:(DBOAuthManager *)oauthManager
                    transportConfig:(DBTransportDefaultConfig *)transportConfig {
  NSCParameterAssert(oauthManager);
  NSCParameterAssert(accessToken);

  id<DBAccessTokenProvider> tokenProvider = [oauthManager accessTokenProviderForToken:accessToken];

  DBTransportDefaultClient *transportClient =
      [[DBTransportDefaultClient alloc] initWithAccessTokenProvider:tokenProvider
                                                           tokenUid:accessToken.uid
                                                    transportConfig:transportConfig];
  return [self initWithTransportClient:transportClient];
}

- (instancetype)initWithTransportClient:(DBTransportDefaultClient *)client {
  if (self = [super initWithTransportClient:client]) {
    _tokenUid = client.tokenUid;
  }
  return self;
}

- (NSString *)accessToken {
  return _transportClient.accessTokenProvider.accessToken;
}

- (BOOL)isAuthorized {
  return _transportClient.accessTokenProvider != nil;
}

- (DBUserClient *)userClientWithMemberId:(NSString *)memberId {
  DBTransportDefaultConfig *transportConfig = nil;
  if ([_transportClient isKindOfClass:[DBTransportDefaultClient class]]) {
    transportConfig = [(DBTransportDefaultClient *)_transportClient duplicateTransportConfigWithAsMemberId:memberId];
  }
  return [[DBUserClient alloc] initWithAccessTokenProvider:_transportClient.accessTokenProvider
                                                  tokenUid:_tokenUid
                                           transportConfig:transportConfig];
}

@end
