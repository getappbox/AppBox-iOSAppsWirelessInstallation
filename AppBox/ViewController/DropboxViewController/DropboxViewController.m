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
    [Common logScreen:@"Dropbox Login"];
    
    //DB Authentication Notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLoggedInNotification:) name:abDropBoxLoggedInNotification object:nil];
}

- (IBAction)buttonConnectDropboxTapped:(NSButton *)sender {
    [Answers logCustomEventWithName:@"Authenticating Dropbox " customAttributes:nil];
    //Authenticate user
    [DBClientsManager authorizeFromControllerDesktop:[NSWorkspace sharedWorkspace] controller:self openURL:^(NSURL *url){ [[NSWorkspace sharedWorkspace] openURL:url];} browserAuth:YES];
}

- (IBAction)buttonQuitTapped:(NSButton *)sender {
    [Answers logCustomEventWithName:@"AppBox terminated before Dropbox LoggedIN :( " customAttributes:nil];
    [self dismissController:self];
    [NSApp terminate:self];
}

#pragma mark - Event Handler
- (void)handleLoggedInNotification:(NSNotification *)notification{
    [[NSApplication sharedApplication] updateDropboxUsage];
    [self dismissController:self];
}



@end
