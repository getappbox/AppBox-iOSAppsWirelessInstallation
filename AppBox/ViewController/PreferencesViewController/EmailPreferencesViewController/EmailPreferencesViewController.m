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
    // Do view setup here.
}

- (BOOL)isValidDetails {
    if ([MailHandler isAllValidEmail:emailTextField.stringValue]) {
        return YES;
    } else {
        [MailHandler showInvalidEmailAddressAlert];
    }
    return NO;
}

#pragma mark - Control Actions
- (IBAction)saveButtonTapped:(NSButton *)sender {
    
}

- (IBAction)sendTestMailButtonTapped:(NSButton *)sender {
    if (![self isValidDetails]) {
        return;
    }
    XCProject *project = [[XCProject alloc] init];
    [project setName:@"Test"];
    [project setVersion:@"1.0"];
    [project setBuild:@"1"];
    [project setEmails: emailTextField.stringValue];
    [project setPersonalMessage:personalMessageTextField.stringValue];
    [project setAppShortShareableURL:[NSURL URLWithString:@"tryappbox.com"]];
    [MBProgressHUD showStatus:@"Sending Test Mail" onView:self.view];
    [MailHandler sendMailForProject:project complition:^(BOOL success) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if (success) {
            [MBProgressHUD showStatus:@"Mail Sent" forSuccess:YES onView:self.view];
        } else {
            [MBProgressHUD showStatus:@"Mail Failed" forSuccess:NO onView:self.view];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        });
    }];
}

@end
