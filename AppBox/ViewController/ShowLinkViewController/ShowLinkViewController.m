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
    textFieldAppLink.stringValue = self.appLink;
}


- (IBAction)buttonCopyToClipboardTapped:(NSButton *)sender {
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:self.appLink  forType:NSStringPboardType];
    [Common showLocalNotificationWithTitle:@"AppBox"  andMessage:@"We've copy distribution link to your clipboard."];
}

- (IBAction)buttonCloseTapped:(NSButton *)sender {
    [self dismissController:self];
}

@end
