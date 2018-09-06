//
//  HomeViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 29/08/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "HomeViewController.h"

@implementation HomeViewController{
    XCProject *project;
    XCProject *ciRepoProject;
    ScriptType scriptType;
    NSArray *allTeamIds;
    UploadManager *uploadManager;
    NSInteger processExecuteCount;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    project = [[XCProject alloc] init];
    allTeamIds = [KeychainHandler getAllTeamId];
    buildOptionBoxHeightConstraint.constant = 0;
    
    //Notification Handler
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initCIProcess:) name:abBuildRepoNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropboxLogoutHandler:) name:abDropBoxLoggedOutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLoggedInNotification:) name:abDropBoxLoggedInNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initOpenFilesProcess:) name:abUseOpenFilesNotification object:nil];
    
    //setup initial value
    [project setBuildDirectory: [UserData buildLocation]];
    
    //setup dropbox
    [UploadManager setupDBClientsManager];
    [self setupUploadManager];
    
    //update available memory
    [[NSApplication sharedApplication] updateDropboxUsage];
    
    //Start monitoring internet connection
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        [[AppDelegate appDelegate] setIsInternetConnected:!(status == AFNetworkReachabilityStatusNotReachable)];
        if ([AppDelegate appDelegate].processing){
            if (status == AFNetworkReachabilityStatusNotReachable){
                [self showStatus:abNotConnectedToInternet andShowProgressBar:YES withProgress:-1];
            }else{
                //[self showStatus:abConnectedToInternet andShowProgressBar:NO withProgress:-1];
                //restart last failed operation
                if (uploadManager.lastfailedOperation){
                    [uploadManager.lastfailedOperation start];
                    uploadManager.lastfailedOperation = nil;
                }
            }
        }
    }];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    //Track screen
    [EventTracker logScreen:@"Home Screen"];
    
    //Get Xcode and Application Loader path
    [XCHandler getXCodePathWithCompletion:^(NSString *xcodePath, NSString *applicationLoaderPath) {
        [UserData setXCodeLocation:xcodePath];
        [UserData setApplicationLoaderLocation:applicationLoaderPath];
    }];
}

- (void)viewWillAppear{
    [super viewWillAppear];
    [self updateMenuButtons];
    
    //Handle Dropbox Login
    if ([DBClientsManager authorizedClient] == nil) {
        [self performSegueWithIdentifier:@"DropBoxLogin" sender:self];
    }
    [[AppDelegate appDelegate] setIsReadyToBuild:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:abAppBoxReadyToUseNotification object:self];
}

#pragma mark - Upload Manager
-(void)setupUploadManager{
    uploadManager = [[UploadManager alloc] init];
    [uploadManager setProject:project];
    [uploadManager setCiRepoProject:ciRepoProject];
    [uploadManager setCurrentViewController:self];
    
    __unsafe_unretained typeof(self) weakSelf = self;
    
    [uploadManager setProgressBlock:^(NSString *title){
        
    }];
    
    [uploadManager setErrorBlock:^(NSError *error, BOOL terminate){
        if (terminate) {
            if (ciRepoProject) {
                exit(abExitCodeForUploadFailed);
            }
            [weakSelf viewStateForProgressFinish:YES];
        }
    }];
    
    [uploadManager setItcLoginBlock:^(){
        [weakSelf performSegueWithIdentifier:@"ITCLogin" sender:weakSelf];
    }];
    
    [uploadManager setCompletionBlock:^(){
        [weakSelf logAppUploadEventAndShareURLOnSlackChannel];
    }];
}


#pragma mark - Build Repo / Open Files Notification
- (void)initCIProcess:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[XCProject class]]) {
        ciRepoProject = notification.object;
        if (ciRepoProject.ipaFullPath)
        {
            [self initIPAUploadProcessForURL: ciRepoProject.ipaFullPath];
        }
        else
        {
            [self initProjectBuildProcessForURL: ciRepoProject.projectFullPath];
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

#pragma mark - Controls Action Handler -
#pragma mark → Project / Workspace Controls Action
//Project Path Handler
- (IBAction)selectedFilePathHandler:(NSPathControl *)sender {
    NSURL *url = [sender.URL filePathURL];
    if (url.isIPA && ![project.ipaFullPath isEqual:url]) {
        [self viewStateForProgressFinish:YES];
        [project setIpaFullPath: url];
        [selectedFilePath setURL:url];
        [self updateViewState];
    } else if (url.isProject && ![project.projectFullPath isEqualTo:url]) {
        [self viewStateForProgressFinish:YES];
        [self initProjectBuildProcessForURL: url];
    }
}

- (void)initProjectBuildProcessForURL:(NSURL *)projectURL {
    [self viewStateForProgressFinish:YES];
    [project setProjectFullPath: projectURL];
    [selectedFilePath setURL:projectURL];
    [self runGetSchemeScript];
}

- (void)initIPAUploadProcessForURL:(NSURL *)ipaURL {
    [self viewStateForProgressFinish:YES];
    [project setIpaFullPath:ipaURL];
    [selectedFilePath setURL:ipaURL];
    [self actionButtonTapped:buttonAction];
}

//Scheme Value Changed
- (IBAction)comboBuildSchemeValueChanged:(NSComboBox *)sender {
    [self updateViewState];
    [project setSelectedSchemes:sender.stringValue];
}

//Team Value Changed
- (IBAction)comboTeamIdValueChanged:(NSComboBox *)sender {
    NSString *teamId;
    if (sender.stringValue.length != 10 || [sender.stringValue containsString:@" "]){
        NSDictionary *team = [[allTeamIds filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.fullName LIKE %@",sender.stringValue]] firstObject];
        teamId = [team valueForKey:abTeamId];
        [project setTeamId: teamId];
    }else{
        [project setTeamId: sender.stringValue];
    }
    [self updateViewState];
}

//Build Type Changed
- (IBAction)comboBuildTypeValueChanged:(NSComboBox *)sender {
    if (![project.buildType isEqualToString:sender.stringValue]){
        [project setBuildType: sender.stringValue];
        if ([project.buildType isEqualToString:BuildTypeAppStore]){
            [self performSegueWithIdentifier:@"ITCLogin" sender:self];
        }
        [self updateViewState];
    }
}

#pragma mark → IPA File Controlles Actions
//IPA File Path Handler

- (IBAction)buttonUniqueLinkTapped:(NSButton *)sender{
    project.isKeepSameLinkEnabled = (sender.state == NSOnState);
}

- (IBAction)buttonSameLinkHelpTapped:(NSButton *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:abKeepSameLinkReadMoreURL]];
    [EventTracker logEventWithType:LogEventTypeExternalLinkKeepSameLink];
}


#pragma mark → Mail Controls Action
//Send mail option
- (IBAction)sendMailOptionValueChanged:(NSButton *)sender {
    [self enableMailField:(sender.state == NSOnState)];
}

//Shutdown mac option
- (IBAction)sendMailMacOptionValueChanged:(NSButton *)sender {
    //No action required
}

//email id text field
- (IBAction)textFieldMailValueChanged:(NSTextField *)sender {
    //removed spaces
    [sender setStringValue: [sender.stringValue stringByReplacingOccurrencesOfString:@" " withString:abEmptyString]];
    
    //check all mails vaild or not and setup mailed option based on this
    BOOL isAllMailVaild = sender.stringValue.length > 0 && [MailHandler isAllValidEmail:sender.stringValue];
    [buttonShutdownMac setEnabled:isAllMailVaild];
    if (isAllMailVaild){
        [project setEmails:sender.stringValue];
        
        //save user emails, if they doesn't have any
        if ([[UserData userEmail] isEqualToString:abEmptyString]){
            [UserData setUserEmail:sender.stringValue];
        }
    }else if (sender.stringValue.length > 0){
        [MailHandler showInvalidEmailAddressAlert];
    }
}

//developer message text field
- (IBAction)textFieldDevMessageValueChanged:(NSTextField *)sender {
    if (sender.stringValue.length > 0){
        if ([[UserData userMessage] isEqualToString:abEmptyString]) {
            [UserData setUserMessage:sender.stringValue];
        }
        [project setPersonalMessage:sender.stringValue];
    }
}

#pragma mark → Final Action Button (Build/IPA/CI)
//Build Button Action
- (IBAction)actionButtonTapped:(NSButton *)sender {
    if (buttonSendMail.state == NSOffState || (textFieldEmail.stringValue.length > 0 && [MailHandler isAllValidEmail:textFieldEmail.stringValue])){
        //set email
        if (project.emails == nil) {
            [self enableMailField:buttonSendMail.state == NSOnState];
        }
        
        if ([AppDelegate appDelegate].processing){
            [[AppDelegate appDelegate] addSessionLog:@"A request already in progress."];
            return;
        }
        //set processing flag
        [[AppDelegate appDelegate] setProcessing:true];
        [[textFieldEmail window] makeFirstResponder:self.view];
        
        if (project.projectFullPath.isProject){
            NSDictionary *currentSetting = [self getBasicViewStateWithOthersSettings:@{@"Build Type" : comboBuildType.stringValue}];
            [EventTracker logEventSettingWithType:LogEventSettingTypeArchiveAndUpload andSettings:currentSetting];
            [project setIsBuildOnly:NO];
            [self runBuildScript];
        }else if (project.ipaFullPath.isIPA){
            NSDictionary *currentSetting = [self getBasicViewStateWithOthersSettings:nil];
            [EventTracker logEventSettingWithType:LogEventSettingTypeUploadIPA andSettings:currentSetting];
            [uploadManager uploadIPAFile:project.ipaFullPath];
        }
        [self viewStateForProgressFinish:![AppDelegate appDelegate].processing];
    }else{
        [MailHandler showInvalidEmailAddressAlert];
    }
}

//Config CI
- (IBAction)buttonConfigCITapped:(NSButton *)sender {
    
}

#pragma mark - NSTask (Scheme, TeamId and Archive) -
#pragma mark → Task

- (void)runGetSchemeScript{
    [self showStatus:@"Getting project scheme..." andShowProgressBar:YES withProgress:-1];
    scriptType = ScriptTypeGetScheme;
    NSString *schemeScriptPath = [[NSBundle mainBundle] pathForResource:@"GetSchemeScript" ofType:@"sh"];
    [self runTaskWithLaunchPath:schemeScriptPath andArgument:@[project.rootDirectory]];
}

- (void)runTeamIDScript{
    [self showStatus:@"Getting project team id..." andShowProgressBar:YES withProgress:-1];
    scriptType = ScriptTypeTeamId;
    NSString *teamIdScriptPath = [[NSBundle mainBundle] pathForResource:@"TeamIDScript" ofType:@"sh"];
    [self runTaskWithLaunchPath:teamIdScriptPath andArgument:@[project.rootDirectory]];
}

-(void)buildAndIPAArguments:(void (^) (NSArray *arguments))completion{
    NSMutableArray *buildArgument = [[NSMutableArray alloc] init];
    
    //${1} Project Location
    [buildArgument addObject:project.rootDirectory];
    
    //${2} Project type workspace/scheme
    [buildArgument addObject:selectedFilePath.URL.lastPathComponent];
    
    //${3} Build Scheme
    [buildArgument addObject:comboBuildScheme.stringValue];
    
    //${4} Archive Location
    [buildArgument addObject:[project.buildArchivePath.resourceSpecifier stringByRemovingPercentEncoding]];
    
    //${5} ipa Location
    [buildArgument addObject:[project.buildUUIDDirectory.resourceSpecifier stringByRemovingPercentEncoding]];
    
    //${6} export options plist Location
    [buildArgument addObject:[project.exportOptionsPlistPath.resourceSpecifier stringByRemovingPercentEncoding]];
    
    //Get Xcode Version
    [XCHandler getXcodeVersionWithCompletion:^(BOOL success, XcodeVersion version, NSString *versionString) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *version;
            if (success) {
                version = [NSString stringWithFormat:@"%@",[NSNumber numberWithInteger:[versionString integerValue]]];
            } else {
                version = @"8";
            }
            //${7} xcode version
            [buildArgument addObject:version];
            
            //${8} xcpretty
            NSString *xcPrettyPath = [[NSBundle mainBundle] pathForResource:@"xcpretty/bin/xcpretty" ofType:nil];
            if (xcPrettyPath){
                [buildArgument addObject:xcPrettyPath];
            }
            if (buildArgument.count == 8) {
                completion(buildArgument);
            } else {
                NSString *errorLog = [NSString stringWithFormat:@"Failed to create build command.\n Build Arguments %@", buildArgument];
                if (ciRepoProject) {
                    [[AppDelegate appDelegate] addSessionLog:errorLog];
                    exit(abExitCodeForInvalidArgumentsXcodeBuild);
                } else {
                    [ABLog log:errorLog];
                    [Common showAlertWithTitle:@"Error" andMessage:@"Failed to create build command."];
                    [self viewStateForProgressFinish:YES];
                    completion(nil);
                }
            }
        });
        
    }];
}

- (void)runBuildScript{
    [self showStatus:@"Cleaning..." andShowProgressBar:YES withProgress:-1];
    scriptType = ScriptTypeBuild;
    
    //Create Export Option Plist
    if (![project createExportOptionPlist]){
        [Common showAlertWithTitle:@"Error" andMessage:@"Unable to create file in this directory."];
        return;
    }
    
    //Run Task
    NSString *buildScriptPath = [[NSBundle mainBundle] pathForResource:@"ProjectBuildScript" ofType:@"sh"];
    [self buildAndIPAArguments:^(NSArray *arguments) {
        if (arguments){
            [self runTaskWithLaunchPath:buildScriptPath andArgument:arguments];
        }
    }];
}

- (void)runCreateIPAScript{
    scriptType = ScriptTypeCreateIPA;
    [self showStatus:@"Creating IPA..." andShowProgressBar:YES withProgress:-1];
    NSString *createIPASriptPath = [[NSBundle mainBundle] pathForResource:@"CreateIPAScript" ofType:@"sh"];
    [self buildAndIPAArguments:^(NSArray *arguments) {
        if (arguments){
            [self runTaskWithLaunchPath:createIPASriptPath andArgument:arguments];
        }
    }];
}

- (void)runXcodePathScript{
    scriptType = ScriptTypeXcodePath;
    NSString *xcodePathSriptPath = [[NSBundle mainBundle] pathForResource:@"XCodePath" ofType:@"sh"];
    [self runTaskWithLaunchPath:xcodePathSriptPath andArgument:nil];
}

- (void)runALAppStoreScriptForValidation:(BOOL)isValidation{
    scriptType = isValidation ? ScriptTypeAppStoreValidation : ScriptTypeAppStoreUpload;
    [self showStatus:isValidation ? @"Validating IPA with AppStore..." : @"Uploading IPA on AppStore..." andShowProgressBar:YES withProgress:-1];
    NSString *alSriptPath = [[NSBundle mainBundle] pathForResource: @"ALAppStore" ofType:@"sh"];
    NSMutableArray *buildArgument = [[NSMutableArray alloc] init];

    
    //${1} Purpose
    NSString *purpose = isValidation ? abALValidateApp : abALUploadApp;
    [buildArgument addObject:purpose];
    
    //${2} AL Path
    [buildArgument addObject:project.alPath];
    
    //${3} Project Location
    [buildArgument addObject: [project.ipaFullPath.resourceSpecifier stringByRemovingPercentEncoding]];
    
    //${4} Project type workspace/scheme
    [buildArgument addObject:project.itcUserName];
    
    //${5} Build Scheme
    [buildArgument addObject:project.itcPasswod];
    
    [self runTaskWithLaunchPath:alSriptPath andArgument:buildArgument];
}


#pragma mark → Run and Capture task data

- (void)runTaskWithLaunchPath:(NSString *)launchPath andArgument:(NSArray *)arguments{
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = launchPath;
    task.arguments = arguments;
    [self captureStandardOutputWithTask:task];
    [task launch];
    if (scriptType == ScriptTypeTeamId){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [task terminate];
            [ABLog log:@"terminating task!!"];
        });
    }
}

- (void)captureStandardOutputWithTask:(NSTask *)task{
    NSPipe *outputPipe = [[NSPipe alloc] init];
    [task setStandardOutput:outputPipe];
    [task setStandardError:outputPipe];
    [outputPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification object:outputPipe.fileHandleForReading queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        NSData *outputData =  outputPipe.fileHandleForReading.availableData;
        NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        [[AppDelegate appDelegate] addSessionLog:outputString];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            //Handle Project Scheme Response
            if (scriptType == ScriptTypeGetScheme){
                NSError *error;
                NSDictionary *buildList = [NSJSONSerialization JSONObjectWithData:outputData options:NSJSONReadingAllowFragments error:&error];
                if (buildList != nil) {
                    [project setBuildListInfo:buildList];
                    [comboBuildScheme removeAllItems];
                    [comboBuildScheme addItemsWithObjectValues:project.schemes];
                }
                if (buildList != nil && comboBuildScheme.numberOfItems > 0){
                    [comboBuildScheme selectItemAtIndex:0];
                    //If CI Project then set project details direct from appbox.plist
                    if (ciRepoProject) {
                        [RepoBuilder setProjectSettingFromProject:ciRepoProject toProject:project];
                        [comboTeamId removeAllItems];
                        if (project.teamId == nil) {
                            [self showStatus:@"Private key not available in keychain." andShowProgressBar:NO withProgress:-1];
                            exit(abExitCodeForPrivateKeyNotFound);
                        }
                        [comboTeamId addItemWithObjectValue:project.teamId];
                        [comboTeamId selectItemWithObjectValue:project.teamId];
                        [comboBuildType selectItemWithObjectValue:project.buildType];
                        if (project.schemes == nil || project.schemes.count == 0) {
                            NSString *message = [NSString stringWithFormat:@"Failed to load scheme information. Please try again with shared Xcode project schemes. Click here to read how to share project scheme - %@", abShareXcodeProjectSchemeURL];
                            [self showStatus:message andShowProgressBar:NO withProgress:-1];
                            exit(abExitCodeForSchemeNotFound);
                        }
                        [comboBuildScheme selectItemWithObjectValue:project.selectedSchemes];
                        [textFieldEmail setStringValue:project.emails];
                        [textFieldMessage setStringValue:project.personalMessage];
                        if (project.emails.length > 0){
                            [buttonSendMail setState:NSOnState];
                        }
                        [self actionButtonTapped:buttonAction];
                    } else {
                        [self comboBuildSchemeValueChanged:comboBuildScheme];
                        [self runTeamIDScript];
                    }
                }else{
                    if (processExecuteCount == 3){
                        processExecuteCount = 0;
                        [self viewStateForProgressFinish:YES];
                        //exit if appbox failed to load scheme information for ci project
                        if (ciRepoProject) {
                            exit(abExitCodeForFailedToLoadSchemeInfo);
                        }
                        NSAlert *alert = [[NSAlert alloc] init];
                        [alert setMessageText: @"Failed to load scheme information."];
                        [alert setInformativeText:@"Please try again with shared Xcode project schemes."];
                        [alert setAlertStyle:NSInformationalAlertStyle];
                        [alert addButtonWithTitle:@"How to share Xcode Project Schemes?"];
                        [alert addButtonWithTitle:@"OK"];
                        if ([alert runModal] == NSAlertFirstButtonReturn){
                            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:abShareXcodeProjectSchemeURL]];
                        }
                    } else {
                        processExecuteCount++;
                        [self runGetSchemeScript];
                        [[AppDelegate appDelegate] addSessionLog:@"Failed to load scheme information."];
                    }
                }
            }
            
            //Handle Team Id Response
            else if (scriptType == ScriptTypeTeamId){
                if ([outputString.lowercaseString containsString:@"development_team"]){
                    NSArray *outputComponent = [outputString componentsSeparatedByString:@"\n"];
                    NSString *devTeam = [[outputComponent filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF CONTAINS 'DEVELOPMENT_TEAM'"]] firstObject];
                    if (devTeam != nil) {
                        project.teamId = [[devTeam componentsSeparatedByString:@" = "] lastObject];
                        if (project.teamId != nil){
                            NSDictionary *team = [[allTeamIds filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.teamId LIKE %@",project.teamId]] firstObject];
                            if (team != nil){
                                [comboTeamId selectItemAtIndex:[allTeamIds indexOfObject:team]];
                            }else{
                                [comboTeamId addItemWithObjectValue:project.teamId];
                                [comboTeamId selectItemWithObjectValue:project.teamId];
                            }
                            [self updateViewState];
                            buildOptionBoxHeightConstraint.constant = 119;
                            [self showStatus:@"Now please select ipa type (save for). You can view log from File -> View Log." andShowProgressBar:NO withProgress:-1];
                        }
                    }
                } else if ([outputString.lowercaseString containsString:@"endofteamidscript"] || outputString.lowercaseString.length == 0) {
                    [self showStatus:@"Can't able to find Team ID! Please select/enter manually!" andShowProgressBar:NO withProgress:-1];
                } else {
                    [outputPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
                }
            }
            
            //Handle Build Response
            else if (scriptType == ScriptTypeBuild){
                if ([outputString.lowercaseString containsString:@"archive succeeded"]){
                    [self runCreateIPAScript];
                } else if ([outputString.lowercaseString containsString:@"clean succeeded"]){
                    [self showStatus:@"Archiving..." andShowProgressBar:YES withProgress:-1];
                    [outputPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
                } else if ([outputString.lowercaseString containsString:@"archive failed"]){
                    if ([AppDelegate appDelegate].isInternetConnected || [outputString containsString:@"^"]){
                        [self showStatus:@"Archive Failed" andShowProgressBar:NO withProgress:-1];
                        if (ciRepoProject) {
                            exit(abExitCodeForArchiveFailed); //exit if appbox failed to archive the project
                        } else {
                            [Common showAlertWithTitle:@"Archive Failed" andMessage:outputString];
                        }
                        [self viewStateForProgressFinish:YES];
                    }else{
                        [self showStatus:abNotConnectedToInternet andShowProgressBar:YES withProgress:-1];
                        uploadManager.lastfailedOperation = [NSBlockOperation blockOperationWithBlock:^{
                            [self runBuildScript];
                        }];
                    }
                } else {
                    [outputPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
                }
            }
            
            //Handle Create IPA Script Response
            else if (scriptType == ScriptTypeCreateIPA) {
                if ([outputString.lowercaseString containsString:@"export succeeded"]){
                    //Check and Upload IPA File
                    if (project.isBuildOnly){
                        [self showStatus:[NSString stringWithFormat:@"Export Succeeded - %@",project.buildUUIDDirectory] andShowProgressBar:NO withProgress:-1];
                    }else{
                        [self showStatus:@"Export Succeeded" andShowProgressBar:YES withProgress:-1];
                        [self checkIPACreated];
                    }
                } else if ([outputString.lowercaseString containsString:@"export failed"]){
                    if ([AppDelegate appDelegate].isInternetConnected){
                        [self showStatus:@"Export Failed" andShowProgressBar:NO withProgress:-1];
                        if (ciRepoProject) {
                            exit(abExitCodeForExportFailed); //exit if appbox failed to export IPA file
                        } else {
                            [Common showAlertWithTitle:@"Export Failed" andMessage:outputString];
                        }
                        [self viewStateForProgressFinish:YES];
                    } else {
                        [self showStatus:abNotConnectedToInternet andShowProgressBar:YES withProgress:-1];
                        uploadManager.lastfailedOperation = [NSBlockOperation blockOperationWithBlock:^{
                            [self runCreateIPAScript];
                        }];
                    }
                } else {
                    [outputPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
                }
            }
            
            //Handle Xcode Path Response
            else if (scriptType == ScriptTypeXcodePath) {
                
            }
            
            //Handle AppStore Validation and Upload Response
            else if (scriptType == ScriptTypeAppStoreValidation || scriptType == ScriptTypeAppStoreUpload){
                [self appStoreScriptOutputHandlerWithOutput:outputString];
            }
        });
    }];
}

-(void)appStoreScriptOutputHandlerWithOutput:(NSString *)output{
    //parse application loader response
    ALOutput *alOutput = [ALOutputParser messageFromXMLString:output];
    [alOutput.messages enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj && obj.length > 0){
            [self showStatus:obj andShowProgressBar:NO withProgress:-1];
        }
    }];
    
    //check if response is valid or error
    if (alOutput.isValid){
        if (scriptType == ScriptTypeAppStoreValidation){
            //run appstore upload script
            [self runALAppStoreScriptForValidation:NO];
        }else if (scriptType == ScriptTypeAppStoreUpload){
            //show upload succeess message
            NSDictionary *currentSetting = [self getBasicViewStateWithOthersSettings:@{@"Uploaded to":@"AppStore"}];
            [EventTracker logEventSettingWithType:LogEventSettingTypeUploadIPASuccess andSettings:currentSetting];
            [self showStatus:@"App uploaded to AppStore." andShowProgressBar:NO withProgress:-1];
            if (ciRepoProject) {
                exit(abExitCodeForSuccess);
            }
            [Common showAlertWithTitle:@"App uploaded to AppStore." andMessage:nil];
            [self viewStateForProgressFinish:YES];
        }
    }else{
        //if internet is connected, show direct error
        if ([AppDelegate appDelegate].isInternetConnected){
            [[AppDelegate appDelegate] addSessionLog:@"Failed to upload on AppStore."];
            if (ciRepoProject) {
                exit(abExitCodeForAppStoreUploadFailed);
            }
            [Common showAlertWithTitle:@"Error" andMessage:[alOutput.messages componentsJoinedByString:@"\n\n"]];
            [self viewStateForProgressFinish:YES];
        }else{
            //if internet connection is lost, show watting message and start process again when connected
            [self showStatus:abNotConnectedToInternet andShowProgressBar:YES withProgress:-1];
            uploadManager.lastfailedOperation = [NSBlockOperation blockOperationWithBlock:^{
                if (scriptType == ScriptTypeAppStoreValidation){
                    [self runALAppStoreScriptForValidation:YES];
                }else if (scriptType == ScriptTypeAppStoreUpload){
                    [self runALAppStoreScriptForValidation:NO];
                }
            }];
        }
    }
}

#pragma mark - Get IPA Info and Upload -

-(void)checkIPACreated{
    [self showStatus:@"Checking IPA File..." andShowProgressBar:YES withProgress:-1];
    NSString *ipaPath = [project.ipaFullPath.resourceSpecifier stringByRemovingPercentEncoding];
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Finding IPA file at path - %@", ipaPath]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:ipaPath]){
        if ([comboBuildType.stringValue isEqualToString: BuildTypeAppStore]){
            //get required info and upload to appstore
            if (project.alPath) {
                [self runALAppStoreScriptForValidation:YES];
            } else {
                [self itcLoginResult:YES];
            }
        }else{
            //get ipa details and upload to dropbox
            [uploadManager uploadIPAFile:project.ipaFullPath];
        }
    }else{
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Not able to find IPA file at path - %@", ipaPath]];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self checkIPACreated];
        });
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
        project = [[XCProject alloc] init];
        [project setBuildDirectory:[UserData buildLocation]];
        [uploadManager setProject:project];
        [ABHudViewController hudForView:self.view hide:YES];
        buildOptionBoxHeightConstraint.constant = 0;
    }
    
    //unique link
    [buttonUniqueLink setEnabled:finish];
    [buttonUniqueLink setState: finish ? NSOffState : buttonUniqueLink.state];
    
    //ipa or project path
    [selectedFilePath setEnabled:finish];
    [selectedFilePath setURL: finish ? nil : selectedFilePath.URL.filePathURL];
    
    //team id combo
    [comboTeamId setEnabled:finish];
    if (finish){
        //setup team id
        [comboTeamId removeAllItems];
        [comboTeamId setStringValue:abEmptyString];
        [allTeamIds enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [comboTeamId addItemWithObjectValue:[obj valueForKey:abFullName]];
        }];
    }
    
    //build type combo
    [comboBuildType setEnabled:finish];
    if (finish && comboBuildType.indexOfSelectedItem >= 0) [comboBuildType deselectItemAtIndex:comboBuildType.indexOfSelectedItem];
    
    //build scheme
    [comboBuildScheme setEnabled:finish];
    if (finish){
        if (comboBuildScheme.indexOfSelectedItem >= 0){
            [comboBuildScheme setStringValue:abEmptyString];
            [comboBuildScheme deselectItemAtIndex:comboBuildType.indexOfSelectedItem];
        }
        [comboBuildScheme removeAllItems];
    }
    
    
    //send mail
    [buttonSendMail setEnabled:finish];
    [buttonShutdownMac setEnabled:(finish && buttonSendMail.state == NSOnState)];
    [textFieldEmail setEnabled:(finish && buttonSendMail.state == NSOnState)];
    [textFieldMessage setEnabled:(finish && buttonSendMail.state == NSOnState)];
    
    //action button
    [self updateViewState];
    
    //logout buttons
    [self updateMenuButtons];
}

-(void)resetBuildOptions{
    [comboTeamId removeAllItems];
    [comboBuildScheme removeAllItems];
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
    //update action button
    BOOL enable = ((comboBuildScheme.stringValue != nil && comboBuildType.stringValue.length > 0 && //build scheme
                    comboBuildType.stringValue != nil && comboBuildType.stringValue.length > 0 && //build type
                    comboTeamId.stringValue != nil && comboTeamId.stringValue.length > 0 && //team id
                    project.projectFullPath != nil && selectedFilePath.URL.isProject &&
                    (![comboBuildType.stringValue isEqualToString: BuildTypeAppStore] || project.itcPasswod.length > 0)) ||
                   
                   //if ipa selected
                   (project.ipaFullPath != nil && selectedFilePath.URL.isIPA));
    
    [buttonAction setEnabled:enable];
    [buttonAction setTitle:selectedFilePath.URL.isIPA ? @"Upload IPA" : @"Archive and Upload IPA" ];
    
    //update CI button
    //[buttonConfigCI setHidden:(tabView.tabViewItems.lastObject.tabState == NSSelectedTab)];
    //[buttonConfigCI setEnabled:(buttonAction.enabled && !buttonConfigCI.hidden)];
    
    //update keepsame link
    [buttonUniqueLink setEnabled:((project.buildType == nil || ![project.buildType isEqualToString:BuildTypeAppStore] ||
                                  selectedFilePath.URL.isIPA) && ![[AppDelegate appDelegate] processing])];
    
    //update advanced button
    [buttonAdcanced setEnabled:buttonAction.enabled];
    
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
    [viewState setValue:[NSNumber numberWithInteger: buttonSendMail.state] forKey:@"Sent Mail"];
    [viewState setValue:[NSNumber numberWithInteger: buttonShutdownMac.state] forKey:@"Shudown Mac"];
    return viewState;
}

#pragma mark - E-Mail -
-(void)enableMailField:(BOOL)enable{
    //Gmail Logout Button
    [self updateMenuButtons];
    
    //Enable text fields
    [textFieldEmail setEnabled:enable];
    [textFieldMessage setEnabled:enable];
    
    //Get last time valid data
    [textFieldEmail setStringValue: enable ? [UserData userEmail] : abEmptyString];
    [textFieldMessage setStringValue: enable ? [UserData userMessage] : abEmptyString];
    
    //Just for confirm changes
    [self textFieldMailValueChanged:textFieldEmail];
    [self textFieldDevMessageValueChanged:textFieldMessage];
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

#pragma mark - AppleDeveloperLogin Delegate -
- (void)itcLoginResult:(BOOL)success{
    if (success) {
        //check xcode and application loader path
        [XCHandler getXCodePathWithCompletion:^(NSString *xcodePath, NSString *applicationLoaderPath) {
            if (xcodePath != nil){
                [project setXcodePath: xcodePath];
                if (applicationLoaderPath != nil){
                    [project setAlPath: applicationLoaderPath];
                    
                    //check for ipa, if ipa start upload
                    if (selectedFilePath.URL.isIPA){
                        [self runALAppStoreScriptForValidation:YES];
                    }else{
                        if (ciRepoProject){
                            [self runALAppStoreScriptForValidation:YES];
                        } else {
                            [self updateViewState];
                        }
                    }
                }else{
                    if (ciRepoProject) {
                        [[AppDelegate appDelegate] addSessionLog:@"Can't able to find application loader in your machine."];
                        exit(abExitCodeForApplicationLoaderNotFount);
                    } else {
                        [Common showAlertWithTitle:@"Error" andMessage:@"Can't able to find application loader in your machine."];
                    }
                }
            }else{
                if (ciRepoProject) {
                    [[AppDelegate appDelegate] addSessionLog:@"Can't able to find xcode in your machine."];
                    exit(abExitCodeForXcodeNotFount);
                } else {
                    [Common showAlertWithTitle:@"Error" andMessage:@"Can't able to find xcode in your machine."];
                }
            }
        }];
    }
}

-(void)itcLoginCanceled{
    if (selectedFilePath.URL.isIPA){
        [uploadManager uploadIPAFileWithoutUnzip:project.ipaFullPath];
    } else {
        [project setBuildType:abEmptyString];
        [comboBuildType deselectItemAtIndex:comboBuildType.indexOfSelectedItem];
        [self updateViewState];
    }
}

#pragma mark - Navigation -
-(void)logAppUploadEventAndShareURLOnSlackChannel{
    //Log IPA Upload Success Rate with Other Options
    NSDictionary *currentSetting = [self getBasicViewStateWithOthersSettings:@{@"Uploaded to":@"Dropbox"}];
    [EventTracker logEventSettingWithType:LogEventSettingTypeUploadIPASuccess andSettings:currentSetting];
    
    NSString *notificationMessage = [NSString stringWithFormat:@"%@ IPA file uploaded.\nShare URL - %@", project.name, project.appShortShareableURL];
    [Common showLocalNotificationWithTitle:@"AppBox" andMessage:notificationMessage];
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@".\n\n\nBUILD URL - %@\n\n\n.", project.appShortShareableURL]];
    
    if ([UserData userSlackMessage].length > 0) {
        if ([UserData userSlackChannel].length > 0){
            [self showStatus:@"Sending Message on Slack..." andShowProgressBar:YES withProgress:-1];
            [SlackClient sendMessageForProject:project completion:^(BOOL success) {
            }];
        }
        if ([UserData userHangoutChatWebHook].length > 0){
            [self showStatus:@"Sending Message on Hangout..." andShowProgressBar:YES withProgress:-1];
            [HangoutClient sendMessageForProject:project completion:^(BOOL success) {
            }];
        }
        if ([UserData userMicrosoftTeamWebHook].length > 0){
            [self showStatus:@"Sending Message on Microsoft Team..." andShowProgressBar:YES withProgress:-1];
            [MSTeamsClient sendMessageForProject:project completion:^(BOOL success) {
            }];
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
        [MailGun sendMailWithProject:project.abpProject complition:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    [ABHudViewController showStatus:@"Mail Sent" forSuccess:YES onView:self.view];
                    if (buttonShutdownMac.state == NSOnState){
                        //if mac shutdown is checked then shutdown mac after 60 sec
                        [self viewStateForProgressFinish:YES];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [MacHandler shutdownSystem];
                        });
                    }else if(![self.presentedViewControllers.lastObject isKindOfClass:[ShowLinkViewController class]]){
                        //if mac shutdown isn't checked then show link
                        if (ciRepoProject == nil){
                            [self performSegueWithIdentifier:@"ShowLink" sender:self];
                        }else{
                            [self viewStateForProgressFinish:YES];
                            exit(abExitCodeForSuccess);
                        }
                    }
                } else {
                    [ABHudViewController showStatus:@"Mail Failed" forSuccess:NO onView:self.view];
                    [self performSegueWithIdentifier:@"ShowLink" sender:self];
                }
            });
        }];
    }else{
        [self performSegueWithIdentifier:@"ShowLink" sender:self];
    }
}

-(void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender{
    
    //prepare to show link
    if ([segue.destinationController isKindOfClass:[ShowLinkViewController class]]) {
        //set project to destination
        [((ShowLinkViewController *)segue.destinationController) setProject:project];
        [self viewStateForProgressFinish:YES];
    }
    
    //prepare to show advanced project settings
    else if([segue.destinationController isKindOfClass:[ProjectAdvancedViewController class]]){
        ProjectAdvancedViewController *projectAdvancedViewController = ((ProjectAdvancedViewController *)segue.destinationController);
        [projectAdvancedViewController setProject:project];
        [projectAdvancedViewController setDelegate:self];
    }
    
    //prepare to show CI controller
    else if([segue.destinationController isKindOfClass:[CIViewController class]]){
        CIViewController *ciViewController = ((CIViewController *)segue.destinationController);
        [ciViewController setProject:project];
    }
    
    //prepare to show AppleDeveloperLogin
    else if ([segue.destinationController isKindOfClass:[ITCLoginViewController class]]){
        ITCLoginViewController *itcLoginViewController = ((ITCLoginViewController *)segue.destinationController);
        [itcLoginViewController setProject:project];
        [itcLoginViewController setDelegate:self];
    }
}

@end
