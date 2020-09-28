///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBOAuthDesktop-macOS.h"

#import "DBLoadingStatusDelegate.h"
#import "DBOAuthManager.h"

static DBDesktopSharedApplication *s_desktopSharedApplication;

@implementation DBDesktopSharedApplication {
  NSWorkspace *_sharedWorkspace;
  NSViewController *_controller;
  void (^_openURL)(NSURL *);
}

+ (DBDesktopSharedApplication *)desktopSharedApplication {
  return s_desktopSharedApplication;
}

+ (void)setDesktopSharedApplication:(DBDesktopSharedApplication *)desktopSharedApplication {
  s_desktopSharedApplication = desktopSharedApplication;
}

- (instancetype)initWithSharedApplication:(NSWorkspace *)sharedWorkspace
                               controller:(NSViewController *)controller
                                  openURL:(void (^)(NSURL *))openURL {
  self = [super init];
  if (self) {
    // fields saved for app-extension safety
    _sharedWorkspace = sharedWorkspace;
    _controller = controller;
    _openURL = openURL;
  }
  return self;
}

- (void)presentErrorMessage:(NSString *)message title:(NSString *)title {
#pragma unused(title)
  if (_controller) {
    NSError *error = [[NSError alloc] initWithDomain:@"" code:123 userInfo:@{NSLocalizedDescriptionKey : message}];
    [_controller presentError:error];
  }
}

- (void)presentErrorMessageWithHandlers:(NSString *)message
                                  title:(NSString *)title
                         buttonHandlers:(NSDictionary<NSString *, void (^)(void)> *)buttonHandlers {
#pragma unused(buttonHandlers)
  [self presentErrorMessage:message title:title];
}

- (BOOL)presentPlatformSpecificAuth:(NSURL *)authURL {
#pragma unused(authURL)
  // no platform-specific auth methods for macOS
  return NO;
}

- (void)presentAuthChannel:(NSURL *)authURL cancelHandler:(void (^_Nonnull)(void))cancelHandler {
#pragma unused(cancelHandler)
  if (_controller) {
    [self presentExternalApp:authURL];
  }
}

- (void)presentExternalApp:(NSURL *)url {
  _openURL(url);
}

- (BOOL)canPresentExternalApp:(NSURL *)url {
#pragma unused(url)
  return YES;
}

- (void)presentLoading {
  [_loadingStatusDelegate showLoading];
}

- (void)dismissLoading {
  [_loadingStatusDelegate dismissLoading];
}

@end
