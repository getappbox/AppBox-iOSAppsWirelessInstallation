///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBTransportDefaultConfig.h"

@implementation DBTransportDefaultConfig

- (instancetype)initWithAppKey:(NSString *)appKey {
  return [self initWithAppKey:appKey appSecret:nil userAgent:nil delegateQueue:nil forceForegroundSession:NO];
}

- (instancetype)initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret {
  return [self initWithAppKey:appKey appSecret:appSecret userAgent:nil delegateQueue:nil forceForegroundSession:NO];
}

- (instancetype)initWithAppKey:(NSString *)appKey
                     appSecret:(NSString *)appSecret
                 delegateQueue:(NSOperationQueue *)delegateQueue {
  return [self initWithAppKey:appKey
                    appSecret:appSecret
                    userAgent:nil
                delegateQueue:delegateQueue
       forceForegroundSession:NO];
}

- (instancetype)initWithAppKey:(NSString *)appKey forceForegroundSession:(BOOL)forceForegroundSession {
  return [self initWithAppKey:appKey
                    appSecret:nil
                    userAgent:nil
                delegateQueue:nil
       forceForegroundSession:forceForegroundSession];
}

- (instancetype)initWithAppKey:(NSString *)appKey
                     appSecret:(NSString *)appSecret
                     userAgent:(NSString *)userAgent
                 delegateQueue:(NSOperationQueue *)delegateQueue
        forceForegroundSession:(BOOL)forceForegroundSession {
  return [self initWithAppKey:appKey
                    appSecret:appSecret
                    userAgent:userAgent
                   asMemberId:nil
                delegateQueue:delegateQueue
       forceForegroundSession:forceForegroundSession];
}

- (instancetype)initWithAppKey:(NSString *)appKey
                     appSecret:(NSString *)appSecret
                     userAgent:(NSString *)userAgent
                    asMemberId:(NSString *)asMemberId
                 delegateQueue:(NSOperationQueue *)delegateQueue
        forceForegroundSession:(BOOL)forceForegroundSession {
  return [self initWithAppKey:appKey
                      appSecret:appSecret
                      userAgent:userAgent
                     asMemberId:asMemberId
                  delegateQueue:delegateQueue
         forceForegroundSession:forceForegroundSession
      sharedContainerIdentifier:nil];
}

- (instancetype)initWithAppKey:(NSString *)appKey
                     appSecret:(NSString *)appSecret
                     userAgent:(NSString *)userAgent
                    asMemberId:(NSString *)asMemberId
                 delegateQueue:(NSOperationQueue *)delegateQueue
        forceForegroundSession:(BOOL)forceForegroundSession
     sharedContainerIdentifier:(NSString *)sharedContainerIdentifier {
  return [self initWithAppKey:appKey
                      appSecret:appSecret
                      userAgent:userAgent
                     asMemberId:asMemberId
              additionalHeaders:nil
                  delegateQueue:delegateQueue
         forceForegroundSession:forceForegroundSession
      sharedContainerIdentifier:sharedContainerIdentifier];
}

- (instancetype)initWithAppKey:(NSString *)appKey
                     appSecret:(NSString *)appSecret
                     userAgent:(NSString *)userAgent
                    asMemberId:(NSString *)asMemberId
             additionalHeaders:(NSDictionary<NSString *, NSString *> *)additionalHeaders
                 delegateQueue:(NSOperationQueue *)delegateQueue
        forceForegroundSession:(BOOL)forceForegroundSession
     sharedContainerIdentifier:(NSString *)sharedContainerIdentifier {
  return [self initWithAppKey:appKey
                      appSecret:appSecret
                 hostnameConfig:nil
                      userAgent:userAgent
                     asMemberId:asMemberId
              additionalHeaders:additionalHeaders
                  delegateQueue:delegateQueue
         forceForegroundSession:forceForegroundSession
      sharedContainerIdentifier:sharedContainerIdentifier];
}

- (instancetype)initWithAppKey:(NSString *)appKey
                     appSecret:(NSString *)appSecret
                hostnameConfig:(DBTransportBaseHostnameConfig *)hostnameConfig
                     userAgent:(NSString *)userAgent
                    asMemberId:(NSString *)asMemberId
             additionalHeaders:(NSDictionary<NSString *, NSString *> *)additionalHeaders
                 delegateQueue:(NSOperationQueue *)delegateQueue
        forceForegroundSession:(BOOL)forceForegroundSession
     sharedContainerIdentifier:(NSString *)sharedContainerIdentifier {
  return [self initWithAppKey:appKey
                      appSecret:appSecret
                 hostnameConfig:hostnameConfig
                    redirectURL:nil
                      userAgent:userAgent
                     asMemberId:asMemberId
                       pathRoot:nil
              additionalHeaders:additionalHeaders
                  delegateQueue:delegateQueue
         forceForegroundSession:forceForegroundSession
      sharedContainerIdentifier:sharedContainerIdentifier];
}

- (instancetype)initWithAppKey:(NSString *)appKey
                     appSecret:(NSString *)appSecret
                hostnameConfig:(DBTransportBaseHostnameConfig *)hostnameConfig
                   redirectURL:(NSString *)redirectURL
                     userAgent:(NSString *)userAgent
                    asMemberId:(NSString *)asMemberId
                      pathRoot:(nullable DBCOMMONPathRoot *)pathRoot
             additionalHeaders:(NSDictionary<NSString *, NSString *> *)additionalHeaders
                 delegateQueue:(NSOperationQueue *)delegateQueue
        forceForegroundSession:(BOOL)forceForegroundSession
     sharedContainerIdentifier:(NSString *)sharedContainerIdentifier {
  if (self = [super initWithAppKey:appKey
                         appSecret:appSecret
                    hostnameConfig:hostnameConfig
                       redirectURL:redirectURL
                         userAgent:userAgent
                        asMemberId:asMemberId
                          pathRoot:pathRoot
                 additionalHeaders:additionalHeaders]) {
    _delegateQueue = delegateQueue;
    _forceForegroundSession = forceForegroundSession;
    _sharedContainerIdentifier = sharedContainerIdentifier;
  }
  return self;
}

@end
