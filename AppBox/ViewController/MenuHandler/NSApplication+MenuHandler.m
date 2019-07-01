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
                 [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"DropBox Used Space : %@MB", usage]];
                 [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"DropBox Available Space : %@MB", allocated]];
                 
                 //check if dopbox running out of space
                 if ((allocated.integerValue - usage.integerValue) < abDropboxOutOfSpaceWarningSize){
                     [Common showAlertWithTitle:@"Warning" andMessage:[NSString stringWithFormat:@"You're running out of Dropbox space\n\n %@MB of %@MB used.", usage, allocated]];
                 }
             } @catch (NSException *exception) {
                 [EventTracker logExceptionEvent:exception];
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
    [EventTracker logEventWithType:LogEventTypeExternalLinkHelp];
}

- (IBAction)latestNewsTapped:(NSMenuItem *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:abTwitterURL]];
    [EventTracker logEventWithType:LogEventTypeExternalLinkTwitter];
}

- (IBAction)releaseNotesTapped:(NSMenuItem *)sender {
    [EventTracker logEventWithType:LogEventTypeExternalLinkReleaseNote];
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",abGitHubReleaseBaseURL,versionString]]];
}

- (IBAction)showDashboardTapped:(NSMenuItem *)sender {
}

- (IBAction)showLocalServerTapped:(NSMenuItem *)sender {
}

- (IBAction)licenseTapped:(NSMenuItem *)sender {
    [EventTracker logEventWithType:LogEventTypeExternalLinkLicense];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:abLicenseURL]];
    
}
@end
