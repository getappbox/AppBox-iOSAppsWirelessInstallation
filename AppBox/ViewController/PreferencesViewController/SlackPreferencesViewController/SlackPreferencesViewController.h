//
//  SlackPreferencesViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 10/05/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SlackPreferencesViewController : NSViewController {
    IBOutlet NSTextField *slackChannelTextField;
    IBOutlet NSTextField *slackMessageTextField;
}

- (IBAction)saveButtonTapped:(NSButton *)sender;
- (IBAction)sendTextMessageButtonTapped:(NSButton *)sender;
- (IBAction)setupNewSlackWebhook:(NSButton *)sender;


@end
