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
    __weak IBOutlet NSTextField *defaultEmalTextField;
    __weak IBOutlet NSTextField *subjectPrefixTextField;
    __weak IBOutlet NSTextField *keychainPathTextField;
    __weak IBOutlet NSSecureTextField *keychainPasswordTextField;
    __weak IBOutlet NSTextField *xcodePathTextField;
    __weak IBOutlet NSButton *xcprettyCheckBox;
}
- (IBAction)updateAlertCheckBoxChanged:(NSButton *)sender;
- (IBAction)limitedLogCheckBoxChanged:(NSButton *)sender;
- (IBAction)xcPrettyCheckBoxChanged:(NSButton *)sender;
- (IBAction)emailSettingSaveButtonAction:(NSButton *)sender;
- (IBAction)keychainUnlockButtonAction:(NSButton *)sender;
- (IBAction)xcodeSaveButtonAction:(NSButton *)sender;

@end
