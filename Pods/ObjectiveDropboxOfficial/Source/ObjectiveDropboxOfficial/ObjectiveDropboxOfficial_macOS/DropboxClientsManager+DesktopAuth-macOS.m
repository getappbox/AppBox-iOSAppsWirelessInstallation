///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <AppKit/AppKit.h>

#import "DBOAuth.h"
#import "DBOAuthDesktop-macOS.h"
#import "DBTransportClient.h"
#import "DropboxClientsManager.h"

@interface DropboxClientsManager ()

+ (void)setupWithOAuthManager:(DBOAuthManager * _Nonnull)oAuthManager
              transportClient:(DBTransportClient * _Nonnull)transportClient;

+ (void)setupWithOAuthManagerMultiUser:(DBOAuthManager * _Nonnull)oAuthManager
                       transportClient:(DBTransportClient * _Nonnull)transportClient
                              tokenUid:(NSString * _Nullable)tokenUid;

+ (void)setupWithOAuthManagerTeam:(DBOAuthManager * _Nonnull)oAuthManager
                  transportClient:(DBTransportClient * _Nonnull)transportClient;

+ (void)setupWithOAuthManagerMultiUserTeam:(DBOAuthManager * _Nonnull)oAuthManager
                           transportClient:(DBTransportClient * _Nonnull)transportClient
                                  tokenUid:(NSString * _Nullable)tokenUid;

@end

@implementation DropboxClientsManager (DesktopAuth)

+ (void)authorizeFromControllerDesktop:(NSWorkspace *)sharedApplication
                            controller:(NSViewController *)controller
                               openURL:(void (^_Nonnull)(NSURL *))openURL
                           browserAuth:(BOOL)browserAuth {
  NSAssert([DBOAuthManager sharedOAuthManager] != nil,
           @"Call `Dropbox.setupWithAppKey` or `Dropbox.setupWithTeamAppKey` before calling this method");
  DBDesktopSharedApplication *sharedDesktopApplication =
      [[DBDesktopSharedApplication alloc] init:sharedApplication controller:controller openURL:openURL];
  [[DBOAuthManager sharedOAuthManager] authorizeFromSharedApplication:sharedDesktopApplication browserAuth:browserAuth];
}

+ (void)setupWithAppKeyDesktop:(NSString *)appKey {
  [[self class] setupWithAppKeyDesktop:appKey transportClient:nil];
}

+ (void)setupWithAppKeyDesktop:(NSString *)appKey transportClient:(DBTransportClient *)transportClient {
  [[self class] setupWithOAuthManager:[[DBDesktopOAuthManager alloc] initWithAppKey:appKey]
                      transportClient:transportClient];
}

+ (void)setupWithAppKeyMultiUserDesktop:(NSString *)appKey
                        transportClient:(DBTransportClient *)transportClient
                               tokenUid:(NSString *)tokenUid {
  [[self class] setupWithOAuthManagerMultiUser:[[DBDesktopOAuthManager alloc] initWithAppKey:appKey]
                               transportClient:transportClient
                                      tokenUid:tokenUid];
}

+ (void)setupWithTeamAppKeyDesktop:(NSString *)appKey {
  [[self class] setupWithTeamAppKeyDesktop:appKey transportClient:nil];
}

+ (void)setupWithTeamAppKeyDesktop:(NSString *)appKey transportClient:(DBTransportClient *)transportClient {
  [[self class] setupWithOAuthManagerTeam:[[DBDesktopOAuthManager alloc] initWithAppKey:appKey]
                          transportClient:transportClient];
}

+ (void)setupWithTeamAppKeyMultiUserDesktop:(NSString *)appKey
                            transportClient:(DBTransportClient *)transportClient
                                   tokenUid:(NSString *)tokenUid {
  [[self class] setupWithOAuthManagerMultiUserTeam:[[DBDesktopOAuthManager alloc] initWithAppKey:appKey]
                                   transportClient:transportClient
                                          tokenUid:tokenUid];
}

@end
