///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

#import "DBOAuth.h"
#import "DBSharedApplicationProtocol.h"

///
/// Platform-specific (here, macOS) shared application.
///
/// Renders OAuth flow and implements `DBSharedApplication` protocol.
///
@interface DBDesktopSharedApplication : NSObject <DBSharedApplication>

///
/// Full constructor.
///
/// @param sharedApplication The `NSWorkspace` with which to render the
/// OAuth flow.
/// @param controller The `NSViewController` with which to render the OAuth
/// flow.
/// @param openURL A wrapper around app-extension unsafe `openURL` call.
///
/// @return An initialized instance.
///
- (nonnull instancetype)init:(NSWorkspace * _Nonnull)sharedApplication
                  controller:(NSViewController * _Nonnull)controller
                     openURL:(void (^_Nonnull)(NSURL * _Nonnull))openURL;

@end

///
/// Platform-specific (here, macOS) `NSViewController` for rendering OAuth flow.
///
@interface DBDesktopWebViewController : NSViewController <NSWindowDelegate, WKNavigationDelegate>

///
/// Full constructor.
///
/// @param tryInterceptHandler The navigation handler for the view controller.
/// Will check if exit url (for redirect back to main app) can be successfully
/// navigated to.
/// @param cancelHandler Handler for auth cancellation. Will redirect back to
/// main app with special cancel url, so that cancellation can be detected.
/// flow.
///
/// @return An initialized instance.
///
- (nonnull instancetype)init:(NSURL * _Nonnull)url
         tryInterceptHandler:(BOOL (^_Nonnull)(NSURL * _Nonnull))tryInterceptHandler
               cancelHandler:(void (^_Nonnull)(void))cancelHandler;

@end
