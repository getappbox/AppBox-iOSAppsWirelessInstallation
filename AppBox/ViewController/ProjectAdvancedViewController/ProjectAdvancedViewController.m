//
//  ProjectAdvancedViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "ProjectAdvancedViewController.h"

@implementation ProjectAdvancedViewController{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [EventTracker logScreen:@"Project Advanced Settings"];
    if (self.project.bundleDirectory) {
        [self.dbFolderNameTextField setStringValue:self.project.bundleDirectory.lastPathComponent];
    }
    [self.dbFolderNameTextField setEnabled:self.project.isKeepSameLinkEnabled];
    [self.localNetworkCheckBox setTitle: [LocalServerHandler getLocalIPAddress]];
}

//MARK: - Action Button Tapped
- (IBAction)buttonCancelTapped:(NSButton *)sender {
    [self dismissController:self];
    [self.delegate projectAdvancedCancelButtonTapped:sender];
}

- (IBAction)buttonLocalNetworkStateChanged:(NSButton *)sender {
    if (sender.state == NSOnState) {
        [MBProgressHUD showStatus:@"Starting Local Server..." onView:self.view];
        [TaskHandler runTaskWithName:@"PythonServer" andArgument:@[[UserData buildLocation].absoluteString] taskLaunch:nil outputStream:^(NSTask *task, NSString *output) {
            [[AppDelegate appDelegate] addSessionLog:output];
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }];
    }
}

- (IBAction)buttonSaveTapped:(NSButton *)sender {
    if (self.delegate != nil){
        [self.delegate projectAdvancedSaveButtonTapped:sender];
    }
    
    if(![self.dbFolderNameTextField.stringValue isEqualToString:self.project.identifer] && self.dbFolderNameTextField.stringValue.length>0){
        NSString *bundlePath = [NSString stringWithFormat:@"/%@",self.dbFolderNameTextField.stringValue];
        bundlePath = [bundlePath stringByReplacingOccurrencesOfString:@" " withString:abEmptyString];
        [self.project setBundleDirectory:[NSURL URLWithString:bundlePath]];
    }

    [self dismissController:self];
}





@end
