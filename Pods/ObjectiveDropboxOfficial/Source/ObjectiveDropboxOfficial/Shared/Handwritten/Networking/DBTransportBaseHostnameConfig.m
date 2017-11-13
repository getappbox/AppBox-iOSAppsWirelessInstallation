///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBTransportBaseHostnameConfig.h"
#import "DBSDKConstants.h"

@implementation DBTransportBaseHostnameConfig

- (instancetype)init {
  if (!kSDKDebug) {
    return [self initWithMeta:@"www.dropbox.com"
                          api:@"api.dropbox.com"
                      content:@"api-content.dropbox.com"
                       notify:@"notify.dropboxapi.com"];
  } else {
    return [self initWithMeta:[NSString stringWithFormat:@"meta-%@.dev.corp.dropbox.com", kSDKDebugHost]
                          api:[NSString stringWithFormat:@"api-%@.dev.corp.dropbox.com", kSDKDebugHost]
                      content:[NSString stringWithFormat:@"api-content-%@.dev.corp.dropbox.com", kSDKDebugHost]
                       notify:[NSString stringWithFormat:@"notify-%@.dev.corp.dropboxapi.com", kSDKDebugHost]];
  }
  return self;
}

- (instancetype)initWithMeta:(NSString *)meta
                         api:(NSString *)api
                     content:(NSString *)content
                      notify:(NSString *)notify {
  if (self = [super init]) {
    _meta = meta;
    _api = api;
    _content = content;
    _notify = notify;
  }
  return self;
}

- (nullable NSString *)apiV2PrefixWithRouteType:(NSString *)routeType {
  if ([routeType isEqualToString:@"api"]) {
    return [NSString stringWithFormat:@"https://%@/2", _api];
  } else if ([routeType isEqualToString:@"content"]) {
    return [NSString stringWithFormat:@"https://%@/2", _content];
  } else if ([routeType isEqualToString:@"notify"]) {
    return [NSString stringWithFormat:@"https://%@/2", _notify];
  } else {
    return nil;
  }
}

@end
