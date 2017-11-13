///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <AppKit/AppKit.h>

#import "DBClientsManager+Protected.h"
#import "DBClientsManager.h"
#import "DBOAuthDesktop-macOS.h"
#import "DBOAuthManager.h"
#import "DBTransportDefaultConfig.h"

@implementation DBClientsManager (DesktopAuth)

+ (void)authorizeFromControllerDesktop:(NSWorkspace *)sharedApplication
                            controller:(NSViewController *)controller
                               openURL:(void (^_Nonnull)(NSURL *))openURL {
  NSAssert([DBOAuthManager sharedOAuthManager] != nil,
           @"Call `Dropbox.setupWithAppKey` or `Dropbox.setupWithTeamAppKey` before calling this method");
  DBDesktopSharedApplication *sharedDesktopApplication =
      [[DBDesktopSharedApplication alloc] initWithSharedApplication:sharedApplication
                                                         controller:controller
                                                            openURL:openURL];
  [[DBOAuthManager sharedOAuthManager] authorizeFromSharedApplication:sharedDesktopApplication];
}

+ (void)setupWithAppKeyDesktop:(NSString *)appKey {
  [[self class] setupWithTransportConfigDesktop:[[DBTransportDefaultConfig alloc] initWithAppKey:appKey]];
}

+ (void)setupWithTransportConfigDesktop:(DBTransportDefaultConfig *)transportConfig {
  [[self class] setupWithOAuthManager:[[DBOAuthManager alloc] initWithAppKey:transportConfig.appKey
                                                                        host:transportConfig.hostnameConfig.meta]
                      transportConfig:transportConfig];
}

+ (void)setupWithTeamAppKeyDesktop:(NSString *)appKey {
  [[self class] setupWithTeamTransportConfigDesktop:[[DBTransportDefaultConfig alloc] initWithAppKey:appKey]];
}

+ (void)setupWithTeamTransportConfigDesktop:(DBTransportDefaultConfig *)transportConfig {
  [[self class] setupWithOAuthManagerTeam:[[DBOAuthManager alloc] initWithAppKey:transportConfig.appKey
                                                                            host:transportConfig.hostnameConfig.meta]
                          transportConfig:transportConfig];
}

@end
