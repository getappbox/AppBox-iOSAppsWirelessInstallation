///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBOAuth.h"
#import "DBOAuthDesktop-macOS.h"

@implementation DBDesktopSharedApplication {
  NSWorkspace * _Nullable _sharedWorkspace;
  NSViewController * _Nullable _controller;
  void (^_openURL)(NSURL * _Nullable);
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

- (void)presentErrorMessageWithHandlers:(NSString * _Nonnull)message
                                  title:(NSString * _Nonnull)title
                         buttonHandlers:(NSDictionary<NSString *, void (^)()> * _Nonnull)buttonHandlers {
#pragma unused(buttonHandlers)
  [self presentErrorMessage:message title:title];
}

- (BOOL)presentPlatformSpecificAuth:(NSURL * _Nonnull)authURL {
#pragma unused(authURL)
  // no platform-specific auth methods for macOS
  return NO;
}

- (void)presentWebViewAuth:(NSURL * _Nonnull)authURL
       tryInterceptHandler:(BOOL (^_Nonnull)(NSURL * _Nonnull, BOOL))tryInterceptHandler
             cancelHandler:(void (^_Nonnull)(void))cancelHandler {
  if (_controller) {
    DBDesktopWebViewController *webViewController =
        [[DBDesktopWebViewController alloc] initWithAuthUrl:authURL
                                        tryInterceptHandler:tryInterceptHandler
                                              cancelHandler:cancelHandler];
    [_controller presentViewControllerAsModalWindow:webViewController];
  }
}

- (void)presentBrowserAuth:(NSURL * _Nonnull)authURL {
  [self presentExternalApp:authURL];
}

- (void)presentExternalApp:(NSURL * _Nonnull)url {
  _openURL(url);
}

- (BOOL)canPresentExternalApp:(NSURL * _Nonnull)url {
#pragma unused(url)
  return YES;
}

@end

@interface DBDesktopWebViewController ()

@property (nonatomic) WKWebView * _Nullable webView;
@property (nonatomic) void (^_Nullable onWillDismiss)(BOOL);
@property (nonatomic) BOOL (^_Nullable tryInterceptHandler)(NSURL * _Nullable, BOOL);
@property (nonatomic) void (^_Nullable cancelHandler)(void);
@property (nonatomic) NSProgressIndicator * _Nullable indicator;
@property (nonatomic, copy) NSURL * _Nullable startUrl;

@end

@implementation DBDesktopWebViewController

- (instancetype)init {
  return [super initWithNibName:nil bundle:nil];
}

- (instancetype)init:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (instancetype)initWithAuthUrl:(NSURL *)authUrl
            tryInterceptHandler:(BOOL (^)(NSURL *, BOOL))tryInterceptHandler
                  cancelHandler:(void (^)(void))cancelHandler {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _tryInterceptHandler = tryInterceptHandler;
    _cancelHandler = cancelHandler;
    _indicator = [[NSProgressIndicator alloc] init];
    [_indicator setFrame:NSMakeRect(20, 20, 30, 30)];
    [_indicator setStyle:NSProgressIndicatorSpinningStyle];
    _startUrl = authUrl;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Link to Dropbox";
  _webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
  _webView.UIDelegate = self;

  [_indicator setFrameOrigin:NSMakePoint((NSWidth(_webView.bounds) - NSWidth(_indicator.frame)) / 2,
                                         (NSHeight(_webView.bounds) - NSHeight(_indicator.frame)) / 2)];

  [_webView addSubview:_indicator];
  [_indicator startAnimation:self];

  [self.view addSubview:_webView];

  [_webView addSubview:_indicator];
  [_indicator startAnimation:self];

  [self.view addSubview:_webView];
  _webView.navigationDelegate = self;
  _webView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

  if (self.view.window != nil) {
    self.view.window.delegate = self;
  }
}

- (void)viewWillAppear {
  [super viewWillAppear];

  if (![_webView canGoBack]) {
    if (_startUrl != nil) {
      [self loadURL:_startUrl];
    } else {
      [_webView loadHTMLString:@"There is no `startUrl`" baseURL:nil];
    }
  }
}

- (BOOL)windowShouldClose:(id)sender {
#pragma unused(sender)
  _cancelHandler();
  return YES;
}

- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                    decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
#pragma unused(webView)
  if (navigationAction.request.URL != nil && _tryInterceptHandler != nil) {
    if (_tryInterceptHandler(navigationAction.request.URL, NO)) {
      [self dismiss:YES];
      return decisionHandler((WKNavigationActionPolicy)WKNavigationActionPolicyCancel);
    }
  }
  return decisionHandler((WKNavigationActionPolicy)WKNavigationActionPolicyAllow);
}

- (WKWebView *)webView:(WKWebView *)webView
    createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
               forNavigationAction:(WKNavigationAction *)navigationAction
                    windowFeatures:(WKWindowFeatures *)windowFeatures {
  // For target="_bank" urls, we want to suppress the call, then reopen in new browser
  if (!navigationAction.targetFrame.isMainFrame) {
    _tryInterceptHandler(navigationAction.request.URL, YES);
  }
  return nil;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
#pragma unused(webView)
#pragma unused(navigation)
  [_indicator stopAnimation:self];
  [_indicator removeFromSuperview];
}

- (void)loadView {
  self.view = [[NSView alloc] init];
  self.view.frame = NSMakeRect(0, 0, 800, 600);
}

- (void)loadURL:(NSURL *)url {
  [_webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)goBack:(id)sender {
#pragma unused(sender)
  [_webView goBack];
}

- (void)cancel:(id)sender {
  [self dismiss:YES animated:(sender != nil)];
  _cancelHandler();
}

- (void)dismiss:(BOOL)animated {
  [self dismiss:NO animated:animated];
}

- (void)dismiss:(BOOL)asCancel animated:(BOOL)animated {
#pragma unused(asCancel)
#pragma unused(animated)
  [_webView stopLoading];
  [self dismissController:nil];
}

@end
