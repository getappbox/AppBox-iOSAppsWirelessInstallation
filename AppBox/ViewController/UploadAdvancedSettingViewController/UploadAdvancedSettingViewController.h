//
//  UploadAdvancedSettingViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UploadAdvancedSettingViewController;
@protocol UploadAdvancedSettingViewDelegate <NSObject>

- (void)uploadAdvancedSettingSaveButtonTapped:(NSButton *)sender;
- (void)uploadAdvancedSettingCancelButtonTapped:(NSButton *)sender;

@end

@interface UploadAdvancedSettingViewController : NSViewController{
    
}

@property(nonatomic, strong) IPAUploadInfo *ipaUploadInfo;
@property(weak) id <UploadAdvancedSettingViewDelegate> delegate;

@property (weak) IBOutlet NSTextField *dbFolderNameTextField;


- (IBAction)buttonSaveTapped:(NSButton *)sender;
- (IBAction)buttonCancelTapped:(NSButton *)sender;

@end
