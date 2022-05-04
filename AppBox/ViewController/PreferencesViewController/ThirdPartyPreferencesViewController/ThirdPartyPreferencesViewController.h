//
//  ThirdPartyPreferencesViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 10/05/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ThirdPartyPreferencesViewController : NSViewController {
    __weak IBOutlet NSTextField *slackChannelTextField;
    __weak IBOutlet NSTextField *slackMessageTextField;
    __weak IBOutlet NSTextField *hangoutChatTextField;
    __weak IBOutlet NSTextField *microsoftTeamWebHook;
}

- (IBAction)saveButtonTapped:(NSButton *)sender;
- (IBAction)testSlackButtonTapped:(NSButton *)sender;
- (IBAction)testHangoutChatButtonTapped:(NSButton *)sender;
- (IBAction)testMicrosoftTeamButtonTapped:(NSButton *)sender;



- (IBAction)setupNewSlackWebhook:(NSButton *)sender;


@end
