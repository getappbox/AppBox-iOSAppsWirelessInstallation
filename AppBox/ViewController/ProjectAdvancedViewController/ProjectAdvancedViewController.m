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
}

- (void)viewDidDisappear{
    [super viewDidDisappear];
}

//MARK: - Action Button Tapped
- (IBAction)buttonCancelTapped:(NSButton *)sender {
    [self dismissController:self];
    [self.delegate projectAdvancedCancelButtonTapped:sender];
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
