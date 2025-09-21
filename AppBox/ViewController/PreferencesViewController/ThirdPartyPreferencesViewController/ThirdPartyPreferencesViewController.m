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
    
    [slackChannelTextField setStringValue:[UserData userSlackChannel]];
    [microsoftTeamWebHook setStringValue:[UserData userMicrosoftTeamWebHook]];
    [slackMessageTextField setStringValue:[UserData userSlackMessage]];
}


- (BOOL)validateWebHookURLWithSlack:(BOOL)slack msTeams:(BOOL)msTeams{
    NSString *slackURL = [slackChannelTextField.stringValue stringByRemovingPercentEncoding];
    if ([NSURL URLWithString:slackURL] == nil && slack) {
        [Common showAlertWithTitle:@"Error" andMessage:@"Please enter a valid Slack WebHook URL."];
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
    if (![self validateWebHookURLWithSlack:YES msTeams:YES]) {
        return;
    }
    [UserData setUserSlackChannel:slackChannelTextField.stringValue];
    [UserData setUserMicrosoftTeamWebHook:microsoftTeamWebHook.stringValue];
    [UserData setUserSlackMessage:slackMessageTextField.stringValue];
    [ABHudViewController showStatus:@"Details Saved!" forSuccess:YES onView:self.view];
}

- (IBAction)testSlackButtonTapped:(NSButton *)sender {
    [self.view.window makeFirstResponder:self.view];
    if (![self validateWebHookURLWithSlack:YES msTeams:NO]) {
        return;
    }
	NSString *webhook = [slackChannelTextField.stringValue stringByRemovingPercentEncoding];
	NSString *message = slackMessageTextField.stringValue;
    [ABHudViewController showStatus:@"Sending Test Message..." onView:self.view];
	[SlackClient sendMessage:[self demoIPAUploadInfo] webhook:webhook message:message completion:^(BOOL success) {
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
    if (![self validateWebHookURLWithSlack:NO msTeams:YES]) {
        return;
    }
	NSString *webhook = [microsoftTeamWebHook.stringValue stringByRemovingPercentEncoding];
	NSString *message = slackMessageTextField.stringValue;
    [ABHudViewController showStatus:@"Sending Test Message..." onView:self.view];
    [MSTeamsClient sendMessage:[self demoIPAUploadInfo] webhook:webhook message:message completion:^(BOOL success) {
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

-(IPAUploadInfo *)demoIPAUploadInfo{
    //create a test ipa upload info for demo email
    IPAUploadInfo *ipaUploadInfo = [[IPAUploadInfo alloc] init];
    [ipaUploadInfo setName:@"TestApp"];
    [ipaUploadInfo setVersion:@"1.0"];
    [ipaUploadInfo setBuild:@"1"];
    [ipaUploadInfo setAppShortShareableURL:[NSURL URLWithString:@"https://getappbox.com"]];
    return ipaUploadInfo;
}

@end
