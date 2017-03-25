//
//  ADLViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 25/03/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "ITCLoginViewController.h"

@interface ITCLoginViewController ()

@end

@implementation ITCLoginViewController{
    NSDictionary *keyChainAccount;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [Common logScreen:@"Apple Developer Login"];
    [progressIndicator setHidden:YES];
    NSArray *accounts = [SAMKeychain accountsForService:abiTunesConnectService];
    if (accounts.count > 0){
        keyChainAccount = [NSDictionary dictionaryWithDictionary:[accounts firstObject]];
        NSString *username = [keyChainAccount valueForKey:kSAMKeychainAccountKey];
        NSString *password = [SAMKeychain passwordForService:abiTunesConnectService account:username];
        [textFieldUserName setStringValue: username];
        [textFieldPassword setStringValue: password];
    }
}

- (IBAction)buttonLoginTapped:(NSButton *)sender{
    [[textFieldPassword window] makeFirstResponder:self.view];
    [progressIndicator setHidden:NO];
    [ITCLogin loginWithUserName:textFieldUserName.stringValue andPassword:textFieldPassword.stringValue completion:^(bool success, NSString *message) {
        [progressIndicator setHidden:YES];
        if (success) {
            //set username and password
            [self.project setItcUserName:textFieldUserName.stringValue];
            if (textFieldPassword.stringValue.length > 0){
                [self.project setItcPasswod:textFieldPassword.stringValue];
                //save username and password in keychain
                [SAMKeychain setPassword:textFieldPassword.stringValue forService:abiTunesConnectService account:textFieldUserName.stringValue];
            }else{
                [self.project setItcPasswod:[NSString stringWithFormat:abiTunesConnectService]];
            }
            [self dismissController:self];
        }else{
            [Common showAlertWithTitle:@"Error" andMessage:message];
        }
        [self.delegate itcLoginResult:success];
    }];
}

- (IBAction)buttonCancelTapped:(NSButton *)sender{
    [self dismissController:self];
}

@end
