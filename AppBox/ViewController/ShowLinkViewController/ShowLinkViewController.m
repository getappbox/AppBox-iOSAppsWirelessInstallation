//
//  ShowLinkViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 07/09/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "ShowLinkViewController.h"

@interface ShowLinkViewController ()

@end

@implementation ShowLinkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [Common logScreen:@"AppBox ShareLink"];
    [textFieldAppLink setStringValue: self.appLink];
}


- (IBAction)buttonCopyToClipboardTapped:(NSButton *)sender {
    [Answers logCustomEventWithName:@"Copy to Clipboard" customAttributes:@{}];
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:self.appLink  forType:NSStringPboardType];
    [sender setTitle:@"Copied!!"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [sender setTitle:@"Copy to clipboard"];
    });
}

- (IBAction)buttonCloseTapped:(NSButton *)sender {
    [self dismissController:self];
}

@end
