//
//  UploadAdvancedSettingViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "UploadAdvancedSettingViewController.h"

@implementation UploadAdvancedSettingViewController{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.ipaUploadInfo.bundleDirectory) {
        [self.dbFolderNameTextField setStringValue:self.ipaUploadInfo.bundleDirectory.lastPathComponent];
    }
    [self.dbFolderNameTextField setEnabled:self.ipaUploadInfo.isKeepSameLinkEnabled];
}

- (void)viewDidDisappear{
    [super viewDidDisappear];
}

//MARK: - Action Button Tapped
- (IBAction)buttonCancelTapped:(NSButton *)sender {
    [self dismissController:self];
    [self.delegate uploadAdvancedSettingCancelButtonTapped:sender];
}

- (IBAction)buttonSaveTapped:(NSButton *)sender {
    if (self.delegate != nil){
        [self.delegate uploadAdvancedSettingSaveButtonTapped:sender];
    }
    
    if(![self.dbFolderNameTextField.stringValue isEqualToString:self.ipaUploadInfo.identifer] && self.dbFolderNameTextField.stringValue.length>0){
        NSString *bundlePath = [NSString stringWithFormat:@"/%@",self.dbFolderNameTextField.stringValue];
        bundlePath = [bundlePath stringByReplacingOccurrencesOfString:@" " withString:abEmptyString];
        [self.ipaUploadInfo setBundleDirectory:[NSURL URLWithString:bundlePath]];
    }

    [self dismissController:self];
}





@end
