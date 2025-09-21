//
//  ShowLinkViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 07/09/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "ShowLinkViewController.h"

#define ShortURLUserHint @"Your app is ready. Copy this link and send it to anyone."
#define LongURLUserHint @"Your app is ready. Copy this link and send it to anyone, sorry for long url, our shortener URL API getting failed currently."

@interface ShowLinkViewController ()

@end

@implementation ShowLinkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [textFieldAppLink setStringValue: self.ipaUploadInfo.appShortShareableURL.stringValue];
    if ([self.ipaUploadInfo.appShortShareableURL isEqualTo:self.ipaUploadInfo.appLongShareableURL]) {
        [textFieldHint setStringValue:LongURLUserHint];
        [linkHeightConstraint setConstant:70];
        [linkHintHeightConstraint setConstant:40];
    } else {
        [textFieldHint setStringValue:ShortURLUserHint];
        [linkHeightConstraint setConstant:30];
        [linkHintHeightConstraint setConstant:20];
    }
    
    //Save Project Details
    [ABProject addProjectWithIPAUploadInfo:self.ipaUploadInfo];
}


- (IBAction)buttonCopyToClipboardTapped:(NSButton *)sender {
    [[NSPasteboard generalPasteboard] clearContents];
	[[NSPasteboard generalPasteboard] setString:self.ipaUploadInfo.appShortShareableURL.stringValue  forType:NSPasteboardTypeString];
    [sender setTitle:@"Copied!!"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [sender setTitle:@"Copy to Clipboard"];
    });
}

- (IBAction)buttonOpenURLAction:(NSButton *)sender {
    [[NSWorkspace sharedWorkspace] openURL:self.ipaUploadInfo.appShortShareableURL];
}


- (IBAction)buttonCloseTapped:(NSButton *)sender {
    [self dismissController:self];
}

//MARK: - Navigation
-(void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender{
    if ([segue.destinationController isKindOfClass:[QRCodeViewController class]]){
        ((QRCodeViewController *) segue.destinationController).ipaUploadInfo = self.ipaUploadInfo;
    }
}

@end
