//
//  PreferencesViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 27/03/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesViewController : NSViewController {
    __weak IBOutlet NSComboBox *chunkSizeComboBox;
    __weak IBOutlet NSButton *downloadIPAButton;
    __weak IBOutlet NSButton *moreDetailsButton;
    __weak IBOutlet NSButton *showPerviousBuildsButton;
	
	__weak IBOutlet NSButton *updateAlertCheckBox;
	__weak IBOutlet NSButton *limitedLogCheckBox;
}

//AppBox Upload Settings
- (IBAction)chunckSizeComboBoxValueChanged:(NSComboBox *)sender;
- (IBAction)downloadIPACheckBoxValueChanged:(NSButton *)sender;
- (IBAction)moreDetailsCheckBoxValueChanged:(NSButton *)sender;
- (IBAction)showPreviousVersionCheckBoxValueChanged:(NSButton *)sender;

//Help Buttons Action
- (IBAction)helpDownloadIPAButtonAction:(NSButton *)sender;
- (IBAction)helpMoreInformationAction:(NSButton *)sender;
- (IBAction)helpDontShowPerviousBuildAction:(NSButton *)sender;
- (IBAction)helpUploadChunkSizeAction:(NSButton *)sender;

//General
- (IBAction)updateAlertCheckBoxChanged:(NSButton *)sender;
- (IBAction)limitedLogCheckBoxChanged:(NSButton *)sender;


@end
