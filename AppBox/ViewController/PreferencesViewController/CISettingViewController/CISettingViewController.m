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

    //set general settings
    [limitedLogCheckBox setState: [UserData debugLog] ? NSOnState : NSOffState];
    [updateAlertCheckBox setState: [UserData updateAlertEnable] ? NSOnState : NSOffState];
    
    //set user emails and password
    [defaultEmalTextField setStringValue:[UserData defaultCIEmail] ? [UserData defaultCIEmail] : @""];
    [subjectPrefixTextField setStringValue:[UserData ciSubjectPrefix] ? [UserData ciSubjectPrefix] : @""];

    //set user keychain settings
    NSString *keychainPassword = [SAMKeychain passwordForService:abmacOSKeyChainService account:abmacOSKeyChainAccount];
    [keychainPasswordTextField setStringValue:keychainPassword ? keychainPassword : @""];
    [keychainPathTextField setStringValue:[UserData keychainPath] ? [UserData keychainPath] : @""];
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

- (IBAction)keychainUnlockButtonAction:(NSButton *)sender {
    //Unlock Keychain
    OSStatus status = [KeychainHandler unlockKeyChain:keychainPathTextField.stringValue
                                         withPassword:keychainPasswordTextField.stringValue];
    
    //if status not equal to zero means error
    if (status != 0) {
        [Common showAlertWithTitle:@"" andMessage:[KeychainHandler errorMessageForStatus:status]];
        return;
    }
    
    //save keychain path
    if (!(keychainPathTextField.stringValue == nil || keychainPathTextField.stringValue.length == 0)) {
        [UserData setKeychainPath:keychainPathTextField.stringValue];
    }
    
    //save password in keychain
    NSError *error;
    [SAMKeychain setPassword:keychainPasswordTextField.stringValue
                  forService:abmacOSKeyChainService
                     account:abmacOSKeyChainAccount
                       error:&error];
    if (error) {
        [Common showAlertWithTitle:nil andMessage:error.localizedDescription];
    } else {
        [Common showAlertWithTitle:@"Success" andMessage:@""];
    }
}
@end
