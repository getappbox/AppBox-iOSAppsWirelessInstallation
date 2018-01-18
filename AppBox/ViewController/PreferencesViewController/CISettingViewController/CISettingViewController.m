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
    [limitedLogCheckBox setState: [UserData debugLog] ? NSOnState : NSOffState];
    [updateAlertCheckBox setState: [UserData updateAlertEnable] ? NSOnState : NSOffState];
}

- (IBAction)updateAlertCheckBoxChanged:(NSButton *)sender {
    [UserData setUpdateAlertEnable:(sender.state == NSOnState)];
}

- (IBAction)limitedLogCheckBoxChanged:(NSButton *)sender {
    [UserData setEnableDebugLog:(sender.state == NSOnState)];
}
@end
