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
    if (![self isValidEmailDetails]) {
        return;
    }
    [UserData setUserEmail:emailTextField.stringValue];
    [UserData setUserMessage:personalMessageTextField.stringValue];
    [ABHudViewController showStatus:@"Details Saved!" forSuccess:YES onView:self.view];
}

- (IBAction)sendTestMailButtonTapped:(NSButton *)sender {
    [self.view.window makeFirstResponder:self.view];
    
    if (![self isValidEmailDetails]) {
        return;
    }
    
    //create a test project for demo email
    XCProject *project = [[XCProject alloc] init];
    [project setName:@"TestApp"];
    [project setVersion:@"1.0"];
    [project setBuild:@"1"];
    [project setEmails: emailTextField.stringValue];
    [project setAppShortShareableURL:[NSURL URLWithString:@"https://getappbox.com"]];
    [project setPersonalMessage: [MailHandler parseMessage:personalMessageTextField.stringValue forProject:project]];
    
    //send mail
    [ABHudViewController showStatus:@"Sending Test Mail" onView:self.view];
    [MailGun sendMailWithProject:project.abpProject complition:^(BOOL success, NSError *error) {
        [ABHudViewController hideAllHudFromView:self.view after:0];
        if (success) {
            [ABHudViewController showStatus:@"Mail Sent" forSuccess:YES onView:self.view];
        } else {
            [ABHudViewController showStatus:@"Mail Failed" forSuccess:NO onView:self.view];
        }
    }];
}

@end
