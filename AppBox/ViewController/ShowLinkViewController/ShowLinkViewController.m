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
    [EventTracker logScreen:@"AppBox ShareLink"];
    [textFieldAppLink setStringValue: self.project.appShortShareableURL.stringValue];
    if ([self.project.appShortShareableURL isEqualTo:self.project.appLongShareableURL]) {
        [textFieldHint setStringValue:LongURLUserHint];
        [linkHeightConstraint setConstant:70];
        [linkHintHeightConstraint setConstant:40];
    } else {
        [textFieldHint setStringValue:ShortURLUserHint];
        [linkHeightConstraint setConstant:30];
        [linkHintHeightConstraint setConstant:20];
    }
    
    //Save Project Details
    [Project addProjectWithXCProject:self.project];
}


- (IBAction)buttonCopyToClipboardTapped:(NSButton *)sender {
    [EventTracker logEventWithType:LogEventTypeCopyToClipboard];
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:self.project.appShortShareableURL.stringValue  forType:NSStringPboardType];
    [sender setTitle:@"Copied!!"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [sender setTitle:@"Copy to Clipboard"];
    });
}

- (IBAction)buttonOpenURLAction:(NSButton *)sender {
    [[NSWorkspace sharedWorkspace] openURL:self.project.appShortShareableURL];
    [EventTracker logEventWithType:LogEventTypeOpenInDropbox];
}


- (IBAction)buttonCloseTapped:(NSButton *)sender {
    [self dismissController:self];
}

//MARK: - Navigation
-(void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender{
    if ([segue.destinationController isKindOfClass:[QRCodeViewController class]]){
        ((QRCodeViewController *) segue.destinationController).project = self.project;
    } else if([segue.destinationController isKindOfClass:[DashboardViewController class]]) {
        [EventTracker logEventWithType:LogEventTypeOpenDashboardFromShowLink];
    }
}

@end
