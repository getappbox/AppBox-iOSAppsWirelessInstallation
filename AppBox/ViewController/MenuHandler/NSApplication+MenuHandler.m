//
//  NSApplication+MenuHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 02/01/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "NSApplication+MenuHandler.h"

@implementation NSApplication (MenuHandler)


//MARK: - AppBox
- (IBAction)checkForUpdateTapped:(NSMenuItem *)sender {
    [UpdateHandler isNewVersionAvailableCompletion:^(bool available, NSURL *url) {
        if (available){
            [UpdateHandler showUpdateAlertWithUpdateURL:url];
        }else{
            [UpdateHandler showAlreadyUptoDateAlert];
        }
    }];
}

//MARK: - File
- (IBAction)viewLogFileTapped:(NSMenuItem *)sender {
	[[AppDelegate appDelegate] openLatestLogFile];
}

- (IBAction)preferencesTapped:(NSMenuItem *)sender {
    [PreferencesTabViewController presentPreferences];
}

//MARK: - Accounts
- (void)updateAccountsMenu{
    [self updateDropboxButton];
	
	//get user account details
	[[[DBClientsManager authorizedClient].usersRoutes getCurrentAccount] setResponseBlock:^(DBUSERSFullAccount * _Nullable result, DBNilObject * _Nullable routeError, DBRequestError * _Nullable networkError) {
		if (result) {
			@try {
				[UserData setLoggedInUserEmail:result.email];
				[UserData setLoggedInUserDisplayName:result.name.displayName];
				[self updateDropboxButton];
			} @catch (NSException *exception) {
				[EventTracker logExceptionEvent:exception];
			}
		}
	}];
    
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
                 [self updateDropboxButton];
                 
                 //log space usage
				 DDLogInfo(@"DropBox Used Space : %@MB", usage);
				 DDLogInfo(@"DropBox Available Space : %@MB", allocated);
                 
                 //check if dopbox running out of space
                 if ((allocated.integerValue - usage.integerValue) < abDropboxOutOfSpaceWarningSize){
                     [Common showAlertWithTitle:@"Warning" andMessage:[NSString stringWithFormat:@"You're running out of Dropbox space\n\n %@MB of %@MB used.", usage, allocated]];
                 }
             } @catch (NSException *exception) {
                 [EventTracker logExceptionEvent:exception];
             }
         }
     }];
}

- (void)updateDropboxButton{
	//Dropbox account menu
	NSString *email = [UserData loggedInUserEmail];
	
	NSMenuItem *dropboxAccountButton = [[AppDelegate appDelegate] dropboxAccountButton];
	NSString *dropboxAccountButtonTitle = [NSString stringWithFormat:@"Email: %@", email];
	[dropboxAccountButton setHidden:email.isEmpty];
	[dropboxAccountButton setTitle:dropboxAccountButtonTitle];
	
	//Dropbox account name menu
	NSString *displayName = [UserData loggedInUserDisplayName];
	NSMenuItem *dropboxNameButton = [[AppDelegate appDelegate] dropboxNameButton];
	NSString *dropboxNameButtonTitle = [NSString stringWithFormat:@"Name: %@", displayName];
	[dropboxNameButton setHidden:displayName.isEmpty];
	[dropboxNameButton setTitle:dropboxNameButtonTitle];
	
	//Dropbox space menu
    NSNumber *used = [UserData dropboxUsedSpace];
    NSNumber *available = [UserData dropboxAvailableSpace];
	
	NSMenuItem *dropboxSpaceButton = [[AppDelegate appDelegate] dropboxSpaceButton];
	NSString *dropboxSpaceButtonTitle = [NSString stringWithFormat:@"Usage: %@MB of %@MB used", used, available];
    [dropboxSpaceButton setTitle:dropboxSpaceButtonTitle];
}

- (IBAction)logoutDropBoxTapped:(NSMenuItem *)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText: @"Are you sure?"];
    [alert setInformativeText:@"Do you want to logout current dropbox account?"];
	[alert setAlertStyle:NSAlertStyleInformational];
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"No"];
    if ([alert runModal] == NSAlertFirstButtonReturn){
        [[NSNotificationCenter defaultCenter] postNotificationName:abDropBoxLoggedOutNotification object:sender];
        [sender setEnabled:NO];
    }
}

- (IBAction)dropboxSpaceTapped:(NSMenuItem *)sender {
    [self updateAccountsMenu];
}

//MARK: - Help
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
