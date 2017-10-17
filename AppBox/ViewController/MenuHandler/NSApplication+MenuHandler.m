//
//  NSApplication+MenuHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 02/01/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "NSApplication+MenuHandler.h"

@implementation NSApplication (MenuHandler)


#pragma mark - AppBox
- (IBAction)checkForUpdateTapped:(NSMenuItem *)sender {
    [UpdateHandler isNewVersionAvailableCompletion:^(bool available, NSURL *url) {
        if (available){
            [UpdateHandler showUpdateAlertWithUpdateURL:url];
        }else{
            [UpdateHandler showAlreadyUptoDateAlert];
        }
    }];
}


- (IBAction)preferencesTapped:(NSMenuItem *)sender {
    [PreferencesTabViewController presentPreferences];
}

#pragma mark - File
- (void)updateDropboxUsage{
    [self updateDropboxUsageFileButton];
    
    //get spaces usage
    [[[DBClientsManager authorizedClient].usersRoutes getSpaceUsage]
     setResponseBlock:^(DBUSERSSpaceUsage * _Nullable response, DBNilObject * _Nullable routeError, DBRequestError * _Nullable error) {
         if (response){
             @try {
                 NSNumber *usage = @(response.used.longValue / abBytesToMB);
                 NSNumber *allocated = @(response.allocation.individual.allocated.longValue / abBytesToMB);
                 
                 //save space usage in user default
                 [UserData setDropboxUsedSpace:usage];
                 [UserData setDropboxAvailableSpace:allocated];
                 [self updateDropboxUsageFileButton];
                 
                 //log space usage
                 [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Used Space : %@MB", usage]];
                 [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Available Space : %@MB", allocated]];
                 
                 //check if dopbox running out of space
                 if ((allocated.integerValue - usage.integerValue) < abDropboxOutOfSpaceWarningSize){
                     [Common showAlertWithTitle:@"Warning" andMessage:[NSString stringWithFormat:@"You're running out of Dropbox space\n\n %@MB of %@MB used.", usage, allocated]];
                 }
             } @catch (NSException *exception) {
                 [EventTracker logEventWithName:@"Exception" customAttributes:@{@"error desc": exception.debugDescription} action:@"error desc" label:exception.debugDescription value:@1];
             }
         } else if (error.tag == DBRequestErrorAuth) {
             [[NSNotificationCenter defaultCenter] postNotificationName:abDropBoxLoggedOutNotification object:self];
         }
     }];
}

- (void)updateDropboxUsageFileButton{
    NSNumber *used = [UserData dropboxUsedSpace];
    NSNumber *availabel = [UserData dropboxAvailableSpace];
    [[[AppDelegate appDelegate] dropboxSpaceButton] setTitle:[NSString stringWithFormat:@"Dropbox Usage : %@MB of %@MB used", used, availabel]];
}

#pragma mark - Accounts
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
- (IBAction)dropboxSpaceTapped:(NSMenuItem *)sender {
    [self updateDropboxUsage];
}

#pragma mark - Help
- (IBAction)helpButtonTapped:(NSMenuItem *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:abDocumentationURL]];
    [EventTracker logEventWithName:@"External Links" customAttributes:@{@"title":@"Help"} action:@"title" label:@"Help" value:@1];
}

- (IBAction)latestNewsTapped:(NSMenuItem *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:abTwitterURL]];
    [EventTracker logEventWithName:@"External Links" customAttributes:@{@"title":@"Twitter"} action:@"title" label:@"Twitter" value:@1];
}

- (IBAction)releaseNotesTapped:(NSMenuItem *)sender {
    [EventTracker logEventWithName:@"External Links" customAttributes:@{@"title":@"Release Notes"} action:@"title" label:@"Release Notes" value:@1];
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",abGitHubReleaseBaseURL,versionString]]];
}

- (IBAction)showDashboardTapped:(NSMenuItem *)sender {
}

- (IBAction)licenseTapped:(NSMenuItem *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:abLicenseURL]];
    [EventTracker logEventWithName:@"External Links" customAttributes:@{@"title":@"License"} action:@"title" label:@"License" value:@1];
}
@end
