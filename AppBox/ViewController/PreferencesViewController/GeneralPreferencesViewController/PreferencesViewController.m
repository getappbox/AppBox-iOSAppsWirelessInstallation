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

@implementation PreferencesViewController {
    NSArray *chunkSizes;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    chunkSizes = @[@10, @25, @50, @75, @100, @125, @150];
	
    //set settings
    [downloadIPAButton setState:[UserData downloadIPAEnable]];
    [moreDetailsButton setState:[UserData moreDetailsEnable]];
    [showPerviousBuildsButton setState:![UserData showPreviousVersions]];
    
    NSNumber *chunkSize = [NSNumber numberWithInteger:[UserData uploadChunkSize]];
    [chunkSizeComboBox selectItemAtIndex:[chunkSizes indexOfObject:chunkSize]];
	
	//set general settings
	[limitedLogCheckBox setState: [UserData debugLog] ? NSOnState : NSOffState];
	[updateAlertCheckBox setState: [UserData updateAlertEnable] ? NSOnState : NSOffState];
}

- (IBAction)chunckSizeComboBoxValueChanged:(NSComboBox *)sender {
    [UserData setUploadChunkSize:[chunkSizes[[sender indexOfSelectedItem]] integerValue]];
}

- (IBAction)downloadIPACheckBoxValueChanged:(NSButton *)sender {
    [UserData setDownloadIPAEnable:(sender.state == NSOnState)];
}

- (IBAction)moreDetailsCheckBoxValueChanged:(NSButton *)sender {
    [UserData setMoreDetailsEnable:(sender.state == NSOnState)];
}

- (IBAction)showPreviousVersionCheckBoxValueChanged:(NSButton *)sender {
    [UserData setShowPreviousVersions:(sender.state == NSOffState)];
}

- (IBAction)helpDownloadIPAButtonAction:(NSButton *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:abDownloadIPAHelpURL]];
}

- (IBAction)helpMoreInformationAction:(NSButton *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:abMoreDetailsHelpURL]];
}

- (IBAction)helpDontShowPerviousBuildAction:(NSButton *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:abDontShowPerviousBuildURL]];
}

- (IBAction)helpUploadChunkSizeAction:(NSButton *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:abUploadChunkSizeHelpURL]];
}

- (IBAction)updateAlertCheckBoxChanged:(NSButton *)sender {
	[UserData setUpdateAlertEnable:(sender.state == NSOnState)];
}

- (IBAction)limitedLogCheckBoxChanged:(NSButton *)sender {
	[UserData setEnableDebugLog:(sender.state == NSOnState)];
}

@end
