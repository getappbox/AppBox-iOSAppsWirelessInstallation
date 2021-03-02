///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBClientsManager.h"
#import "DBOAuthManager+Protected.h"
#import "DBOAuthResult.h"
#import "DBSDKKeychain.h"
#import "DBTeamClient.h"
#import "DBTransportDefaultClient.h"
#import "DBTransportDefaultConfig.h"
#import "DBUserClient.h"

@implementation DBClientsManager

static DBTransportDefaultConfig *s_currentTransportConfig;

static NSString *s_appKey;

/// An authorized client. This will be set to `nil` if unlinked.
static DBUserClient *s_authorizedClient;

static NSMutableDictionary<NSString *, DBUserClient *> *s_tokenUidToAuthorizedClients;

/// An authorized team client. This will be set to `nil` if unlinked.
static DBTeamClient *s_authorizedTeamClient;

static NSMutableDictionary<NSString *, DBTeamClient *> *s_tokenUidToAuthorizedTeamClients;

+ (void)initialize {
  if (self != [DBClientsManager class])
    return;

  s_tokenUidToAuthorizedClients = [NSMutableDictionary new];
  s_tokenUidToAuthorizedTeamClients = [NSMutableDictionary new];
}

+ (NSString *)appKey {
  return s_appKey;
}

+ (void)setAppKey:(NSString *)appKey {
  s_appKey = appKey;
}

+ (DBTransportDefaultConfig *)transportConfig {
  return s_currentTransportConfig;
}

+ (void)setTransportConfig:(DBTransportDefaultConfig *)transportConfig {
  s_currentTransportConfig = transportConfig;
}

+ (DBUserClient *)authorizedClient {
  @synchronized(self) {
    return s_authorizedClient;
  }
}

+ (NSDictionary<NSString *, DBUserClient *> *)authorizedClients {
  @synchronized(self) {
    // return shallow copy
    return [NSMutableDictionary dictionaryWithDictionary:s_tokenUidToAuthorizedClients];
  }
}

+ (DBTeamClient *)authorizedTeamClient {
  @synchronized(self) {
    return s_authorizedTeamClient;
  }
}

+ (NSDictionary<NSString *, DBTeamClient *> *)authorizedTeamClients {
  @synchronized(self) {
    // return shallow copy
    return [NSMutableDictionary dictionaryWithDictionary:s_tokenUidToAuthorizedTeamClients];
  }
}

+ (BOOL)authorizeClientFromKeychain:(NSString *)tokenUid {
  NSAssert([DBOAuthManager sharedOAuthManager],
           @"Call the appropriate `[DBClientsManager setupWith...]` before calling this method");

  DBAccessToken *accessToken = [[DBOAuthManager sharedOAuthManager] retrieveAccessToken:tokenUid];
  if (accessToken) {
    [self db_addAuthorizedClientWithToken:accessToken setAsDefault:YES];
    return YES;
  }
  return NO;
}

+ (BOOL)authorizeTeamClientFromKeychain:(NSString *)tokenUid {
  NSAssert([DBOAuthManager sharedOAuthManager],
           @"Call the appropriate `[DBClientsManager setupWith...]` before calling this method");

  DBAccessToken *accessToken = [[DBOAuthManager sharedOAuthManager] retrieveAccessToken:tokenUid];
  if (accessToken) {
    [self db_addAuthorizedTeamClientWithToken:accessToken setAsDefault:YES];
    return YES;
  }
  return NO;
}

+ (void)setupWithOAuthManager:(DBOAuthManager *)oAuthManager
              transportConfig:(DBTransportDefaultConfig *)transportConfig {
  NSAssert(![DBOAuthManager sharedOAuthManager], @"Only call `[DBClientsManager setupWith...]` once");

  [self db_setupHelperWithOAuthManager:oAuthManager transportConfig:transportConfig];
  [self db_setupAuthorizedClients];
}

+ (void)setupWithOAuthManagerTeam:(DBOAuthManager *)oAuthManager
                  transportConfig:(DBTransportDefaultConfig *)transportConfig {
  NSAssert(![DBOAuthManager sharedOAuthManager], @"Only call `[DBClientsManager setupWith...]` once");

  [self db_setupHelperWithOAuthManager:oAuthManager transportConfig:transportConfig];
  [self db_setupAuthorizedTeamClients];
}

+ (BOOL)handleRedirectURL:(NSURL *)url completion:(DBOAuthCompletion)completion {
  return [self db_handleRedirectURL:url isTeam:NO completion:completion];
}

+ (BOOL)handleRedirectURLTeam:(NSURL *)url completion:(DBOAuthCompletion)completion {
  return [self db_handleRedirectURL:url isTeam:YES completion:completion];
}

+ (void)unlinkAndResetClient:(NSString *)tokenUid {
  if ([DBOAuthManager sharedOAuthManager]) {
    [[DBOAuthManager sharedOAuthManager] clearStoredAccessToken:tokenUid];
    [self db_resetClient:tokenUid];
  }
}

+ (void)unlinkAndResetClients {
  if ([DBOAuthManager sharedOAuthManager]) {
    [[DBOAuthManager sharedOAuthManager] clearStoredAccessTokens];
    [self db_resetClients];
  }
}

+ (BOOL)checkAndPerformV1TokenMigration:(DBTokenMigrationResponseBlock)responseBlock
                                  queue:(NSOperationQueue *)queue
                                 appKey:(NSString *)appKey
                              appSecret:(NSString *)appSecret {
  return [DBSDKKeychain checkAndPerformV1TokenMigration:responseBlock queue:queue appKey:appKey appSecret:appSecret];
}

#pragma mark Private helpers

+ (void)db_addAuthorizedClientWithToken:(DBAccessToken *)token setAsDefault:(BOOL)setAsDefault {
  id<DBAccessTokenProvider> tokenProvider = [[DBOAuthManager sharedOAuthManager] accessTokenProviderForToken:token];
  DBUserClient *client = [[DBUserClient alloc] initWithAccessTokenProvider:tokenProvider
                                                                  tokenUid:token.uid
                                                           transportConfig:[self transportConfig]];
  [self db_addAuthorizedClient:client tokenUid:token.uid setAsDefault:setAsDefault];
}

+ (void)db_setAuthorizedClient:(DBUserClient *)client {
  @synchronized(self) {
    s_authorizedClient = client;
  }
}

+ (void)db_addAuthorizedClient:(DBUserClient *)client tokenUid:(NSString *)tokenUid setAsDefault:(BOOL)setAsDefault {
  @synchronized(self) {
    s_tokenUidToAuthorizedClients[tokenUid] = client;
    if (setAsDefault) {
      [self db_setAuthorizedClient:client];
    }
  }
}

+ (void)db_addAuthorizedTeamClientWithToken:(DBAccessToken *)token setAsDefault:(BOOL)setAsDefault {
  if (![DBOAuthManager sharedOAuthManager]) {
    return;
  }

  id<DBAccessTokenProvider> tokenProvider = [[DBOAuthManager sharedOAuthManager] accessTokenProviderForToken:token];
  DBTeamClient *client = [[DBTeamClient alloc] initWithAccessTokenProvider:tokenProvider
                                                                  tokenUid:token.uid
                                                           transportConfig:[self transportConfig]];
  [self db_addAuthorizedTeamClient:client tokenUid:token.uid setAsDefault:setAsDefault];
}

+ (void)db_setAuthorizedTeamClient:(DBTeamClient *)client {
  @synchronized(self) {
    s_authorizedTeamClient = client;
  }
}

+ (void)db_addAuthorizedTeamClient:(DBTeamClient *)client
                          tokenUid:(NSString *)tokenUid
                      setAsDefault:(BOOL)setAsDefault {
  @synchronized(self) {
    s_tokenUidToAuthorizedTeamClients[tokenUid] = client;
    if (setAsDefault) {
      [self db_setAuthorizedTeamClient:client];
    }
  }
}

+ (DBUserClient *)db_authorizedClient:(NSString *)tokenUid {
  @synchronized(self) {
    return s_tokenUidToAuthorizedClients[tokenUid];
  }
}

+ (DBTeamClient *)db_authorizedTeamClient:(NSString *)tokenUid {
  @synchronized(self) {
    return s_tokenUidToAuthorizedTeamClients[tokenUid];
  }
}

+ (void)db_removeAuthorizedClient:(NSString *)tokenUid {
  @synchronized(self) {
    [s_tokenUidToAuthorizedClients removeObjectForKey:tokenUid];
  }
}

+ (void)db_removeAuthorizedTeamClient:(NSString *)tokenUid {
  @synchronized(self) {
    [s_tokenUidToAuthorizedTeamClients removeObjectForKey:tokenUid];
  }
}

+ (void)db_removeAllAuthorizedClients {
  @synchronized(self) {
    [s_tokenUidToAuthorizedClients removeAllObjects];
  }
}

+ (void)db_removeAllAuthorizedTeamClients {
  @synchronized(self) {
    [s_tokenUidToAuthorizedTeamClients removeAllObjects];
  }
}

+ (void)db_setupHelperWithOAuthManager:(DBOAuthManager *)oAuthManager
                       transportConfig:(DBTransportDefaultConfig *)transportConfig {
  [DBOAuthManager setSharedOAuthManager:oAuthManager];
  [self setTransportConfig:transportConfig];
  [self setAppKey:transportConfig.appKey];
}

+ (void)db_setupAuthorizedClients {
  NSArray<DBAccessToken *> *accessTokens = [[[DBOAuthManager sharedOAuthManager] retrieveAllAccessTokens] allValues];
  for (NSUInteger i = 0; i < accessTokens.count; i++) {
    [self db_addAuthorizedClientWithToken:accessTokens[i] setAsDefault:i == 0];
  }
}

+ (void)db_setupAuthorizedTeamClients {
  NSArray<DBAccessToken *> *accessTokens = [[[DBOAuthManager sharedOAuthManager] retrieveAllAccessTokens] allValues];
  for (NSUInteger i = 0; i < accessTokens.count; i++) {
    [self db_addAuthorizedTeamClientWithToken:accessTokens[i] setAsDefault:i == 0];
  }
}

+ (void)db_resetClients {
  [DBClientsManager db_setAuthorizedClient:nil];
  [DBClientsManager db_setAuthorizedTeamClient:nil];

  [DBClientsManager db_removeAllAuthorizedClients];
  [DBClientsManager db_removeAllAuthorizedTeamClients];
}

+ (void)db_resetClient:(NSString *)tokenUid {
  BOOL shouldResetDefaultUserClient = [self db_authorizedClient:tokenUid] == [DBClientsManager authorizedClient];
  [self db_removeAuthorizedClient:tokenUid];
  if (shouldResetDefaultUserClient) {
    [DBClientsManager db_setAuthorizedClient:nil];

    NSDictionary<NSString *, DBUserClient *> *authorizedClientsCopy = [DBClientsManager authorizedClients];

    if ([authorizedClientsCopy count] > 0) {
      NSString *firstUid = [authorizedClientsCopy allKeys][0];
      [DBClientsManager db_setAuthorizedClient:authorizedClientsCopy[firstUid]];
    }
  }

  BOOL shouldResetDefaultTeamClient =
      [self db_authorizedTeamClient:tokenUid] == [DBClientsManager authorizedTeamClient];
  [self db_removeAuthorizedTeamClient:tokenUid];
  if (shouldResetDefaultTeamClient) {
    [DBClientsManager db_setAuthorizedTeamClient:nil];

    NSDictionary<NSString *, DBTeamClient *> *authorizedTeamClientsCopy = [DBClientsManager authorizedTeamClients];

    if ([authorizedTeamClientsCopy count] > 0) {
      NSString *firstUid = [authorizedTeamClientsCopy allKeys][0];
      [DBClientsManager db_setAuthorizedTeamClient:authorizedTeamClientsCopy[firstUid]];
    }
  }
}

+ (BOOL)db_handleRedirectURL:(NSURL *)url isTeam:(BOOL)isTeam completion:(DBOAuthCompletion)completion {
  NSAssert([DBOAuthManager sharedOAuthManager],
           @"Call the appropriate `[DBClientsManager setupWith...]` before calling this method");

  return [[DBOAuthManager sharedOAuthManager]
      handleRedirectURL:url
             completion:^(DBOAuthResult *result) {
               if ([result isSuccess]) {
                 DBAccessToken *token = result.accessToken;
                 if (isTeam) {
                   [self db_addAuthorizedTeamClientWithToken:token setAsDefault:YES];
                 } else {
                   [self db_addAuthorizedClientWithToken:token setAsDefault:YES];
                 }
               }
               completion(result);
             }];
}

@end
