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
    ScriptType scriptType;
    FileType fileType;
    NSArray *allTeamIds;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    project = [[XCProject alloc] init];
    allTeamIds = [Common getAllTeamId];
    
    DBSession *session = [[DBSession alloc] initWithAppKey:DbAppkey appSecret:DbScreatkey root:DbRoot];
    [session setDelegate:self];
    [DBSession setSharedSession:session];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authHelperStateChangedNotification:) name:DBAuthHelperOSXStateChangedNotification object:[DBAuthHelperOSX sharedHelper]];
    
    NSAppleEventManager *em = [NSAppleEventManager sharedAppleEventManager];
    [em setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
    [pathBuild setURL:[NSURL URLWithString:[@"~/Desktop" stringByExpandingTildeInPath]]];
    [project setBuildDirectory: pathBuild.URL];
}

- (void)viewWillAppear{
    [super viewWillAppear];
    if (![[DBSession sharedSession] isLinked]) {
        [self performSegueWithIdentifier:@"DropBoxLogin" sender:self];
    }else{
        [self progressCompletedViewState];
    }
}

#pragma mark - Controllers Actions

//Build Button Action
- (IBAction)buttonBuildTapped:(NSButton *)sender {
    [self runBuildScript];
}

//Build and Upload Button Action
- (IBAction)buttonBuildAndUploadTapped:(NSButton *)sender {
    [self runBuildScript];
}

//Scheme Value Changed
- (IBAction)comboBuildSchemeValueChanged:(NSComboBox *)sender {
    [self updateBuildButtonState];
}

//Team Value Changed
- (IBAction)comboTeamIdValueChanged:(NSComboBox *)sender {
    NSString *teamId;
    if (sender.stringValue.length != 10 || [sender.stringValue containsString:@" "]){
         NSDictionary *team = [[allTeamIds filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.fullName LIKE %@",sender.stringValue]] firstObject];
        teamId = [team valueForKey:@"teamId"];
        [project setTeamId: teamId];
    }else{
        [project setTeamId: sender.stringValue];
    }
    [self updateBuildButtonState];
}
- (IBAction)sendMailMacOptionValueChanged:(NSButton *)sender {
    
}

- (IBAction)sendMailOptionValueChanged:(NSButton *)sender {
    if (sender.state == NSOnState){
        [sender setState:NSOffState];
        [self performSegueWithIdentifier:@"MailView" sender:self];
    }else{
        [self enableMailField:NO];
    }
}

- (IBAction)textFieldMailValueChanged:(NSTextField *)sender {
    [buttonShutdownMac setEnabled:[Common isValidEmail:sender.stringValue]];
}

- (IBAction)textFieldDevMessageValueChanged:(NSTextField *)sender {
}

//Build Type Changed
- (IBAction)comboBuildTypeValueChanged:(NSComboBox *)sender {
    if (![project.buildType isEqualToString:sender.stringValue]){
        [project setBuildType: sender.stringValue];
        [self updateBuildButtonState];
    }
}

//Project Path Handler
- (IBAction)projectPathHandler:(NSPathControl *)sender {
    if (![project.fullPath isEqualTo:sender.URL]){
        [project setFullPath: sender.URL];
        [self runGetSchemeScript];
    }
}

//IPA File Path Handler
- (IBAction)ipaFilePathHandle:(NSPathControl *)sender {
    project.ipaFullPath = sender.URL;
    [self uploadBuildWithIPAFileURL:project.ipaFullPath];
}

//Build PathHandler
- (IBAction)buildPathHandler:(NSPathControl *)sender {
    if (![project.buildDirectory isEqualTo:sender.URL]){
        [project setBuildDirectory: sender.URL];
    }
}

#pragma mark - Task

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

- (void)runBuildScript{
    [self showStatus:@"Cleaning..." andShowProgressBar:YES withProgress:-1];
    scriptType = ScriptTypeBuild;
    
    //Build Script Name
    NSString *buildScriptName = ([project.fullPath.pathExtension  isEqual: @"xcworkspace"]) ? @"WorkspaceBuildScript" : @"ProjectBuildScript";
    
    //Create Export Option Plist
    [project createExportOpetionPlist];
    
    //Build Script
    NSString *buildScriptPath = [[NSBundle mainBundle] pathForResource:buildScriptName ofType:@"sh"];
    NSMutableArray *buildArgument = [[NSMutableArray alloc] init];
    
    //${1} Project Location
    [buildArgument addObject:project.rootDirectory];
    
    //${2} Project type workspace/scheme
    [buildArgument addObject:pathProject.URL.lastPathComponent];
    
    //${3} Build Scheme
    [buildArgument addObject:comboBuildScheme.stringValue];
    
    //${4} Archive Location
    [buildArgument addObject:project.buildArchivePath.resourceSpecifier];
    
    //${5} Archive Location
    [buildArgument addObject:project.buildArchivePath.resourceSpecifier];

    //${6} ipa Location
    [buildArgument addObject:project.buildUUIDDirectory.resourceSpecifier];

    //${7} ipa Location
    [buildArgument addObject:project.exportOptionsPlistPath.resourceSpecifier];

    //Run Task
    [self runTaskWithLaunchPath:buildScriptPath andArgument:buildArgument];
}

#pragma mark - Capture task data

- (void)runTaskWithLaunchPath:(NSString *)launchPath andArgument:(NSArray *)arguments{
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = launchPath;
    task.arguments = arguments;
    [self captureStandardOutputWithTask:task];
    [task launch];
    if (scriptType == ScriptTypeTeamId){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [task terminate];
            NSLog(@"Task teeminating!!");
        });
    }
}

- (void)captureStandardOutputWithTask:(NSTask *)task{
    NSPipe *pipe = [[NSPipe alloc] init];
    [task setStandardOutput:pipe];
    [pipe.fileHandleForReading waitForDataInBackgroundAndNotify];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification object:pipe.fileHandleForReading queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        NSData *outputData =  pipe.fileHandleForReading.availableData;
        NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        NSLog(@"%@", outputString);
        [[AppDelegate appDelegate] addSessionLog:outputString];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            //Handle Project Scheme Response
            if (scriptType == ScriptTypeGetScheme){
                NSError *error;
                NSDictionary *buildList = [NSJSONSerialization JSONObjectWithData:outputData options:NSJSONReadingAllowFragments error:&error];
                if (buildList != nil){
                    [project setBuildListInfo:buildList];
                    [progressIndicator setDoubleValue:50];
                    [comboBuildScheme removeAllItems];
                    [comboBuildScheme addItemsWithObjectValues:project.schemes];
                    [comboBuildScheme selectItemAtIndex:0];
                    
                    //Run Team Id Script
                    [self runTeamIDScript];
                }else{
                    [self showStatus:@"Failed to load scheme information." andShowProgressBar:NO withProgress:-1];
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
                            [comboTeamId removeAllItems];
                            [comboTeamId addItemWithObjectValue:project.teamId];
                            [comboTeamId selectItemAtIndex:0];
                            [self showStatus:@"All Done!! Lets build the Rocket!!" andShowProgressBar:NO withProgress:-1];
                        }
                    }
                } else if ([outputString.lowercaseString containsString:@"endofteamidscript"] || outputString.lowercaseString.length == 0) {
                    [comboTeamId removeAllItems];
                    [allTeamIds enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        [comboTeamId addItemWithObjectValue:[obj valueForKey:@"fullName"]];
                    }];
                    [self showStatus:@"Can't able to find Team ID! Please enter manually!" andShowProgressBar:NO withProgress:-1];
                } else {
                    [pipe.fileHandleForReading waitForDataInBackgroundAndNotify];
                }
            }
            
            //Handle Build Response
            else if (scriptType == ScriptTypeBuild){
                if ([outputString.lowercaseString containsString:@"archive succeeded"]){
                    [self showStatus:@"Creating IPA..." andShowProgressBar:YES withProgress:-1];
                    [pipe.fileHandleForReading waitForDataInBackgroundAndNotify];
                } else if ([outputString.lowercaseString containsString:@"clean succeeded"]){
                    [self showStatus:@"Archiving..." andShowProgressBar:YES withProgress:-1];
                    [pipe.fileHandleForReading waitForDataInBackgroundAndNotify];
                } else if ([outputString.lowercaseString containsString:@"export succeeded"]){
                    [self showStatus:@"Export Succeeded" andShowProgressBar:YES withProgress:-1];
                    [self checkIPACreated];
                } else if ([outputString.lowercaseString containsString:@"export failed"]){
                    [self showStatus:@"Export Failed" andShowProgressBar:NO withProgress:-1];
                } else if ([outputString.lowercaseString containsString:@"archive failed"]){
                    [self showStatus:@"Archive Failed" andShowProgressBar:NO withProgress:-1];
                } else {
                    [pipe.fileHandleForReading waitForDataInBackgroundAndNotify];
                }
            }
        });
    }];
}

-(void)checkIPACreated{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([[NSFileManager defaultManager] fileExistsAtPath:project.ipaFullPath.resourceSpecifier]){
            [self uploadBuildWithIPAFileURL:project.ipaFullPath];
        }else{
            [self checkIPACreated];
        }
    });
}

#pragma mark - Upload Build

- (void)uploadBuildWithIPAFileURL:(NSURL *)ipaFileURL{
    NSString *fromPath = [ipaFileURL.resourceSpecifier stringByRemovingPercentEncoding];
    if ([[NSFileManager defaultManager] fileExistsAtPath:fromPath]) {
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"\n\n======\nUploading IPA - %@\n======\n\n",fromPath]];
        //Unzip ipa
        __block NSString *payloadEntry;
        __block NSString *infoPlistPath;
        [SSZipArchive unzipFileAtPath:fromPath toDestination:NSTemporaryDirectory() overwrite:YES password:nil progressHandler:^(NSString * _Nonnull entry, unz_file_info zipInfo, long entryNumber, long total) {
            if ([[entry.lastPathComponent substringFromIndex:(entry.lastPathComponent.length-4)].lowercaseString isEqualToString: @".app"]) {
                payloadEntry = entry;
            }
            NSString *mainInfoPlistPath = [NSString stringWithFormat:@"%@Info.plist",payloadEntry].lowercaseString;
            if ([entry.lowercaseString isEqualToString:mainInfoPlistPath]) {
                infoPlistPath = entry;
            }
            [self showStatus:@"Extracting files..." andShowProgressBar:YES withProgress:-1];
            [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"%@-%@",[NSNumber numberWithLong:entryNumber], [NSNumber numberWithLong:total]]];
        } completionHandler:^(NSString * _Nonnull path, BOOL succeeded, NSError * _Nonnull error) {
            if (error) {
                [self progressCompletedViewState];
                [Common showAlertWithTitle:@"AppBox - Error" andMessage:error.localizedDescription];
                return;
            }
            
            //get info.plist
            project.ipaInfoPlist = [NSDictionary dictionaryWithContentsOfFile:[NSTemporaryDirectory() stringByAppendingPathComponent:infoPlistPath]];
            if (project.ipaInfoPlist == nil) {
                [self progressCompletedViewState];
                [Common showAlertWithTitle:@"AppBox - Error" andMessage:@"AppBox can't able to find Info.plist in you IPA."];
                return;
            }
            [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"\n\n======\nIPA Info.plist\n======\n\n - %@",project.ipaInfoPlist]];
            
            //upload ipa
            fileType = FileTypeIPA;
            [self.restClient uploadFile:ipaFileURL.lastPathComponent toPath:project.dbDirectory.absoluteString withParentRev:nil fromPath:fromPath];
        }];
    }else{
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"\n\n======\nFile Not Exist - %@\n======\n\n",fromPath]];
    }
}


#pragma mark - DB Delegate
- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId{
}

#pragma mark - RestClient Delegate
//Upload File
-(void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error{
    [Common showAlertWithTitle:@"Error" andMessage:error.localizedDescription];
    [self progressCompletedViewState];
}

-(void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata{
    if (fileType == FileTypeIPA){
        [self disableEmailFields];
    }
    [restClient loadSharableLinkForFile:[NSString stringWithFormat:@"%@/%@",project.dbDirectory.absoluteString ,metadata.filename] shortUrl:NO];
    NSString *status = [NSString stringWithFormat:@"Creating Sharable Link for %@",(fileType == FileTypeIPA)?@"IPA":@"Manifest"];
    [self showStatus:status andShowProgressBar:YES withProgress:-1];
    [Common showLocalNotificationWithTitle:@"AppBox" andMessage:[NSString stringWithFormat:@"%@ file uploaded.",(fileType == FileTypeIPA)?@"IPA":@"Manifest"]];
}

-(void)restClient:(DBRestClient *)client uploadProgress:(CGFloat)progress forFile:(NSString *)destPath from:(NSString *)srcPath{
    if (fileType == FileTypeIPA) {
        NSString *status = [NSString stringWithFormat:@"Uploading IPA (%@%%)",[NSNumber numberWithInt:progress * 100]];
        [self showStatus:status andShowProgressBar:YES withProgress:progress];
        NSLog(@"ipa upload progress %@",[NSNumber numberWithFloat:progress]);
    }else if (fileType == FileTypeManifest){
        NSString *status = [NSString stringWithFormat:@"Uploading Manifest (%@%%)",[NSNumber numberWithInt:progress * 100]];
        [self showStatus:status andShowProgressBar:YES withProgress:progress];
        NSLog(@"manifest upload progress %@",[NSNumber numberWithFloat:progress]);
    }
}

//Shareable Link
-(void)restClient:(DBRestClient *)restClient loadSharableLinkFailedWithError:(NSError *)error{
    [Common showAlertWithTitle:@"Error" andMessage:error.localizedDescription];
    [self progressCompletedViewState];
}

-(void)restClient:(DBRestClient *)restClientLocal loadedSharableLink:(NSString *)link forFile:(NSString *)path{
    if (fileType == FileTypeIPA) {
        NSString *shareableLink = [link stringByReplacingCharactersInRange:NSMakeRange(link.length-1, 1) withString:@"1"];
        project.ipaFileDBShareableURL = [NSURL URLWithString:shareableLink];
        [project createManifestWithIPAURL:project.ipaFileDBShareableURL completion:^(NSString *manifestPath) {
            fileType = FileTypeManifest;
            [restClientLocal uploadFile:@"manifest.plist" toPath:project.dbDirectory.absoluteString withParentRev:nil fromPath:manifestPath];
        }];

    }else if (fileType == FileTypeManifest){
        NSString *shareableLink = [link substringToIndex:link.length-5];
        NSLog(@"manifest link - %@",shareableLink);
        project.manifestFileSharableURL = [NSURL URLWithString:shareableLink];
        NSString *requiredLink = [shareableLink componentsSeparatedByString:@"dropbox.com"][1];
        
        //create short url
        GooglURLShortenerService *service = [GooglURLShortenerService serviceWithAPIKey:@"AIzaSyD5c0jmblitp5KMZy2crCbueTU-yB1jMqI"];
        [Tiny shortenURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://tryapp.github.io?url=%@",requiredLink]] withService:service completion:^(NSURL *shortURL, NSError *error) {
            project.appShortShareableURL = shortURL;
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *status = [NSString stringWithFormat:@"Last Build URL - %@",project.appShortShareableURL.absoluteString];
                [self showStatus:status andShowProgressBar:NO withProgress:0];
                if (textFieldEmail.stringValue.length > 0 && [Common isValidEmail:textFieldEmail.stringValue]) {
                    [self performSegueWithIdentifier:@"MailView" sender:self];
                }else{
                    [self performSegueWithIdentifier:@"ShowLink" sender:self];
                }
                [self progressCompletedViewState];
            });
        }];
    }
}

#pragma mark - Dropbox Helper
- (void)authHelperStateChangedNotification:(NSNotification *)notification {
    if ([[DBSession sharedSession] isLinked]) {
        [self progressCompletedViewState];
    }
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    // This gets called when the user clicks Show "App name". You don't need to do anything for Dropbox here
}

- (DBRestClient *)restClient {
    if (!restClient) {
        restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
    }
    return restClient;
}

#pragma mark - Controller Helper

-(void)progressCompletedViewState{

}

-(void)disableEmailFields{
    
}

-(void)resetBuildOptions{
    [comboTeamId removeAllItems];
    [comboBuildScheme removeAllItems];
}

-(void)showStatus:(NSString *)status andShowProgressBar:(BOOL)showProgressBar withProgress:(double)progress{
    [[AppDelegate appDelegate]addSessionLog:[NSString stringWithFormat:@"%@",status]];
    [labelStatus setStringValue:status];
    [labelStatus setHidden:!(status != nil && status.length > 0)];
    [progressIndicator setHidden:!showProgressBar];
    [progressIndicator setIndeterminate:(progress == -1)];
    [viewProgressStatus setHidden: (labelStatus.hidden && progressIndicator.hidden)];
    if (progress == -1){
        if (showProgressBar){
            [progressIndicator startAnimation:self];
        }else{
            [progressIndicator stopAnimation:self];
        }
    }else{
        if (!showProgressBar){
            [progressIndicator stopAnimation:self];
        }else{
            [progressIndicator setDoubleValue:progress];
        }
    }
}

-(void)updateBuildButtonState{
    BOOL enable = (comboBuildScheme.stringValue != nil && comboBuildType.stringValue.length > 0 &&
                   comboBuildType.stringValue != nil && comboBuildType.stringValue.length > 0);
    [buttonBuild setEnabled:enable];
    [buttonBuildAndUpload setEnabled:enable];
}

#pragma mark - MailDelegate
-(void)mailViewLoadedWithWebView:(WebView *)webView{
    
}

-(void)mailSentWithWebView:(WebView *)webView{
    if (buttonShutdownMac.state == NSOnState){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [Common shutdownSystem];
        });
    }
}

-(void)invalidPerametersWithWebView:(WebView *)webView{
    
}

-(void)loginSuccessWithWebView:(WebView *)webView{
    [buttonSendMail setState:NSOnState];
    [self enableMailField:YES];
}

-(void)enableMailField:(BOOL)enable{
    [textFieldEmail setEnabled:enable];
    [textFieldMessage setEnabled:enable];
}

#pragma mark - Navigation
-(void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender{
    if ([segue.destinationController isKindOfClass:[ShowLinkViewController class]]) {
        ((ShowLinkViewController *)segue.destinationController).appLink = project.appShortShareableURL.absoluteString;
    }else if([segue.destinationController isKindOfClass:[MailViewController class]]){
        MailViewController *mailViewController = ((MailViewController *)segue.destinationController);
        [mailViewController setDelegate:self];
        if (project.appShortShareableURL == nil){
            [mailViewController setUrl: @"https://tryapp.github.io/mail"];
        }else{
            NSString *mailURL = [project buildMailURLStringForEmailId:textFieldEmail.stringValue andMessage:textFieldMessage.stringValue];
            [mailViewController setUrl: mailURL];
        }
    }
}
@end
