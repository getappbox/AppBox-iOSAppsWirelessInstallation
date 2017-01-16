///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBOAuth.h"
#import "DBOAuthDesktop-macOS.h"

@interface DBDesktopSharedApplication ()

@property (nonatomic) NSWorkspace * _Nullable sharedWorkspace;
@property (nonatomic) NSViewController * _Nullable controller;
@property (nonatomic) void (^openURL)(NSURL * _Nullable);

- (nonnull instancetype)init:(NSWorkspace * _Nonnull)sharedApplication
                  controller:(NSViewController * _Nonnull)controller
                     openURL:(void (^_Nonnull)(NSURL * _Nonnull))openURL;

@end

@implementation DBDesktopSharedApplication

- (instancetype)init:(NSWorkspace *)sharedWorkspace
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
  NSError *error = [[NSError alloc] initWithDomain:@"" code:123 userInfo:@{NSLocalizedDescriptionKey : message}];
  [_controller presentError:error];
}

- (void)presentErrorMessageWithHandlers:(NSString * _Nonnull)message
                                  title:(NSString * _Nonnull)title
                         buttonHandlers:(NSDictionary<NSString *, void (^)()> * _Nonnull)buttonHandlers {
  [self presentErrorMessage:message title:title];
}

- (BOOL)presentPlatformSpecificAuth:(NSURL * _Nonnull)authURL {
  // no platform-specific auth methods for macOS
  return NO;
}

- (void)presentWebViewAuth:(NSURL * _Nonnull)authURL
       tryInterceptHandler:(BOOL (^_Nonnull)(NSURL * _Nonnull))tryInterceptHandler
             cancelHandler:(void (^_Nonnull)(void))cancelHandler {
  DBDesktopWebViewController *webViewController = [[DBDesktopWebViewController alloc] init:authURL
                                                                       tryInterceptHandler:tryInterceptHandler
                                                                             cancelHandler:cancelHandler];
  [_controller presentViewControllerAsModalWindow:webViewController];
}

- (void)presentBrowserAuth:(NSURL * _Nonnull)authURL {
  [self presentExternalApp:authURL];
}

- (void)presentExternalApp:(NSURL * _Nonnull)url {
  _openURL(url);
}

- (BOOL)canPresentExternalApp:(NSURL * _Nonnull)url {
  return YES;
}

@end

@interface DBDesktopWebViewController ()

@property (nonatomic) WKWebView * _Nullable webView;
@property (nonatomic) void (^_Nullable onWillDismiss)(BOOL);
@property (nonatomic) BOOL (^_Nullable tryInterceptHandler)(NSURL * _Nullable);
@property (nonatomic) void (^_Nullable cancelHandler)(void);
@property (nonatomic) NSProgressIndicator * _Nullable indicator;
@property (nonatomic, copy) NSURL * _Nullable startURL;

@end

@implementation DBDesktopWebViewController

- (instancetype)init {
  return [super initWithNibName:nil bundle:nil];
}

- (instancetype)init:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (instancetype)init:(NSURL *)URL
    tryInterceptHandler:(BOOL (^)(NSURL *))tryInterceptHandler
          cancelHandler:(void (^)(void))cancelHandler {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _tryInterceptHandler = tryInterceptHandler;
    _cancelHandler = cancelHandler;
    _indicator = [[NSProgressIndicator alloc] init];
    [_indicator setFrame:NSMakeRect(20, 20, 30, 30)];
    [_indicator setStyle:NSProgressIndicatorSpinningStyle];
    _startURL = URL;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Link to Dropbox";
  _webView = [[WKWebView alloc] initWithFrame:self.view.bounds];

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
    if (_startURL != nil) {
      [self loadURL:_startURL];
    } else {
      [_webView loadHTMLString:@"There is no `startURL`" baseURL:nil];
    }
  }
}

- (BOOL)windowShouldClose:(id)sender {
  _cancelHandler();
  return YES;
}

- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                    decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
  if (navigationAction.request.URL != nil && _tryInterceptHandler != nil) {
    if (_tryInterceptHandler(navigationAction.request.URL)) {
      [self dismiss:YES];
      return decisionHandler((WKNavigationActionPolicy)WKNavigationActionPolicyCancel);
    }
  }
  return decisionHandler((WKNavigationActionPolicy)WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
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
  [_webView stopLoading];
  [self dismissController:nil];
}

@end
