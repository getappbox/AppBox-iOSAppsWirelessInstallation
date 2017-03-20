///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBClientsManager.h"

@class DBOAuthManager;
@class DBTransportDefaultConfig;

@interface DBClientsManager (Protected)

+ (void)setupWithOAuthManager:(DBOAuthManager * _Nonnull)oAuthManager
              transportConfig:(DBTransportDefaultConfig * _Nonnull)transportConfig;

+ (void)setupWithOAuthManagerMultiUser:(DBOAuthManager * _Nonnull)oAuthManager
                       transportConfig:(DBTransportDefaultConfig * _Nonnull)transportConfig
                              tokenUid:(NSString * _Nullable)tokenUid;

+ (void)setupWithOAuthManagerTeam:(DBOAuthManager * _Nonnull)oAuthManager
                  transportConfig:(DBTransportDefaultConfig * _Nonnull)transportConfig;

+ (void)setupWithOAuthManagerTeamMultiUser:(DBOAuthManager * _Nonnull)oAuthManager
                           transportConfig:(DBTransportDefaultConfig * _Nonnull)transportConfig
                                  tokenUid:(NSString * _Nullable)tokenUid;

+ (void)setTransportConfig:(DBTransportDefaultConfig * _Nonnull)transportConfig;

+ (DBTransportDefaultConfig * _Nonnull)transportConfig;

+ (void)setAppKey:(NSString * _Nonnull)appKey;

@end
