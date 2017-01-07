//
//  ShowLinkViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 07/09/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "ShowLinkViewController.h"

#define ShortURLUserHint @"Your app is ready. Copy this link and send it to anyone."
#define LongURLUserHint @"Your app is ready. Copy this link and send it to anyone, sorry for long url, google shortener API getting failed currently."

@interface ShowLinkViewController ()

@end

@implementation ShowLinkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [Common logScreen:@"AppBox ShareLink"];
    [textFieldAppLink setStringValue: self.project.appShortShareableURL.absoluteString];
    [textFieldHint setStringValue: ([self.project.appShortShareableURL isEqualTo:self.project.appLongShareableURL]) ? LongURLUserHint : ShortURLUserHint];
}


- (IBAction)buttonCopyToClipboardTapped:(NSButton *)sender {
    [Answers logCustomEventWithName:@"Copy to Clipboard" customAttributes:@{}];
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:self.project.appShortShareableURL.absoluteString  forType:NSStringPboardType];
    [sender setTitle:@"Copied!!"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [sender setTitle:@"Copy to Clipboard"];
    });
}

- (IBAction)buttonCloseTapped:(NSButton *)sender {
    [self dismissController:self];
}

@end
