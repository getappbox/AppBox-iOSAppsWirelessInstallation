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
	[limitedLogCheckBox setState: [UserData debugLog] ? NSControlStateValueOff : NSControlStateValueOn];
	[updateAlertCheckBox setState: [UserData updateAlertEnable] ? NSControlStateValueOn : NSControlStateValueOff];
	[defaultIPAHandlerCheckBox setState: [DefaultAppHandler isDefaultIPAHandler] ? NSControlStateValueOn : NSControlStateValueOff];
    
    // Observe default IPA handler changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultIPAHandlerDidChange:)
                                                 name:ABDefaultIPAHandlerDidChangeNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ABDefaultIPAHandlerDidChangeNotification object:nil];
}

- (IBAction)chunckSizeComboBoxValueChanged:(NSComboBox *)sender {
    [UserData setUploadChunkSize:[chunkSizes[[sender indexOfSelectedItem]] integerValue]];
}

- (IBAction)downloadIPACheckBoxValueChanged:(NSButton *)sender {
	[UserData setDownloadIPAEnable:(sender.state == NSControlStateValueOn)];
}

- (IBAction)moreDetailsCheckBoxValueChanged:(NSButton *)sender {
	[UserData setMoreDetailsEnable:(sender.state == NSControlStateValueOn)];
}

- (IBAction)showPreviousVersionCheckBoxValueChanged:(NSButton *)sender {
	[UserData setShowPreviousVersions:(sender.state == NSControlStateValueOff)];
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
	[UserData setUpdateAlertEnable:(sender.state == NSControlStateValueOn)];
}

- (IBAction)limitedLogCheckBoxChanged:(NSButton *)sender {
	[UserData setEnableDebugLog:(sender.state != NSControlStateValueOn)];
}

- (IBAction)defaultIPAHandlerCheckBoxChanged:(NSButton *)sender {
	if (sender.state == NSControlStateValueOn) {
		[DefaultAppHandler setAsDefaultIPAHandler];
	} else {
		[DefaultAppHandler removeAsDefaultIPAHandler];
	}
}

- (void)defaultIPAHandlerDidChange:(NSNotification *)notification {
    BOOL isDefault = [notification.userInfo[@"isDefault"] boolValue];
    [defaultIPAHandlerCheckBox setState:isDefault ? NSControlStateValueOn : NSControlStateValueOff];
}

@end
