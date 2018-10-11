//
//  CISettingViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 13/01/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import "CISettingViewController.h"

@interface CISettingViewController ()

@end

@implementation CISettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //set user emails and password
    [defaultEmalTextField setStringValue:[UserData defaultCIEmail] ? [UserData defaultCIEmail] : @""];
    [subjectPrefixTextField setStringValue:[UserData ciSubjectPrefix] ? [UserData ciSubjectPrefix] : @""];
    [limitedLogCheckBox setState: [UserData debugLog] ? NSOnState : NSOffState];
    [updateAlertCheckBox setState: [UserData updateAlertEnable] ? NSOnState : NSOffState];
}

- (IBAction)updateAlertCheckBoxChanged:(NSButton *)sender {
    [UserData setUpdateAlertEnable:(sender.state == NSOnState)];
}

- (IBAction)limitedLogCheckBoxChanged:(NSButton *)sender {
    [UserData setEnableDebugLog:(sender.state == NSOnState)];
}

- (IBAction)emailSettingSaveButtonAction:(NSButton *)sender {
    //validate emails
    if (defaultEmalTextField.stringValue.length == 0  || ![MailHandler isAllValidEmail:defaultEmalTextField.stringValue]) {
        [MailHandler showInvalidEmailAddressAlert];
        return;
    }
    
    //save emails and prefix
    [UserData setDefaultCIEmail:defaultEmalTextField.stringValue];
    if (subjectPrefixTextField.stringValue.length > 0) {
        [UserData setCISubjectPrefix:subjectPrefixTextField.stringValue];
    }
}
@end
