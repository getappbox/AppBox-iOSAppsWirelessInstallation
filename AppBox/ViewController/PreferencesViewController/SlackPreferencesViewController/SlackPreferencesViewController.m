//
//  SlackPreferencesViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 10/05/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "SlackPreferencesViewController.h"

@interface SlackPreferencesViewController ()

@end

@implementation SlackPreferencesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    [slackChannelTextField setStringValue:[UserData userSlackChannel]];
    [slackMessageTextField setStringValue:[UserData userSlackMessage]];
}


- (BOOL)validateSlackInformation{
    if (slackChannelTextField.stringValue.length == 0 || [NSURL URLWithString:slackChannelTextField.stringValue] == nil) {
        [Common showAlertWithTitle:@"Error" andMessage:@"Please enter a valid URL."];
        return NO;
    }
    return YES;
}

- (IBAction)saveButtonTapped:(NSButton *)sender {
    [self.view.window makeFirstResponder:self.view];
    if (![self validateSlackInformation]) {
        return;
    }
    [UserData setUserSlackChannel:slackChannelTextField.stringValue];
    [UserData setUserSlackMessage:slackMessageTextField.stringValue];
    [ABHudViewController showStatus:@"Details Saved!" forSuccess:YES onView:self.view];
}

- (IBAction)sendTextMessageButtonTapped:(NSButton *)sender {
    [self.view.window makeFirstResponder:self.view];
    if (![self validateSlackInformation]) {
        return;
    }
    
    //create a test project for demo email
    XCProject *project = [[XCProject alloc] init];
    [project setName:@"TestApp"];
    [project setVersion:@"1.0"];
    [project setBuild:@"1"];
    [project setAppShortShareableURL:[NSURL URLWithString:@"tryappbox.com"]];
    
    [ABHudViewController showStatus:@"Sending Test Message..." onView:self.view];
    [SlackClient sendMessageForProject:project completion:^(BOOL success) {
        [ABHudViewController hideAllHudFromView:self.view after:0];
        if (success) {
            [ABHudViewController showStatus:@"Message Sent." forSuccess:YES onView:self.view];
        } else {
            [ABHudViewController showStatus:@"Message Failed." forSuccess:NO onView:self.view];
        }
    }];
}

- (IBAction)setupNewSlackWebhook:(NSButton *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:abWebHookSetupURL]];
}

@end
