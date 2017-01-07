//
//  NSApplication+MenuHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 02/01/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "NSApplication+MenuHandler.h"

@implementation NSApplication (MenuHandler)

- (IBAction)logoutGmailTapped:(NSMenuItem *)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText: @"Are you sure?"];
    [alert setInformativeText:@"Do you want to logout current gmail account?"];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"No"];
    if ([alert runModal] == NSAlertFirstButtonReturn){
        [sender setEnabled:NO];
        [UserData setIsGmailLoggedIn:NO];
        [KeychainHandler removeAllStoredCredentials];
        [[NSNotificationCenter defaultCenter] postNotificationName:abGmailLoggedOutNotification object:sender];
    }
}

- (IBAction)logoutDropBoxTapped:(NSMenuItem *)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText: @"Are you sure?"];
    [alert setInformativeText:@"Do you want to logout current dropbox account?"];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"No"];
    if ([alert runModal] == NSAlertFirstButtonReturn){
        [[NSNotificationCenter defaultCenter] postNotificationName:abDropBoxLoggedOutNotification object:sender];
        [sender setEnabled:NO];
    }
}
@end
