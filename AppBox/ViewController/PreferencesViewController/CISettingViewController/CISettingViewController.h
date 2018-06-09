//
//  CISettingViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 13/01/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CISettingViewController : NSViewController{
    __weak IBOutlet NSButton *updateAlertCheckBox;
    __weak IBOutlet NSButton *limitedLogCheckBox;
    __weak IBOutlet NSButton *copyBuildArtifactsCheckBox;
}
- (IBAction)updateAlertCheckBoxChanged:(NSButton *)sender;
- (IBAction)limitedLogCheckBoxChanged:(NSButton *)sender;
- (IBAction)copyBuildArtifactsCheckBoxChanged:(NSButton *)sender;

@end
