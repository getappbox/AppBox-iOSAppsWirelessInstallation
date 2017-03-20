///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <AppKit/AppKit.h>

#import "DBClientsManager+Protected.h"
#import "DBClientsManager.h"
#import "DBOAuth.h"
#import "DBOAuthDesktop-macOS.h"
#import "DBTransportDefaultConfig.h"

@implementation DBClientsManager (DesktopAuth)

+ (void)authorizeFromControllerDesktop:(NSWorkspace *)sharedApplication
                            controller:(NSViewController *)controller
                               openURL:(void (^_Nonnull)(NSURL *))openURL
                           browserAuth:(BOOL)browserAuth {
  NSAssert([DBOAuthManager sharedOAuthManager] != nil,
           @"Call `Dropbox.setupWithAppKey` or `Dropbox.setupWithTeamAppKey` before calling this method");
  DBDesktopSharedApplication *sharedDesktopApplication =
      [[DBDesktopSharedApplication alloc] initWithSharedApplication:sharedApplication
                                                         controller:controller
                                                            openURL:openURL];
  [[DBOAuthManager sharedOAuthManager] authorizeFromSharedApplication:sharedDesktopApplication browserAuth:browserAuth];
}

+ (void)setupWithAppKeyDesktop:(NSString *)appKey {
  [[self class] setupWithTransportConfigDesktop:[[DBTransportDefaultConfig alloc] initWithAppKey:appKey]];
}

+ (void)setupWithTransportConfigDesktop:(DBTransportDefaultConfig *)transportConfig {
  [[self class] setupWithOAuthManager:[[DBDesktopOAuthManager alloc] initWithAppKey:transportConfig.appKey]
                      transportConfig:transportConfig];
}

+ (void)setupWithAppKeyMultiUserDesktop:(NSString *)appKey tokenUid:(NSString *)tokenUid {
  DBTransportDefaultConfig *transportConfig = [[DBTransportDefaultConfig alloc] initWithAppKey:appKey];
  [[self class] setupWithOAuthManagerMultiUser:[[DBDesktopOAuthManager alloc] initWithAppKey:transportConfig.appKey]
                               transportConfig:transportConfig
                                      tokenUid:tokenUid];
}

+ (void)setupWithTransportConfigMultiUserDesktop:(DBTransportDefaultConfig *)transportConfig
                                        tokenUid:(NSString *)tokenUid {
  [[self class] setupWithOAuthManagerMultiUser:[[DBDesktopOAuthManager alloc] initWithAppKey:transportConfig.appKey]
                               transportConfig:transportConfig
                                      tokenUid:tokenUid];
}

+ (void)setupWithTeamAppKeyDesktop:(NSString *)appKey {
  [[self class] setupWithTeamTransportConfigDesktop:[[DBTransportDefaultConfig alloc] initWithAppKey:appKey]];
}

+ (void)setupWithTeamTransportConfigDesktop:(DBTransportDefaultConfig *)transportConfig {
  [[self class] setupWithOAuthManagerTeam:[[DBDesktopOAuthManager alloc] initWithAppKey:transportConfig.appKey]
                          transportConfig:transportConfig];
}

+ (void)setupWithTeamAppKeyMultiUserDesktop:(NSString *)appKey tokenUid:(NSString *)tokenUid {
  DBTransportDefaultConfig *transportConfig = [[DBTransportDefaultConfig alloc] initWithAppKey:appKey];
  [[self class] setupWithOAuthManagerTeamMultiUser:[[DBDesktopOAuthManager alloc] initWithAppKey:transportConfig.appKey]
                                   transportConfig:transportConfig
                                          tokenUid:tokenUid];
}

+ (void)setupWithTeamTransportConfigMultiUserDesktop:(DBTransportDefaultConfig *)transportConfig
                                            tokenUid:(NSString *)tokenUid {
  [[self class] setupWithOAuthManagerTeamMultiUser:[[DBDesktopOAuthManager alloc] initWithAppKey:transportConfig.appKey]
                                   transportConfig:transportConfig
                                          tokenUid:tokenUid];
}

@end
