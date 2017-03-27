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
    NSArray *itcAccounts;
    NSDictionary *keyChainAccount;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [Common logScreen:@"Apple Developer Login"];
    
    //Load iTunes UserName and password
    itcAccounts = [SAMKeychain accountsForService:abiTunesConnectService];
    if (itcAccounts.count > 0){
        [self selectITCAccountAtIndex:0];
    }
    BOOL isMultipleAccounts = itcAccounts.count > 1;
    [comboUserName setHidden:!isMultipleAccounts];
    [textFieldUserName setHidden:isMultipleAccounts];
    if (isMultipleAccounts) {
        for (NSDictionary *itcAccount in itcAccounts) {
            [comboUserName addItemWithObjectValue:[itcAccount valueForKey:kSAMKeychainAccountKey]];
        }
        [comboUserName selectItemAtIndex:0];
    }
}

#pragma mark - Controls actions
- (IBAction)buttonLoginTapped:(NSButton *)sender{
    [[textFieldPassword window] makeFirstResponder:self.view];
    [self showProgress:YES];
    [ITCLogin loginWithUserName:textFieldUserName.stringValue andPassword:textFieldPassword.stringValue completion:^(bool success, NSString *message) {
        [self showProgress:NO];
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

- (IBAction)comboUserNameValueChanged:(NSComboBox *)sender {
    if ([sender.objectValues containsObject:sender.stringValue]){
        [self selectITCAccountAtIndex:sender.indexOfSelectedItem];
    }else{
        [textFieldUserName setStringValue:sender.stringValue];
        [self textFieldUserNameValueChanged:textFieldUserName];
    }
}

- (IBAction)textFieldUserNameValueChanged:(NSTextField *)sender {
    [comboUserName setHidden:YES];
    [textFieldUserName setHidden:NO];
    [textFieldPassword setStringValue:@""];
}

- (IBAction)textFieldPasswordValueChanged:(NSSecureTextField *)sender {
//    [self buttonLoginTapped:buttonLogin];
}


#pragma mark - Helper Methods

- (void)selectITCAccountAtIndex:(NSInteger)index{
    keyChainAccount = [NSDictionary dictionaryWithDictionary:[itcAccounts objectAtIndex:index]];
    NSString *username = [keyChainAccount valueForKey:kSAMKeychainAccountKey];
    NSString *password = [SAMKeychain passwordForService:abiTunesConnectService account:username];
    [textFieldUserName setStringValue: username];
    [textFieldPassword setStringValue: password];
}

- (void)showProgress:(BOOL)progress{
    [progressIndicator setHidden:!progress];
    [buttonLogin setEnabled:!progress];
    [buttonCancel setEnabled:!progress];
    if (progress){
        [progressIndicator startAnimation:nil];
    }else{
        [progressIndicator stopAnimation:nil];
    }
}

@end
