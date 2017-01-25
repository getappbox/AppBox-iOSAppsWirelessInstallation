//
//  ProjectAdvancedViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "ProjectAdvancedViewController.h"

@implementation ProjectAdvancedViewController{
    NSDictionary *keyChainAccount;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [Common logScreen:@"Project Advanced Settings"];
    if ([self.project.buildType isEqualToString:BuildTypeAppStore]){
        [comboAppStoreTool selectItemAtIndex:0];
    }else{
        [comboAppStoreTool setEnabled:NO];
        [textFieldUserName setEnabled:NO];
        [textFieldPassword setEnabled:NO];
    }
    [pathBuild setURL:self.project.buildDirectory];
    NSArray *accounts = [SAMKeychain accountsForService:abiTunesConnectService];
    if (accounts.count > 0){
        keyChainAccount = [NSDictionary dictionaryWithDictionary:[accounts firstObject]];
        [textFieldUserName setStringValue: [keyChainAccount valueForKey:kSAMKeychainAccountKey]];
        [textFieldPassword setPlaceholderString:@"Taken from keychain. Type here to change."];
    }
}

- (IBAction)buttonCancelTapped:(NSButton *)sender {
    [self dismissController:self];
}

- (IBAction)buttonSaveTapped:(NSButton *)sender {
    [[textFieldPassword window] makeFirstResponder:self.view];
    [UserData setBuildLocation:self.project.buildDirectory];
    
    //set username and password
    [self.project setItcUserName:textFieldUserName.stringValue];
    [self.project setAppStoreUploadTool: comboAppStoreTool.stringValue];
    if (textFieldPassword.stringValue.length > 0){
        [self.project setItcPasswod:textFieldPassword.stringValue];
        //save username and password in keychain
        [SAMKeychain setPassword:textFieldPassword.stringValue forService:abiTunesConnectService account:textFieldUserName.stringValue];
    }else{
        [self.project setItcPasswod:[NSString stringWithFormat:abiTunesConnectService]];
    }
    
    
    [self dismissController:self];
}


//Build Path Handler
- (IBAction)buildPathHandler:(NSPathControl *)sender {
    if (![self.project.buildDirectory isEqualTo:sender.URL]){
        [self.project setBuildDirectory: sender.URL];
    }
}
@end
