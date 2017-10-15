//
//  PreferencesViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 27/03/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "PreferencesViewController.h"

@interface PreferencesViewController ()

@end

@implementation PreferencesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //set build url
    [pathBuild setURL:[UserData buildLocation]];
    [pathXCode setURL:[UserData xCodeLocation]];
    
    //set settings
    [uploadSymbolButton setState:[UserData uploadSymbols]];
    [uploadBitCodeButton setState:[UserData uploadBitcode]];
    [compileBitCodeButton setState:[UserData compileBitcode]];
}

//Build Path Handler
- (IBAction)buildPathHandler:(NSPathControl *)sender {
    if ([[sender.URL.resourceSpecifier stringByRemovingPercentEncoding] containsString:@" "]){
        [Common showAlertWithTitle:@"Error" andMessage:[NSString stringWithFormat:@"Please select directory without any spaces.\n\n%@",[sender.URL.resourceSpecifier stringByRemovingPercentEncoding]]];
        [sender setURL:[UserData buildLocation]];
    }else{
        [UserData setBuildLocation:sender.URL];
    }
}

//Xcode Path Handler
- (IBAction)xcodePathHandler:(NSPathControl *)sender {
    NSString *selectedXcode = sender.URL.resourceSpecifier;
    NSString *alPath = [[selectedXcode stringByAppendingPathComponent:abApplicationLoaderALToolLocation] stringByRemovingPercentEncoding];
    if ([[NSFileManager defaultManager] fileExistsAtPath:alPath]){
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Application Loader = %@", alPath]];
        [XCHandler changeDefaultXcodePath:selectedXcode withCompletion:^(BOOL success, NSString *error) {
            if (success) {
                [UserData setXCodeLocation:selectedXcode];
                [UserData setApplicationLoaderLocation:alPath];
            } else {
                [sender setURL:[UserData xCodeLocation]];
                [Common showAlertWithTitle:@"Error" andMessage:error];
            }
        }];
    } else {
        [sender setURL:nil];
        [Common showAlertWithTitle:@"Error" andMessage:@"Please select a valid Xcode. AppBox don't able to find application loader for selected Xcode."];
    }
}

- (IBAction)appStoreSymbolsFileCheckBokValueChanged:(NSButton *)sender {
    [UserData setUploadSymbols:(sender.state == NSOnState)];
}

- (IBAction)compileBitcodeCheckBokValueChanged:(NSButton *)sender {
    [UserData setCompileBitcode:(sender.state == NSOnState)];
}

- (IBAction)appStoreBitcodeCheckBokValueChanged:(NSButton *)sender {
    [UserData setUploadBitcode:(sender.state == NSOnState)];
}

@end
