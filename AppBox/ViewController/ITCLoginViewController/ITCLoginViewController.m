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
    [EventTracker logScreen:@"Apple Developer Login"];
    
    //Load iTunes UserName and password
    itcAccounts = [KeychainHandler getAllITCAccounts];
    
    if (itcAccounts.count > 0){
        [self selectITCAccountAtIndex:0];
    }
    
    //check for multiple account available in keychain
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
    if (![self isValidDetails]) {
        return;
    }
    
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

- (IBAction)buttonUseWithoutLoginTapped:(NSButton *)sender {
    [[textFieldPassword window] makeFirstResponder:self.view];
    if (![self isValidDetails]) {
        return;
    }
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText: @"Warning"];
    [alert setInformativeText:@"Please make sure Username/Email and Password correct. Because AppBox would not verify with AppStore."];
    [alert addButtonWithTitle:@"Login"];
    [alert addButtonWithTitle:@"Continue without Login"];
    [alert setAlertStyle:NSInformationalAlertStyle];
    
    if ([alert runModal] == NSAlertFirstButtonReturn){
        [self buttonLoginTapped:sender];
    } else {
        [self.project setItcUserName:textFieldUserName.stringValue];
        [self.project setItcPasswod:textFieldPassword.stringValue];
        //save username and password in keychain
        [SAMKeychain setPassword:textFieldPassword.stringValue forService:abiTunesConnectService account:textFieldUserName.stringValue];
        [self.delegate itcLoginResult:YES];
        [self dismissController:self];
    }
}


- (IBAction)buttonCancelTapped:(NSButton *)sender{
    [self.delegate itcLoginCanceled];
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
//    [textFieldPassword setStringValue:@""];
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
    [buttonUseWithoutLogin setEnabled:!progress];
    
    if (progress){
        [progressIndicator startAnimation:nil];
    }else{
        [progressIndicator stopAnimation:nil];
    }
}

-(BOOL)isValidDetails {
    NSString *userName = [textFieldUserName stringValue];
    NSString *password = [textFieldPassword stringValue];
    
    if (userName && !userName.isEmpty && [MailHandler isValidEmail:userName]) {
        if (password && !password.isEmpty) {
            return YES;
        } else {
            [Common showAlertWithTitle:nil andMessage:@"Please enter a Password."];
        }
    } else {
        [Common showAlertWithTitle:nil andMessage:@"Please enter a valid AppStore Connect email."];
    }
    return NO;
}

@end
