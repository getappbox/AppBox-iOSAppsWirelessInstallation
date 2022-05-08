//
//  DropboxViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 28/11/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "DropboxViewController.h"


@implementation DropboxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Log Screen
    [EventTracker logScreen:@"Dropbox Login"];
    
    //DB Authentication Notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLoggedInNotification:) name:abDropBoxLoggedInNotification object:nil];
	
	//Set quit button title
	[buttonQuit setTitle:[UserData isLoggedIn] ? @"Cancel" : @"Quit"];
}

- (IBAction)buttonConnectDropboxTapped:(NSButton *)sender {
    [EventTracker logEventWithType:LogEventTypeAuthDropbox];
    
	//Authenticate user
	[DBClientsManager authorizeFromControllerDesktopV2:[NSWorkspace sharedWorkspace] controller:self loadingStatusDelegate:nil openURL:^(NSURL * _Nonnull url) {
		[[NSWorkspace sharedWorkspace] openURL:url];
	} scopeRequest:nil];
}

- (IBAction)buttonQuitTapped:(NSButton *)sender {
    [EventTracker logEventWithType:LogEventTypeExitWithoutAuth];
    [self dismissController:self];
	if (![UserData isLoggedIn]) {
		[NSApp terminate:self];
	}
}

//MARK: - Event Handler
- (void)handleLoggedInNotification:(NSNotification *)notification{
    [[NSApplication sharedApplication] updateDropboxUsage];
    [self dismissController:self];
}



@end
