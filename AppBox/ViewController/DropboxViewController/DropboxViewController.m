//
//  DropboxViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 28/11/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "DropboxViewController.h"

@interface DropboxViewController ()

- (IBAction)buttonQuitTapped:(NSButton *)sender;

@end

@implementation DropboxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Log Screen
    [EventTracker logScreen:@"Dropbox Login"];
    
    //DB Authentication Notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLoggedInNotification:) name:abDropBoxLoggedInNotification object:nil];
}

- (IBAction)buttonConnectDropboxTapped:(NSButton *)sender {
    [EventTracker logEventWithType:LogEventTypeAuthDropbox];
    //Authenticate user
    [DBClientsManager authorizeFromControllerDesktop:[NSWorkspace sharedWorkspace] controller:self openURL:^(NSURL * _Nonnull url) {
        [[NSWorkspace sharedWorkspace] openURL:url];
    }];
}

- (IBAction)buttonQuitTapped:(NSButton *)sender {
    [EventTracker logEventWithType:LogEventTypeExitWithoutAuth];
    [self dismissController:self];
    [NSApp terminate:self];
}

#pragma mark - Event Handler
- (void)handleLoggedInNotification:(NSNotification *)notification{
    [[NSApplication sharedApplication] updateDropboxUsage];
    [self dismissController:self];
}



@end
