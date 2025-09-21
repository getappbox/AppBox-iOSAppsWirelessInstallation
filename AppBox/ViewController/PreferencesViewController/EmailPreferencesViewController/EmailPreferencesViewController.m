//
//  EmailPreferencesViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 28/03/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "EmailPreferencesViewController.h"

@interface EmailPreferencesViewController ()

@end

@implementation EmailPreferencesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //set user emails and password
    [emailTextField setStringValue:[UserData userEmail]];
    [personalMessageTextField setStringValue:[UserData userMessage]];
}

- (BOOL)isValidEmailDetails {
    if (emailTextField.stringValue.length > 0 && [MailHandler isAllValidEmail:emailTextField.stringValue]) {
        return YES;
    } else {
        [MailHandler showInvalidEmailAddressAlert];
    }
    return NO;
}

//MARK: - Control Actions
- (IBAction)saveButtonTapped:(NSButton *)sender {
    [self.view.window makeFirstResponder:self.view];
	if (emailTextField.stringValue.isEmpty && personalMessageTextField.stringValue.isEmpty) {
		[UserData setUserEmail:emailTextField.stringValue];
		[UserData setUserMessage:personalMessageTextField.stringValue];
		[ABHudViewController showStatus:@"Details Cleared!" forSuccess:YES onView:self.view];
	} else if ([self isValidEmailDetails]) {
		[UserData setUserEmail:emailTextField.stringValue];
		[UserData setUserMessage:personalMessageTextField.stringValue];
		[ABHudViewController showStatus:@"Details Saved!" forSuccess:YES onView:self.view];
    }
}

- (IBAction)sendTestMailButtonTapped:(NSButton *)sender {
    [self.view.window makeFirstResponder:self.view];
    
    if (![self isValidEmailDetails]) {
        return;
    }
    
    //create a test ipa upload info for demo email
    IPAUploadInfo *ipaUploadInfo = [[IPAUploadInfo alloc] init];
    [ipaUploadInfo setName:@"TestApp"];
    [ipaUploadInfo setVersion:@"1.0"];
    [ipaUploadInfo setBuild:@"1"];
    [ipaUploadInfo setEmails: emailTextField.stringValue];
    [ipaUploadInfo setAppShortShareableURL:[NSURL URLWithString:@"https://getappbox.com"]];
    [ipaUploadInfo setPersonalMessage: [MailHandler parseMessage:personalMessageTextField.stringValue forIPAUploadInfo:ipaUploadInfo]];
    
    //send mail
    [ABHudViewController showStatus:@"Sending Test Mail" onView:self.view];
	weakify(self);
    [MailGun sendMailWithProject:ipaUploadInfo.abpProject complition:^(BOOL success, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			strongify(self);
			[ABHudViewController hideAllHudFromView:self.view after:0];
			if (success) {
				[ABHudViewController showStatus:@"Mail Sent" forSuccess:YES onView:self.view];
			} else {
				[ABHudViewController showStatus:@"Mail Failed" forSuccess:NO onView:self.view];
			}
		});
    }];
}

@end
