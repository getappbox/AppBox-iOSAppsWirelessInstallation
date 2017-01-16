///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBOAuth.h"
#import "DBOAuthResult.h"
#import "DropboxClient.h"
#import "DropboxClientsManager.h"
#import "DropboxTeamClient.h"

@implementation DropboxClientsManager

/// An authorized client. This will be set to `nil` if unlinked.
static DropboxClient *authorizedClient;

/// An authorized team client. This will be set to `nil` if unlinked.
static DropboxTeamClient *authorizedTeamClient;

+ (DropboxClient *)authorizedClient {
  return authorizedClient;
}

+ (void)authorizedClient:(DropboxClient *)client {
  authorizedClient = client;
}

+ (DropboxTeamClient *)authorizedTeamClient {
  return authorizedTeamClient;
}

+ (void)authorizedTeamClient:(DropboxTeamClient *)client {
  authorizedTeamClient = client;
}

+ (void)setupWithOAuthManager:(DBOAuthManager *)oAuthManager transportClient:(DBTransportClient *)transportClient {
  NSAssert(
      [DBOAuthManager sharedOAuthManager] == nil,
      @"Only call `[DropboxClientsManager setupWithAppKey]` or `[DropboxClientsManager setupWithTeamAppKey]` once");
  [DBOAuthManager sharedOAuthManager:oAuthManager];

  DBAccessToken *accessToken = [[DBOAuthManager sharedOAuthManager] getFirstAccessToken];
  [[self class] setupAuthorizedClient:accessToken transportClient:transportClient];
}

+ (void)setupWithOAuthManagerMultiUser:(DBOAuthManager *)oAuthManager
                       transportClient:(DBTransportClient *)transportClient
                              tokenUid:(NSString *)tokenUid {
  NSAssert([DBOAuthManager sharedOAuthManager] == nil, @"Only call `[DropboxClientsManager setupWithAppKeyMultiUser]` "
                                                       @"or `[DropboxClientsManager setupWithTeamAppKeyMultiUser]` "
                                                       @"once");
  [DBOAuthManager sharedOAuthManager:oAuthManager];

  DBAccessToken *accessToken = [[DBOAuthManager sharedOAuthManager] getAccessToken:tokenUid];
  [[self class] setupAuthorizedClient:accessToken transportClient:transportClient];
}

+ (void)setupWithOAuthManagerTeam:(DBOAuthManager *)oAuthManager transportClient:(DBTransportClient *)transportClient {
  NSAssert(
      [DBOAuthManager sharedOAuthManager] == nil,
      @"Only call `[DropboxClientsManager setupWithAppKey]` or `[DropboxClientsManager setupWithTeamAppKey]` once");
  [DBOAuthManager sharedOAuthManager:oAuthManager];

  DBAccessToken *accessToken = [[DBOAuthManager sharedOAuthManager] getFirstAccessToken];
  [[self class] setupAuthorizedTeamClient:accessToken transportClient:transportClient];
}

+ (void)setupWithOAuthManagerMultiUserTeam:(DBOAuthManager *)oAuthManager
                           transportClient:(DBTransportClient *)transportClient
                                  tokenUid:(NSString *)tokenUid {
  NSAssert([DBOAuthManager sharedOAuthManager] == nil, @"Only call `[DropboxClientsManager setupWithAppKeyMultiUser]` "
                                                       @"or `[DropboxClientsManager setupWithTeamAppKeyMultiUser]` "
                                                       @"once");
  [DBOAuthManager sharedOAuthManager:oAuthManager];

  DBAccessToken *accessToken = [[DBOAuthManager sharedOAuthManager] getAccessToken:tokenUid];
  [[self class] setupAuthorizedTeamClient:accessToken transportClient:transportClient];
}

+ (BOOL)reauthorizeClient:(NSString *)tokenUid {
  NSAssert([DBOAuthManager sharedOAuthManager] != nil,
           @"Call `[DropboxClientsManager setupWithAppKey]` before calling this method");

  DBAccessToken *accessToken = [[DBOAuthManager sharedOAuthManager] getAccessToken:tokenUid];
  if (accessToken) {
    [[self class] setupAuthorizedClient:accessToken transportClient:nil];
    return YES;
  }

  return NO;
}

+ (BOOL)reauthorizeTeamClient:(NSString *)tokenUid {
  NSAssert([DBOAuthManager sharedOAuthManager] != nil,
           @"Call `[DropboxClientsManager setupWithTeamAppKey]` before calling this method");

  DBAccessToken *accessToken = [[DBOAuthManager sharedOAuthManager] getAccessToken:tokenUid];
  if (accessToken) {
    [[self class] setupAuthorizedTeamClient:accessToken transportClient:nil];
    return YES;
  }

  return NO;
}

+ (void)setupAuthorizedClient:(DBAccessToken *)accessToken transportClient:(DBTransportClient *)transportClient {
  if (accessToken) {
    if (transportClient) {
      transportClient.accessToken = accessToken.accessToken;
      authorizedClient = [[DropboxClient alloc] initWithTransportClient:transportClient];
    } else {
      authorizedClient = [[DropboxClient alloc] initWithAccessToken:accessToken.accessToken];
    }
  } else {
    if (transportClient) {
      authorizedClient = [[DropboxClient alloc] initWithTransportClient:transportClient];
    }
  }
}

+ (void)setupAuthorizedTeamClient:(DBAccessToken *)accessToken transportClient:(DBTransportClient *)transportClient {
  if (accessToken) {
    if (transportClient) {
      transportClient.accessToken = accessToken.accessToken;
      authorizedTeamClient = [[DropboxTeamClient alloc] initWithTransportClient:transportClient];
    } else {
      authorizedTeamClient = [[DropboxTeamClient alloc] initWithAccessToken:accessToken.accessToken];
    }
  } else {
    if (transportClient) {
      authorizedTeamClient = [[DropboxTeamClient alloc] initWithTransportClient:transportClient];
    }
  }
}

+ (DBOAuthResult *)handleRedirectURL:(NSURL *)url {
  NSAssert([DBOAuthManager sharedOAuthManager] != nil,
           @"Call `[DropboxClientsManager setupWithAppKey]` before calling this method");

  DBOAuthResult *result = [[DBOAuthManager sharedOAuthManager] handleRedirectURL:url];

  if ([result isSuccess]) {
    if (authorizedClient) {
      authorizedClient.transportClient.accessToken = result.accessToken.accessToken;
    } else {
      [DropboxClientsManager
          authorizedClient:[[DropboxClient alloc] initWithAccessToken:result.accessToken.accessToken]];
    }
  } else if ([result isCancel]) {
    return result;
  } else if ([result isError]) {
    return result;
  }

  return result;
}

+ (DBOAuthResult *)handleRedirectURLTeam:(NSURL *)url {
  NSAssert([DBOAuthManager sharedOAuthManager] != nil,
           @"Call `[DropboxClientsManager setupWithTeamAppKey]` before calling this method");

  DBOAuthResult *result = [[DBOAuthManager sharedOAuthManager] handleRedirectURL:url];

  if ([result isSuccess]) {
    if (authorizedTeamClient) {
      authorizedTeamClient.transportClient.accessToken = result.accessToken.accessToken;
    } else {
      [DropboxClientsManager
          authorizedTeamClient:[[DropboxTeamClient alloc] initWithAccessToken:result.accessToken.accessToken]];
    }
  } else if ([result isCancel]) {
    return result;
  } else if ([result isError]) {
    return result;
  }

  return nil;
}

+ (void)unlinkClients {
  if ([DBOAuthManager sharedOAuthManager]) {
    [[DBOAuthManager sharedOAuthManager] clearStoredAccessTokens];
    [[self class] resetClients];
  }
}

+ (void)resetClients {
  if ([DropboxClientsManager authorizedClient] == nil && [DropboxClientsManager authorizedTeamClient] == nil) {
    // already unlinked
    return;
  }

  [DropboxClientsManager authorizedClient:nil];
  [DropboxClientsManager authorizedTeamClient:nil];
}

@end
