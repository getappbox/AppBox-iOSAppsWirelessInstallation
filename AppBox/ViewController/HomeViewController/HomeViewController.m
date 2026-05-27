//
//  HomeViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 29/08/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "HomeViewController.h"
#import <Network/Network.h>

@interface HomeViewController()

@property (nonatomic, assign) BOOL isCLIActive;
@property (nonatomic, strong) IPAUploadInfo *ipaUploadInfo;
@property (nonatomic, strong) UploadManager *uploadManager;
@property (nonatomic, assign) NSInteger processExecuteCount;

@end

@implementation HomeViewController{
    nw_path_monitor_t _pathMonitor;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.ipaUploadInfo = [[IPAUploadInfo alloc] init];
    buildOptionBoxHeightConstraint.constant = 0;
    
    //Notification Handler
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initCLIUpload:) name:abBuildRepoNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropboxLogoutHandler:) name:abDropBoxLoggedOutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLoggedInNotification:) name:abDropBoxLoggedInNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initOpenFilesProcess:) name:abUseOpenFilesNotification object:nil];
    
    //setup dropbox
    [UploadManager setupDBClientsManager];
    [self setupUploadManager];
    
    //update cli tool and user account menu details
	[[NSApplication sharedApplication] updateCLIMenu];
    [[NSApplication sharedApplication] updateAccountsMenu];

    //Start monitoring internet connection
    weakify(self);
    _pathMonitor = nw_path_monitor_create();
    nw_path_monitor_set_queue(_pathMonitor, dispatch_get_main_queue());
    nw_path_monitor_set_update_handler(_pathMonitor, ^(nw_path_t _Nonnull path) {
        strongify(self);
        BOOL connected = (nw_path_get_status(path) == nw_path_status_satisfied);
        [[AppDelegate appDelegate] setIsInternetConnected:connected];
        if ([AppDelegate appDelegate].processing){
            if (!connected){
                [self showStatus:abNotConnectedToInternet andShowProgressBar:YES withProgress:-1];
            }else{
                //[self showStatus:abConnectedToInternet andShowProgressBar:NO withProgress:-1];
                //restart last failed operation
                if (self.uploadManager.lastfailedOperation){
                    [self.uploadManager.lastfailedOperation start];
                    self.uploadManager.lastfailedOperation = nil;
                }
            }
        }
    });
    nw_path_monitor_start(_pathMonitor);
}

- (void)viewWillAppear{
    [super viewWillAppear];
    [self updateMenuButtons];
    
    //Handle Dropbox Login
    if ([DBClientsManager authorizedClient] == nil) {
        [self performSegueWithIdentifier:@"DropBoxLogin" sender:self];
    } else {
        [[[DBClientsManager authorizedClient].usersRoutes getCurrentAccount] setResponseBlock:^(DBUSERSFullAccount * _Nullable result, DBNilObject * _Nullable routeError, DBRequestError * _Nullable networkError) {
            if (result) {
                [[Common currentDBManager] registerUserId:result.email];
            } else if (networkError.tag == DBRequestErrorAuth) {
				[[NSNotificationCenter defaultCenter] postNotificationName:abDropBoxLoggedOutNotification object:self];
			}
        }];
    }
    [[AppDelegate appDelegate] setIsReadyToUpload:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:abAppBoxReadyToUseNotification object:self];
}

-(void)viewDidAppear {
	[super viewDidAppear];

	//update cli tool if needed
	if ([CLISupportHelper updatePromptAfterVersionUpdate]) {
		[[NSApplication sharedApplication] updateCLIMenu];
	}
}

//MARK: - Upload Manager
-(void)setupUploadManager{
    self.uploadManager = [[UploadManager alloc] init];
    [self.uploadManager setIpaUploadInfo:self.ipaUploadInfo];
    [self.uploadManager setIsCLIActive:self.isCLIActive];
    [self.uploadManager setCurrentViewController:self];
    
    weakify(self);
    [self.uploadManager setProgressBlock:^(NSString *title){
        
    }];
    
    [self.uploadManager setErrorBlock:^(NSError *error, BOOL terminate){
        strongify(self);
        if (terminate && self.isCLIActive) {
            [AppDelegate terminateWithExitCode:abExitCodeForUploadFailed];
        }
        if (terminate) {
            [self viewStateForProgressFinish:YES];
        }
    }];
    
    [self.uploadManager setItcLoginBlock:^(){
        strongify(self);
        [self performSegueWithIdentifier:@"ITCLogin" sender:self];
    }];
    
    [self.uploadManager setCompletionBlock:^(){
        strongify(self);
		[self showUploadCompleteNotification];
        [self exportSharedURLInSystemFile];
		[self shareURLOnSlackMSTeamChannel];

		weakify(self);
		[self shareURLOnEmailComplition:^(BOOL success) {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				strongify(self);
				[self showLinkViewControllerIfNeededWithExitCode:success ? abExitCodeForSuccess : abExitCodeForMailFailed];
			});
		}];
    }];
}


//MARK: - Build Repo / Open Files Notification
- (void)initCLIUpload:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[IPAUploadInfo class]]) {
        [self initCLIUploadProcessWithIPAUploadInfo:[notification object]];
    }
}

- (void)initOpenFilesProcess:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[NSString class]]) {
        NSURL *fileURL = [notification.object ipaURL];
        if (fileURL) {
            [selectedFilePath setURL:fileURL.filePathURL];
            [self selectedFilePathHandler:selectedFilePath];
            return;
        }
    }
}

- (void)exportSharedURLInSystemFile{
    if (self.isCLIActive) {
        [self.ipaUploadInfo exportSharedURLInSystemFile];
    }
}

//MARK: - Controls Action Handler -
#pragma mark → Project / Workspace Controls Action
//Project Path Handler
- (IBAction)selectedFilePathHandler:(NSPathControl *)sender {
    NSURL *url = [sender.URL filePathURL];
    if (url.isIPA && ![self.ipaUploadInfo.ipaFullPath isEqual:url]) {
        [self viewStateForProgressFinish:YES];
        [self.ipaUploadInfo setIpaFullPath: url];
        [selectedFilePath setURL:url];
        [self updateViewState];
		
		//Get last time valid data
		BOOL enable = selectedFilePath.URL.isIPA;
		[textFieldEmail setStringValue: enable ? [UserData userEmail] : abEmptyString];
		[textFieldMessage setStringValue: enable ? [UserData userMessage] : abEmptyString];
    }
}

- (void)initCLIUploadProcessWithIPAUploadInfo:(IPAUploadInfo *)ipaUploadInfo {
    NSURL *ipaURL = ipaUploadInfo.ipaFullPath;
    if (ipaURL == nil) {
        return;
    }

	self.isCLIActive = YES;
	self.ipaUploadInfo = ipaUploadInfo;
    [self.ipaUploadInfo setIpaFullPath:ipaURL];
	[self.uploadManager setIpaUploadInfo:self.ipaUploadInfo];
    [selectedFilePath setURL:ipaURL];
    if (ipaUploadInfo.emails.length != 0) {
        [textFieldEmail setStringValue:ipaUploadInfo.emails];
    }
    if (ipaUploadInfo.personalMessage.length != 0) {
        [textFieldMessage setStringValue:ipaUploadInfo.personalMessage];
    }
	[buttonUniqueLink setState:ipaUploadInfo.keepSameLink.boolValue ? NSControlStateValueOn : NSControlStateValueOff];
	[self buttonUniqueLinkTapped:buttonUniqueLink];
    [self actionButtonTapped:buttonAction];
}

#pragma mark → IPA File Controlles Actions
//IPA File Path Handler

- (IBAction)buttonUniqueLinkTapped:(NSButton *)sender{
	self.ipaUploadInfo.isKeepSameLinkEnabled = (sender.state == NSControlStateValueOn);
}

- (IBAction)buttonSameLinkHelpTapped:(NSButton *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:abKeepSameLinkReadMoreURL]];
}


#pragma mark → Mail Controls Action

//email id text field
- (IBAction)textFieldMailValueChanged:(NSTextField *)sender {
    //removed spaces
    [sender setStringValue: [sender.stringValue stringByReplacingOccurrencesOfString:@" " withString:abEmptyString]];
    
    //check all mails vaild or not and setup mailed option based on this
    BOOL isAllMailVaild = sender.stringValue.length > 0 && [MailHandler isAllValidEmail:sender.stringValue];
    if (isAllMailVaild){
        [self.ipaUploadInfo setEmails:sender.stringValue];
    } else if (sender.stringValue.length > 0) {
        [MailHandler showInvalidEmailAddressAlert];
    }
}

//developer message text field
- (IBAction)textFieldDevMessageValueChanged:(NSTextField *)sender {
	[self.ipaUploadInfo setPersonalMessage:sender.stringValue];
}

#pragma mark → Final Action Button (Build/IPA/CI)
//Build Button Action
- (IBAction)actionButtonTapped:(NSButton *)sender {
    if (textFieldEmail.stringValue.isEmpty || [MailHandler isAllValidEmail:textFieldEmail.stringValue]){
        if ([AppDelegate appDelegate].processing){
			DDLogInfo(@"A request already in progress.");
            return;
        }
        
        //set processing flag
        [[AppDelegate appDelegate] setProcessing:true];
        [[textFieldEmail window] makeFirstResponder:self.view];

		// start upload process
        [self.uploadManager uploadIPAFile:self.ipaUploadInfo.ipaFullPath];
        [self viewStateForProgressFinish:![AppDelegate appDelegate].processing];
    }else{
        [MailHandler showInvalidEmailAddressAlert];
    }
}


//MARK: - Dropbox Helper -
#pragma mark → Dropbox Notification Handler
- (void)handleLoggedInNotification:(NSNotification *)notification{
    [self updateMenuButtons];
    [self viewStateForProgressFinish:YES];
	[self promptCLIInstallIfNeeded];
}

- (void)dropboxLogoutHandler:(id)sender{
    //handle dropbox logout for authorized users
    if ([DBClientsManager authorizedClient]){
        [DBClientsManager unlinkAndResetClients];
		
		//update home view state
        [self viewStateForProgressFinish:YES];
		
		//reset logged in user details and update accounts menu
		[UserData setDropboxUsedSpace:@0];
		[UserData setDropboxAvailableSpace:@0];
		[UserData setLoggedInUserEmail:@""];
		[UserData setLoggedInUserDisplayName:@""];
		[[NSApplication sharedApplication] updateAccountsMenu];
        
		//show login page
		[self performSegueWithIdentifier:@"DropBoxLogin" sender:self];
    }
}

- (void)promptCLIInstallIfNeeded{
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		if (![[NSFileManager defaultManager] fileExistsAtPath:abCLIPath]) {
			[CLISupportHelper installPromptAfterLogin];
		}
	});
}


//MARK: - Controller Helpers -

-(void)viewStateForProgressFinish:(BOOL)finish{
    DDLogDebug(@"Updating view setting for finish - %@", [NSNumber numberWithBool:finish]);
    [[AppDelegate appDelegate] setProcessing:!finish];
    [[AppDelegate appDelegate] setIsReadyToUpload:finish];
    
    //reset ipa upload info
    if (finish){
        self.ipaUploadInfo = [[IPAUploadInfo alloc] init];
        [self.uploadManager setIpaUploadInfo:self.ipaUploadInfo];
        [ABHudViewController hudForView:self.view hide:YES];
        buildOptionBoxHeightConstraint.constant = 0;
    }
    
    //unique link
    [buttonUniqueLink setEnabled:finish];
	[buttonUniqueLink setState: finish ? NSControlStateValueOff : buttonUniqueLink.state];

    //ipa
    [selectedFilePath setEnabled:finish];
    [selectedFilePath setURL: finish ? nil : selectedFilePath.URL.filePathURL];
    
    //action button
    [self updateViewState];
    
    //logout buttons
    [self updateMenuButtons];
}

-(void)showStatus:(NSString *)status andShowProgressBar:(BOOL)showProgressBar withProgress:(double)progress{
    //log status in session log
	DDLogInfo(@"%@",status);
    
    //start/stop/progress based on showProgressBar and progress
    if (progress == -1){
        if (showProgressBar){
            [ABHudViewController showStatus:status onView:self.view];
        }else{
            [ABHudViewController showOnlyStatus:status onView:self.view];
        }
    }else{
        if (showProgressBar){
            [ABHudViewController showStatus:status witProgress:progress onView:self.view];
        }else{
            [ABHudViewController showOnlyStatus:status onView:self.view];
        }
    }
}

-(void)updateViewState{
	//Update menu buttons
	[self updateMenuButtons];

	
	BOOL enable = selectedFilePath.URL.isIPA;
	
	//Enable text fields
	[textFieldEmail setEnabled:enable];
	[textFieldMessage setEnabled:enable];
	
	//Reset text field content
	[textFieldEmail setStringValue: enable ? textFieldEmail.stringValue : abEmptyString];
	[textFieldMessage setStringValue: enable ? textFieldMessage.stringValue : abEmptyString];
	
	//Just for confirm changes
	[self textFieldMailValueChanged:textFieldEmail];
	[self textFieldDevMessageValueChanged:textFieldMessage];
	
	//update main action button
    [buttonAction setEnabled:enable];
    [buttonAction setTitle:@"Upload IPA"];
    
    //update keepsame link
    [buttonUniqueLink setEnabled:(enable && ![[AppDelegate appDelegate] processing])];
    
    //update advanced button
    [buttonAdvanced setEnabled:enable];
    
}

-(void)updateMenuButtons{
    //Menu Buttons
    BOOL enable = ([DBClientsManager authorizedClient] && selectedFilePath.enabled);
    [[[AppDelegate appDelegate] dropboxLogoutButton] setEnabled:enable];
}

//get optional feature enable/disable dictionary
-(NSDictionary *)getBasicViewStateWithOthersSettings:(NSDictionary *)otherSettings{
    if (otherSettings == nil){
        otherSettings = @{};
    }
    NSMutableDictionary *viewState = [[NSMutableDictionary alloc] initWithDictionary:otherSettings];
    [viewState setValue:[NSNumber numberWithInteger: buttonUniqueLink.state] forKey:@"Same Link"];
    return viewState;
}

//MARK: - TabView Delegate -
-(void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem{
    //update view state based on selected tap
    [self updateViewState];
}

-(BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem{
    return ![AppDelegate appDelegate].processing;
}

//MARK: - ProjectAdvancedViewDelegate - 
- (void)uploadAdvancedSettingSaveButtonTapped:(NSButton *)sender{

}

- (void)uploadAdvancedSettingCancelButtonTapped:(NSButton *)sender{
    
}

//MARK: - Share URL -
-(void)showUploadCompleteNotification {
	if (self.isCLIActive) {
		return;
	}
	[Common showUploadNotificationWithName:self.ipaUploadInfo.name andURL:self.ipaUploadInfo.appShortShareableURL];
}

-(void)shareURLOnSlackMSTeamChannel {
	// Share URL on Slack/Microsoft Team Channel
	NSString *message;
	if (self.ipaUploadInfo.webhookMessage) {
		message = self.ipaUploadInfo.webhookMessage;
	} else {
		message = [UserData userSlackMessage];
	}

	NSString *slackWebhook;
	if (self.ipaUploadInfo.slackWebhook) {
		slackWebhook = self.ipaUploadInfo.slackWebhook;
	} else {
		slackWebhook = [UserData userSlackChannel];
	}
	if (slackWebhook.length > 0){
		[self showStatus:@"Sending Message on Slack..." andShowProgressBar:YES withProgress:-1];
		[SlackClient sendMessage:self.ipaUploadInfo
						 webhook:slackWebhook
						 message:message
					  completion:^(BOOL success) {}];
	}

	NSString *msTeamWebhook;
	if (self.ipaUploadInfo.msTeamsWebhook) {
		msTeamWebhook = self.ipaUploadInfo.msTeamsWebhook;
	} else {
		msTeamWebhook = [UserData userMicrosoftTeamWebHook];
	}
	if (msTeamWebhook.length > 0){
		[self showStatus:@"Sending Message on Microsoft Team..." andShowProgressBar:YES withProgress:-1];
		[MSTeamsClient sendMessage:self.ipaUploadInfo
						   webhook:msTeamWebhook
						   message:message
						completion:^(BOOL success) {}];
	}
}

-(void)shareURLOnEmailComplition:(void (^) (BOOL success))completion  {
	if (textFieldEmail.stringValue.length > 0 && [MailHandler isAllValidEmail:textFieldEmail.stringValue]) {
		[self showStatus:@"Sending Mail..." andShowProgressBar:YES withProgress:-1];
		[MailGun sendMailWithIPAUploadInfo:self.ipaUploadInfo.abpIPAUploadInfo complition:^(BOOL success, NSError *error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				if (success) {
					[ABHudViewController showStatus:@"Mail Sent" forSuccess:YES onView:self.view];
					completion(YES);
				} else {
					[ABHudViewController showStatus:@"Mail Failed" forSuccess:NO onView:self.view];
					completion(NO);
				}
			});
		}];
	} else {
		completion(YES);
	}
}

-(void)showLinkViewControllerIfNeededWithExitCode:(int)exitCode {
	DDLogInfo(@"\n\n\nSHARE URL - %@\n\n\n.", self.ipaUploadInfo.appShortShareableURL);
	if (self.isCLIActive){
		[self viewStateForProgressFinish:YES];
		[AppDelegate terminateWithExitCode:exitCode];
	}else{
		[self performSegueWithIdentifier:@"ShowLink" sender:self];
	}
}

//MARK: - Navigation -
-(void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender{
    //prepare to show link
    if ([segue.destinationController isKindOfClass:[ShowLinkViewController class]]) {
        //set ipa upload info to destination
        [((ShowLinkViewController *)segue.destinationController) setIpaUploadInfo:self.ipaUploadInfo];
        [self viewStateForProgressFinish:YES];
    }
    
    //prepare to show advanced upload settings
    else if([segue.destinationController isKindOfClass:[UploadAdvancedSettingViewController class]]){
        UploadAdvancedSettingViewController *projectAdvancedViewController = ((UploadAdvancedSettingViewController *)segue.destinationController);
        [projectAdvancedViewController setIpaUploadInfo:self.ipaUploadInfo];
        [projectAdvancedViewController setDelegate:self];
    }
}

@end
