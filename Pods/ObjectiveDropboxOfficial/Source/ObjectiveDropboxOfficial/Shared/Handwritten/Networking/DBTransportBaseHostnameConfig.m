///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBTransportBaseHostnameConfig.h"
#import "DBSDKConstants.h"
#import "DBStoneBase.h"

@implementation DBRoute (DropboxHost)

- (DBRouteHost)host {
  NSString *routeHost = self.attrs[@"host"];
  if ([routeHost isEqualToString:@"api"]) {
    return DBRouteHostApi;
  }
  if ([routeHost isEqualToString:@"content"]) {
    return DBRouteHostContent;
  }
  if ([routeHost isEqualToString:@"notify"]) {
    return DBRouteHostNotify;
  }
  return DBRouteHostUnknown;
}

@end

@implementation DBTransportBaseHostnameConfig

- (instancetype)init {
  return [self initWithMeta:@"www.dropbox.com"
                        api:@"api.dropbox.com"
                    content:@"api-content.dropbox.com"
                     notify:@"notify.dropboxapi.com"];
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

- (nullable NSString *)apiV2PrefixWithRoute:(DBRoute *)route {
  switch (route.host) {
  case DBRouteHostApi:
    return [NSString stringWithFormat:@"https://%@/2", _api];
  case DBRouteHostContent:
    return [NSString stringWithFormat:@"https://%@/2", _content];
  case DBRouteHostNotify:
    return [NSString stringWithFormat:@"https://%@/2", _notify];
  case DBRouteHostUnknown:
    return nil;
  }
}

@end
