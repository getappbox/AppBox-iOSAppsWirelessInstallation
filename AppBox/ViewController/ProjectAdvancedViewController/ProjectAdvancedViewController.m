//
//  ProjectAdvancedViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "ProjectAdvancedViewController.h"

@interface ProjectAdvancedViewController ()

@end

@implementation ProjectAdvancedViewController

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
}

- (IBAction)buttonCancelTapped:(NSButton *)sender {
    [self dismissController:self];
}

- (IBAction)buttonSaveTapped:(NSButton *)sender {
    [UserData setBuildLocation:self.project.buildDirectory];
    [self.project setItcPasswod:textFieldPassword.stringValue];
    [self.project setItcUserName:textFieldUserName.stringValue];
    [self.project setAppStoreUploadTool: comboAppStoreTool.stringValue];
    [self dismissController:self];
}


//Build Path Handler
- (IBAction)buildPathHandler:(NSPathControl *)sender {
    if (![self.project.buildDirectory isEqualTo:sender.URL]){
        [self.project setBuildDirectory: sender.URL];
    }
}
@end
