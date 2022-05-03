///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

#import "DBLoadingStatusDelegate.h"
#import "DBSharedApplicationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

///
/// Platform-specific (here, macOS) shared application.
///
/// Renders OAuth flow and implements `DBSharedApplication` protocol.
///
@interface DBDesktopSharedApplication : NSObject <DBSharedApplication>

/// Delegate to handle loading status during auth flow.
@property (nonatomic, readwrite, weak) id<DBLoadingStatusDelegate> loadingStatusDelegate;

/// Returns the shared instance of `DBDesktopSharedApplication`.
+ (nullable DBDesktopSharedApplication *)desktopSharedApplication;

/// Sets the shared instance of `DBDesktopSharedApplication`.
+ (void)setDesktopSharedApplication:(DBDesktopSharedApplication *)desktopSharedApplication;

///
/// Full constructor.
///
/// @param sharedApplication The `NSWorkspace` with which to render the OAuth flow.
/// @param controller The `NSViewController` with which to render the OAuth flow. The controller reference is weakly
/// held.
/// @param openURL A wrapper around app-extension unsafe `openURL` call.
///
/// @return An initialized instance.
///
- (instancetype)initWithSharedApplication:(NSWorkspace *)sharedApplication
                               controller:(NSViewController *)controller
                                  openURL:(void (^_Nonnull)(NSURL *))openURL;

@end

NS_ASSUME_NONNULL_END
