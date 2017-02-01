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
        NSString *xcodePath = [UserData xCodeLocation];
        if ([[NSFileManager defaultManager] fileExistsAtPath:xcodePath]){
            [pathXCode setURL: [NSURL URLWithString:xcodePath]];
        }
    }else{
        [pathXCode setEnabled:NO];
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

//MARK: - Action Button Tapped
- (IBAction)buttonCancelTapped:(NSButton *)sender {
    [self dismissController:self];
}

- (IBAction)buttonSaveTapped:(NSButton *)sender {
    [[textFieldPassword window] makeFirstResponder:self.view];
    [UserData setBuildLocation:self.project.buildDirectory];
    
    //set xcode and application loader path
    if (pathXCode.URL.isFileURL){
        [self.project setXcodePath:[pathXCode.URL.filePathURL resourceSpecifier]];
    }else{
        [self.project setXcodePath: pathXCode.URL.absoluteString];
    }
    [self.project setAlPath: [[self.project.xcodePath stringByAppendingPathComponent:abApplicationLoaderLocation] stringByRemovingPercentEncoding]];
    
    //set xcode location
    [UserData setXCodeLocation:self.project.xcodePath];
    
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
}


//Build Path Handler
- (IBAction)buildPathHandler:(NSPathControl *)sender {
    if (![self.project.buildDirectory isEqualTo:sender.URL]){
        [self.project setBuildDirectory: sender.URL];
    }
}

//Xcode Path Handler
- (IBAction)xcodePathHandler:(NSPathControl *)sender {

}
@end
