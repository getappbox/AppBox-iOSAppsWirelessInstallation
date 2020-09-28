///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <AppKit/AppKit.h>

#import "DBClientsManager+Protected.h"
#import "DBClientsManager.h"
#import "DBLoadingStatusDelegate.h"
#import "DBOAuthDesktop-macOS.h"
#import "DBOAuthManager.h"
#import "DBScopeRequest.h"
#import "DBTransportDefaultConfig.h"

@implementation DBClientsManager (DesktopAuth)

+ (void)authorizeFromControllerDesktop:(NSWorkspace *)sharedApplication
                            controller:(NSViewController *)controller
                               openURL:(void (^_Nonnull)(NSURL *))openURL {
  [self db_authorizeFromControllerDesktop:sharedApplication
                               controller:controller
                    loadingStatusDelegate:nil
                                  openURL:openURL
                                  usePkce:NO
                             scopeRequest:nil];
}

+ (void)authorizeFromControllerDesktopV2:(NSWorkspace *)sharedApplication
                              controller:(nullable NSViewController *)controller
                   loadingStatusDelegate:(nullable id<DBLoadingStatusDelegate>)loadingStatusDelegate
                                 openURL:(void (^_Nonnull)(NSURL *))openURL
                            scopeRequest:(nullable DBScopeRequest *)scopeRequest {
  [self db_authorizeFromControllerDesktop:sharedApplication
                               controller:controller
                    loadingStatusDelegate:loadingStatusDelegate
                                  openURL:openURL
                                  usePkce:YES
                             scopeRequest:scopeRequest];
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

#pragma - mark Private methods

+ (void)db_authorizeFromControllerDesktop:(NSWorkspace *)sharedApplication
                               controller:(nullable NSViewController *)controller
                    loadingStatusDelegate:(nullable id<DBLoadingStatusDelegate>)loadingStatusDelegate
                                  openURL:(void (^_Nonnull)(NSURL *))openURL
                                  usePkce:(BOOL)usePkce
                             scopeRequest:(nullable DBScopeRequest *)scopeRequest {
  NSAssert([DBOAuthManager sharedOAuthManager] != nil,
           @"Call `Dropbox.setupWithAppKey` or `Dropbox.setupWithTeamAppKey` before calling this method");
  DBDesktopSharedApplication *sharedDesktopApplication =
      [[DBDesktopSharedApplication alloc] initWithSharedApplication:sharedApplication
                                                         controller:controller
                                                            openURL:openURL];
  sharedDesktopApplication.loadingStatusDelegate = loadingStatusDelegate;
  [DBDesktopSharedApplication setDesktopSharedApplication:sharedDesktopApplication];
  [[DBOAuthManager sharedOAuthManager] authorizeFromSharedApplication:sharedDesktopApplication
                                                              usePkce:usePkce
                                                         scopeRequest:scopeRequest];
}

@end
