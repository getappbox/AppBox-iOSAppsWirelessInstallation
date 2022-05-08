//
//  NSApplication+MenuHandler.h
//  AppBox
//
//  Created by Vineet Choudhary on 02/01/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PreferencesTabViewController.h"

@interface NSApplication (MenuHandler)

//AppBox
- (IBAction)preferencesTapped:(NSMenuItem *)sender;
- (IBAction)checkForUpdateTapped:(NSMenuItem *)sender;

//File
- (IBAction)showDashboardTapped:(NSMenuItem *)sender;
- (IBAction)showLocalServerTapped:(NSMenuItem *)sender;

//Accounts
- (void)updateAccountsMenu;
- (IBAction)dropboxSpaceTapped:(NSMenuItem *)sender;
- (IBAction)logoutDropBoxTapped:(NSMenuItem *)sender;

//Help
- (IBAction)licenseTapped:(NSMenuItem *)sender;
- (IBAction)latestNewsTapped:(NSMenuItem *)sender;
- (IBAction)helpButtonTapped:(NSMenuItem *)sender;
- (IBAction)releaseNotesTapped:(NSMenuItem *)sender;

//Window
@end
