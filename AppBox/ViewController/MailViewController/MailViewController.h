//
//  MailViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 12/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@protocol MailDelegate <NSObject>

-(void)mailSentWithWebView:(WebView *)webView;
-(void)loginSuccessWithWebView:(WebView *)webView;
-(void)mailViewLoadedWithWebView:(WebView *)webView;
-(void)invalidPerametersWithWebView:(WebView *)webView;

@end

@interface MailViewController : NSViewController <WebFrameLoadDelegate, WebUIDelegate>{
    IBOutlet WebView *webView;
    IBOutlet NSButton *buttonReload;
    IBOutlet NSButton *buttonCancel;
    IBOutlet NSButton *buttonClearCache;
    IBOutlet NSProgressIndicator *progressIndicator;
}

@property(nonatomic, strong) NSString *url;
@property(nonatomic, weak) id<MailDelegate> delegate;

- (IBAction)reloadButtonTapped:(NSButton *)sender;
- (IBAction)cancelButtonTapped:(NSButton *)sender;
- (IBAction)clearCacheButtonTapped:(NSButton *)sender;

@end
