///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

///
/// Protocol implemented by platform-specific builds of the Obj-C SDK
/// for properly rendering the OAuth linking flow.
///
@protocol DBSharedApplication <NSObject>

///
/// Presents a platform-specific error message, and halts the auth flow.
///
/// @param message String to display which describes the error.
/// @param title String to display which titles the error view.
///
- (void)presentErrorMessage:(NSString * _Nonnull)message title:(NSString * _Nonnull)title;

///
/// Presents a platform-specific error message, and halts the auth flow. Optional handlers may be
/// provided for view display buttons (mainly useful in the mobile case).
///
/// @param message String to display which describes the error.
/// @param title String to display which titles the error view.
/// @param buttonHandlers Map from button name to button handler.
///
- (void)presentErrorMessageWithHandlers:(NSString * _Nonnull)message
                                  title:(NSString * _Nonnull)title
                         buttonHandlers:(NSDictionary<NSString *, void (^)()> * _Nonnull)buttonHandlers;

///
/// Presents platform-specific authorization paths.
///
/// This method is called before more generic, platform-neutral auth methods (like in-app web view
/// auth or external browser auth). For example, in the mobile case, the Obj-C SDK will use a direct
/// authorization route with the Dropbox mobile app, if it is installed on the current device.
///
/// @param authURL Gateway url to commence auth flow.
///
- (BOOL)presentPlatformSpecificAuth:(NSURL * _Nonnull)authURL;

///
/// Presents platform-neutral "webview auth" flow.
///
/// With this flow, an in-app web browser loads the auth page. The advantage with this flow is that
/// the user never leaves the app during the auth process. The disadvantage is that session data is
/// not retrieved, so the user must enter their login credentials manually, which can be cumbersome.
///
/// @param authURL Gateway url to commence auth flow.
/// @param tryInterceptHandler Navigation handler for redirect from webview back to normal app view.
/// @param cancelHandler Handler for cancelling auth flow. Opens "cancel" url to signal cancellation.
///
- (void)presentWebViewAuth:(NSURL * _Nonnull)authURL
       tryInterceptHandler:(BOOL (^_Nonnull)(NSURL * _Nonnull))tryInterceptHandler
             cancelHandler:(void (^_Nonnull)(void))cancelHandler;

///
/// Presents platform-neutral "external webbrowser auth" flow.
///
/// With this flow, the default external webbrowser is opened to load the auth page. The advantage with
/// this flow is that the user can leverage preexisting session data. This is also a safer option for
/// app users, as it is not required that they trust the third-party app that they're using. The disadvantage
/// is that the user is redirected outside of the app, which can require multiple confirmations and is
/// generally not the smoothest experience.
///
/// @param authURL Gateway url to commence auth flow.
///
- (void)presentBrowserAuth:(NSURL * _Nonnull)authURL;

///
/// Opens external app to handle url.
///
/// This method opens whichever app is registered to handle the type of the supplied url, and then passes
/// the supplied url into the newly opened app.
///
/// @param url Url to open with external app.
///
- (void)presentExternalApp:(NSURL * _Nonnull)url;

///
/// Checks whether there is an external app registered to open the url type.
///
/// @param url Url to check.
///
/// @return Whether there is an external app registered to open the url type.
///
- (BOOL)canPresentExternalApp:(NSURL * _Nonnull)url;

@end
