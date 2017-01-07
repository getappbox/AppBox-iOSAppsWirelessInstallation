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
    // Do view setup here.
    DBSession *session = [[DBSession alloc] initWithAppKey:abDbAppkey appSecret:abDbScreatkey root:abDbRoot];
    [session setDelegate:self];
    [DBSession setSharedSession:session];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authHelperStateChangedNotification:) name:DBAuthHelperOSXStateChangedNotification object:[DBAuthHelperOSX sharedHelper]];
}

- (IBAction)buttonConnectDropboxTapped:(NSButton *)sender {
    [[DBAuthHelperOSX sharedHelper] authenticate];
}

- (IBAction)buttonQuitTapped:(NSButton *)sender {
    [self dismissController:self];
    [NSApp terminate:self];
}

#pragma mark - DBSession Delegate
- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId{
    [Common showAlertWithTitle:@"Authorization Failed" andMessage:abEmptyString];
}

- (void)authHelperStateChangedNotification:(NSNotification *)notification {
    if ([[DBSession sharedSession] isLinked]) {
        [Answers logLoginWithMethod:@"Dropbox" success:@YES customAttributes:@{}];
        [self dismissController:self];
    }
}


@end
