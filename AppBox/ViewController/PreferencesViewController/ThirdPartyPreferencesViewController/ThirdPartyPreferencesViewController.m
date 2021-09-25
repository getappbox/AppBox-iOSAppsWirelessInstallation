//
//  ThirdPartyPreferencesViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 10/05/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "ThirdPartyPreferencesViewController.h"

@implementation ThirdPartyPreferencesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    [slackChannelTextField setStringValue:[UserData userSlackChannel]];
    [hangoutChatTextField setStringValue:[UserData userHangoutChatWebHook]];
    [microsoftTeamWebHook setStringValue:[UserData userMicrosoftTeamWebHook]];
    [slackMessageTextField setStringValue:[UserData userSlackMessage]];
}


- (BOOL)validateWebHookURLWithSlack:(BOOL)slack hangout:(BOOL)hangout msTeams:(BOOL)msTeams{
    NSString *slackURL = [slackChannelTextField.stringValue stringByRemovingPercentEncoding];
    if ([NSURL URLWithString:slackURL] == nil && slack) {
        [Common showAlertWithTitle:@"Error" andMessage:@"Please enter a valid Slack WebHook URL."];
        return NO;
    }
    
    NSString *hangoutURL = [hangoutChatTextField.stringValue stringByRemovingPercentEncoding];
    if ([NSURL URLWithString:hangoutURL] == nil && hangout) {
        [Common showAlertWithTitle:@"Error" andMessage:@"Please enter a valid Hangout Chat WebHook URL."];
        return NO;
    }
    
    NSString *microsoftTeamURL = [microsoftTeamWebHook.stringValue stringByRemovingPercentEncoding];
    if ([NSURL URLWithString:microsoftTeamURL] == nil && msTeams) {
        [Common showAlertWithTitle:@"Error" andMessage:@"Please enter a valid Microsoft Team WebHook URL."];
        return NO;
    }
    return YES;
}

- (IBAction)saveButtonTapped:(NSButton *)sender {
    [self.view.window makeFirstResponder:self.view];
    if (![self validateWebHookURLWithSlack:YES hangout:YES msTeams:YES]) {
        return;
    }
    [UserData setUserSlackChannel:slackChannelTextField.stringValue];
    [UserData setUserHangoutChatWebHook:hangoutChatTextField.stringValue];
    [UserData setUserMicrosoftTeamWebHook:microsoftTeamWebHook.stringValue];
    [UserData setUserSlackMessage:slackMessageTextField.stringValue];
    [ABHudViewController showStatus:@"Details Saved!" forSuccess:YES onView:self.view];
}

- (IBAction)testSlackButtonTapped:(NSButton *)sender {
    [self.view.window makeFirstResponder:self.view];
    if (![self validateWebHookURLWithSlack:YES hangout:NO msTeams:NO]) {
        return;
    }
    [ABHudViewController showStatus:@"Sending Test Message..." onView:self.view];
    [SlackClient sendMessageForProject:[self demoProject] completion:^(BOOL success) {
        [ABHudViewController hideAllHudFromView:self.view after:0];
        if (success) {
            [ABHudViewController showStatus:@"Message Sent." forSuccess:YES onView:self.view];
        } else {
            [ABHudViewController showStatus:@"Message Failed." forSuccess:NO onView:self.view];
        }
    }];
}

- (IBAction)testHangoutChatButtonTapped:(NSButton *)sender {
    [self.view.window makeFirstResponder:self.view];
    if (![self validateWebHookURLWithSlack:NO hangout:YES msTeams:NO]) {
        return;
    }
    [ABHudViewController showStatus:@"Sending Test Message..." onView:self.view];
    [HangoutClient sendMessageForProject:[self demoProject] completion:^(BOOL success) {
        [ABHudViewController hideAllHudFromView:self.view after:0];
        if (success) {
            [ABHudViewController showStatus:@"Message Sent." forSuccess:YES onView:self.view];
        } else {
            [ABHudViewController showStatus:@"Message Failed." forSuccess:NO onView:self.view];
        }
    }];
}

- (IBAction)testMicrosoftTeamButtonTapped:(NSButton *)sender {
    [self.view.window makeFirstResponder:self.view];
    if (![self validateWebHookURLWithSlack:NO hangout:NO msTeams:YES]) {
        return;
    }
    [ABHudViewController showStatus:@"Sending Test Message..." onView:self.view];
    [MSTeamsClient sendMessageForProject:[self demoProject] completion:^(BOOL success) {
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

-(XCProject *)demoProject{
    //create a test project for demo email
    XCProject *project = [[XCProject alloc] init];
    [project setName:@"TestApp"];
    [project setVersion:@"1.0"];
    [project setBuild:@"1"];
    [project setAppShortShareableURL:[NSURL URLWithString:@"https://getappbox.com"]];
    return project;
}

@end
