//
//  HomeViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 29/08/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "HomeViewController.h"

@interface HomeViewController()

@property (nonatomic, strong) XCProject *project;
@property (nonatomic, strong) XCProject *ciRepoProject;
@property (nonatomic, strong) UploadManager *uploadManager;
@property (nonatomic, assign) NSInteger processExecuteCount;

@end

@implementation HomeViewController{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.project = [[XCProject alloc] init];
    buildOptionBoxHeightConstraint.constant = 0;
    
    //Notification Handler
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initCIProcess:) name:abBuildRepoNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropboxLogoutHandler:) name:abDropBoxLoggedOutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLoggedInNotification:) name:abDropBoxLoggedInNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initOpenFilesProcess:) name:abUseOpenFilesNotification object:nil];
    
    //setup dropbox
    [EventTracker logAppBoxVersion];
    [UploadManager setupDBClientsManager];
    [self setupUploadManager];
    
    //update available memory
    [[NSApplication sharedApplication] updateDropboxUsage];
    
    //Start monitoring internet connection
    weakify(self);
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        strongify(self);
        [[AppDelegate appDelegate] setIsInternetConnected:!(status == AFNetworkReachabilityStatusNotReachable)];
        if ([AppDelegate appDelegate].processing){
            if (status == AFNetworkReachabilityStatusNotReachable){
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
    }];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    //Track screen
    [EventTracker logScreen:@"Home Screen"];
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
            }
        }];
    }
    [[AppDelegate appDelegate] setIsReadyToBuild:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:abAppBoxReadyToUseNotification object:self];
}

#pragma mark - Upload Manager
-(void)setupUploadManager{
    self.uploadManager = [[UploadManager alloc] init];
    [self.uploadManager setProject:self.project];
    [self.uploadManager setCiRepoProject:self.ciRepoProject];
    [self.uploadManager setCurrentViewController:self];
    
    weakify(self);
    [self.uploadManager setProgressBlock:^(NSString *title){
        
    }];
    
    [self.uploadManager setErrorBlock:^(NSError *error, BOOL terminate){
        strongify(self);
        if (terminate && self.ciRepoProject) {
            exit(abExitCodeForUploadFailed);
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
        [self exportSharedURLInSystemFile];
        [self logAppUploadEventAndShareURLOnSlackChannel];
    }];
}


#pragma mark - Build Repo / Open Files Notification
- (void)initCIProcess:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[XCProject class]]) {
        self.ciRepoProject = notification.object;
        if (self.ciRepoProject.ipaFullPath) {
            [self initIPAUploadProcessForURL:self.ciRepoProject.ipaFullPath];
        }
    }
}

- (void)initOpenFilesProcess:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[NSString class]]) {
        NSURL *fileURL = [notification.object validURL];
        if (fileURL) {
            [selectedFilePath setURL:fileURL.filePathURL];
            [self selectedFilePathHandler:selectedFilePath];
            return;
        }
    }
}

- (void)exportSharedURLInSystemFile{
    if (self.ciRepoProject) {
        [self.project exportSharedURLInSystemFile];
    }
}

#pragma mark - Controls Action Handler -
#pragma mark → Project / Workspace Controls Action
//Project Path Handler
- (IBAction)selectedFilePathHandler:(NSPathControl *)sender {
    NSURL *url = [sender.URL filePathURL];
    if (url.isIPA && ![self.project.ipaFullPath isEqual:url]) {
        [self viewStateForProgressFinish:YES];
        [self.project setIpaFullPath: url];
        [selectedFilePath setURL:url];
        [self updateViewState];
		
		//Get last time valid data
		BOOL enable = selectedFilePath.URL.isIPA;
		[textFieldEmail setStringValue: enable ? [UserData userEmail] : abEmptyString];
		[textFieldMessage setStringValue: enable ? [UserData userMessage] : abEmptyString];
    }
}

- (void)initIPAUploadProcessForURL:(NSURL *)ipaURL {
    [self viewStateForProgressFinish:YES];
    [self.project setIpaFullPath:ipaURL];
    [selectedFilePath setURL:ipaURL];
    [textFieldEmail setStringValue:self.project.emails];
    [textFieldMessage setStringValue:self.project.personalMessage];
    [buttonUniqueLink setState:self.project.keepSameLink.boolValue ? NSOnState : NSOffState];
    [self actionButtonTapped:buttonAction];
}

#pragma mark → IPA File Controlles Actions
//IPA File Path Handler

- (IBAction)buttonUniqueLinkTapped:(NSButton *)sender{
    self.project.isKeepSameLinkEnabled = (sender.state == NSOnState);
}

- (IBAction)buttonSameLinkHelpTapped:(NSButton *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:abKeepSameLinkReadMoreURL]];
    [EventTracker logEventWithType:LogEventTypeExternalLinkKeepSameLink];
}


#pragma mark → Mail Controls Action

//email id text field
- (IBAction)textFieldMailValueChanged:(NSTextField *)sender {
    //removed spaces
    [sender setStringValue: [sender.stringValue stringByReplacingOccurrencesOfString:@" " withString:abEmptyString]];
    
    //check all mails vaild or not and setup mailed option based on this
    BOOL isAllMailVaild = sender.stringValue.length > 0 && [MailHandler isAllValidEmail:sender.stringValue];
    if (isAllMailVaild){
        [self.project setEmails:sender.stringValue];
        
        //save user emails, if they doesn't have any
        if ([[UserData userEmail] isEqualToString:abEmptyString]){
            [UserData setUserEmail:sender.stringValue];
        }
    } else if (sender.stringValue.length > 0) {
        [MailHandler showInvalidEmailAddressAlert];
    }
}

//developer message text field
- (IBAction)textFieldDevMessageValueChanged:(NSTextField *)sender {
	if ([[UserData userMessage] isEqualToString:abEmptyString]) {
		[UserData setUserMessage:sender.stringValue];
	}
	[self.project setPersonalMessage:sender.stringValue];
}

#pragma mark → Final Action Button (Build/IPA/CI)
//Build Button Action
- (IBAction)actionButtonTapped:(NSButton *)sender {
    if (textFieldEmail.stringValue.isEmpty || [MailHandler isAllValidEmail:textFieldEmail.stringValue]){
        if ([AppDelegate appDelegate].processing){
            [[AppDelegate appDelegate] addSessionLog:@"A request already in progress."];
            return;
        }
        
        //set processing flag
        [[AppDelegate appDelegate] setProcessing:true];
        [[textFieldEmail window] makeFirstResponder:self.view];
        
        NSDictionary *currentSetting = [self getBasicViewStateWithOthersSettings:nil];
        [EventTracker logEventSettingWithType:LogEventSettingTypeUploadIPA andSettings:currentSetting];
        [self.uploadManager uploadIPAFile:self.project.ipaFullPath];
        
        [self viewStateForProgressFinish:![AppDelegate appDelegate].processing];
    }else{
        [MailHandler showInvalidEmailAddressAlert];
    }
}


#pragma mark - Dropbox Helper -
#pragma mark → Dropbox Notification Handler
- (void)handleLoggedInNotification:(NSNotification *)notification{
    [self updateMenuButtons];
    [self viewStateForProgressFinish:YES];
}

- (void)dropboxLogoutHandler:(id)sender{
    //handle dropbox logout for authorized users
    if ([DBClientsManager authorizedClient]){
        [DBClientsManager unlinkAndResetClients];
        [self viewStateForProgressFinish:YES];
        [self performSegueWithIdentifier:@"DropBoxLogin" sender:self];
    }
}


#pragma mark - Controller Helpers -

-(void)viewStateForProgressFinish:(BOOL)finish{
    [ABLog log:@"Updating view setting for finish - %@", [NSNumber numberWithBool:finish]];
    [[AppDelegate appDelegate] setProcessing:!finish];
    [[AppDelegate appDelegate] setIsReadyToBuild:finish];
    
    //reset project
    if (finish){
        self.project = [[XCProject alloc] init];
        [self.uploadManager setProject:self.project];
        [ABHudViewController hudForView:self.view hide:YES];
        buildOptionBoxHeightConstraint.constant = 0;
    }
    
    //unique link
    [buttonUniqueLink setEnabled:finish];
    [buttonUniqueLink setState: finish ? NSOffState : buttonUniqueLink.state];
    
    //ipa or project path
    [selectedFilePath setEnabled:finish];
    [selectedFilePath setURL: finish ? nil : selectedFilePath.URL.filePathURL];
    
    //action button
    [self updateViewState];
    
    //logout buttons
    [self updateMenuButtons];
}

-(void)showStatus:(NSString *)status andShowProgressBar:(BOOL)showProgressBar withProgress:(double)progress{
    //log status in session log
    [[AppDelegate appDelegate]addSessionLog:[NSString stringWithFormat:@"%@",status]];
    
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

#pragma mark - TabView Delegate -
-(void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem{
    //update view state based on selected tap
    [self updateViewState];
}

-(BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem{
    return ![AppDelegate appDelegate].processing;
}

#pragma mark - ProjectAdvancedViewDelegate - 
- (void)projectAdvancedSaveButtonTapped:(NSButton *)sender{

}

- (void)projectAdvancedCancelButtonTapped:(NSButton *)sender{
    
}

#pragma mark - Navigation -
-(void)logAppUploadEventAndShareURLOnSlackChannel{
    //Log IPA Upload Success Rate with Other Options
    NSDictionary *currentSetting = [self getBasicViewStateWithOthersSettings:@{@"Uploaded to":@"Dropbox"}];
    [EventTracker logEventSettingWithType:LogEventSettingTypeUploadIPASuccess andSettings:currentSetting];
    
    //Show Notification
    if (self.ciRepoProject == nil) {
        [Common showUploadNotificationWithName:self.project.name andURL:self.project.appShortShareableURL];
    }
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@".\n\n\nSHARE URL - %@\n\n\n.", self.project.appShortShareableURL]];
    
    
    if ([UserData userSlackMessage].length > 0) {
        if ([UserData userSlackChannel].length > 0){
            [self showStatus:@"Sending Message on Slack..." andShowProgressBar:YES withProgress:-1];
            [SlackClient sendMessageForProject:self.project completion:^(BOOL success) {}];
        }
        if ([UserData userHangoutChatWebHook].length > 0){
            [self showStatus:@"Sending Message on Hangout..." andShowProgressBar:YES withProgress:-1];
            [HangoutClient sendMessageForProject:self.project completion:^(BOOL success) {}];
        }
        if ([UserData userMicrosoftTeamWebHook].length > 0){
            [self showStatus:@"Sending Message on Microsoft Team..." andShowProgressBar:YES withProgress:-1];
            [MSTeamsClient sendMessageForProject:self.project completion:^(BOOL success) {}];
        }
        
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self handleAppURLAfterSlack];
    });
}


-(void) handleAppURLAfterSlack {
    //Send mail if valid email address othervise show link
    if (textFieldEmail.stringValue.length > 0 && [MailHandler isAllValidEmail:textFieldEmail.stringValue]) {
        [self showStatus:@"Sending Mail..." andShowProgressBar:YES withProgress:-1];
        [MailGun sendMailWithProject:self.project.abpProject complition:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    [ABHudViewController showStatus:@"Mail Sent" forSuccess:YES onView:self.view];
                    if(![self.presentedViewControllers.lastObject isKindOfClass:[ShowLinkViewController class]]){
                        if (self.ciRepoProject == nil){
                            [self performSegueWithIdentifier:@"ShowLink" sender:self];
                        }else{
                            [self viewStateForProgressFinish:YES];
                            exit(abExitCodeForSuccess);
                        }
                    }
                } else {
                    [ABHudViewController showStatus:@"Mail Failed" forSuccess:NO onView:self.view];
                    if (self.ciRepoProject == nil){
                        [self performSegueWithIdentifier:@"ShowLink" sender:self];
                    }else{
                        [self viewStateForProgressFinish:YES];
                        exit(abExitCodeForMailFailed);
                    }
                }
            });
        }];
    }else{
        if (self.ciRepoProject == nil){
            [self performSegueWithIdentifier:@"ShowLink" sender:self];
        }else{
            [self viewStateForProgressFinish:YES];
            exit(abExitCodeForSuccess);
        }
    }
}

-(void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender{
    
    //prepare to show link
    if ([segue.destinationController isKindOfClass:[ShowLinkViewController class]]) {
        //set project to destination
        [((ShowLinkViewController *)segue.destinationController) setProject:self.project];
        [self viewStateForProgressFinish:YES];
    }
    
    //prepare to show advanced project settings
    else if([segue.destinationController isKindOfClass:[ProjectAdvancedViewController class]]){
        ProjectAdvancedViewController *projectAdvancedViewController = ((ProjectAdvancedViewController *)segue.destinationController);
        [projectAdvancedViewController setProject:self.project];
        [projectAdvancedViewController setDelegate:self];
    }
}

@end
