//
//  HomeViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 29/08/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "HomeViewController.h"

static NSString *const UNIQUE_LINK_SHARED = @"uniqueLinkShared";
static NSString *const UNIQUE_LINK_SHORT = @"uniqueLinkShort";
static NSString *const FILE_NAME_UNIQUE_JSON = @"appinfo.json";

@implementation HomeViewController{
    XCProject *project;
    ScriptType scriptType;
    FileType fileType;
    NSArray *allTeamIds;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    project = [[XCProject alloc] init];
    allTeamIds = [KeychainHandler getAllTeamId];
    
    //Init DBSession
    DBSession *session = [[DBSession alloc] initWithAppKey:abDbAppkey appSecret:abDbScreatkey root:abDbRoot];
    [session setDelegate:self];
    [DBSession setSharedSession:session];
    
    //Notification Handler
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authHelperStateChangedNotification:) name:DBAuthHelperOSXStateChangedNotification object:[DBAuthHelperOSX sharedHelper]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gmailLogoutHandler:) name:abGmailLoggedOutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropboxLogoutHandler:) name:abDropBoxLoggedOutNotification object:nil];
    
    NSAppleEventManager *em = [NSAppleEventManager sharedAppleEventManager];
    [em setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
    //setup initial value
    [project setBuildDirectory: [UserData buildLocation]];
}

- (void)viewWillAppear{
    [super viewWillAppear];
    [self updateMenuButtons];
    
    //Handle Dropbox Login
    if (![[DBSession sharedSession] isLinked]) {
        [self performSegueWithIdentifier:@"DropBoxLogin" sender:self];
    }else{
        [self viewStateForProgressFinish:YES];
    }
}


#pragma mark - Controls Action Handler -
#pragma mark → Project / Workspace Controls Action
//Project Path Handler
- (IBAction)projectPathHandler:(NSPathControl *)sender {
    NSURL *senderURL = [sender.URL copy];
    if (![project.fullPath isEqualTo:senderURL]){
        [self viewStateForProgressFinish:YES];
        [project setFullPath: senderURL];
        [sender setURL:senderURL];
        [self runGetSchemeScript];
    }
}

//Scheme Value Changed
- (IBAction)comboBuildSchemeValueChanged:(NSComboBox *)sender {
    [self updateViewState];
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
        [self updateViewState];
    }
}

#pragma mark → IPA File Controlles Actions
//IPA File Path Handler
- (IBAction)ipaFilePathHandle:(NSPathControl *)sender {
    if (![project.fullPath isEqual:sender.URL]){
        project.ipaFullPath = sender.URL.filePathURL;
        [self updateViewState];
    }
}

- (IBAction)buttonUniqueLinkTapped:(NSButton *)sender{
    [textFieldBundleIdentifier setEnabled:(sender.state == NSOnState)];
}

- (IBAction)buttonSameLinkHelpTapped:(NSButton *)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText: abKeepSameLinkHelpTitle];
    [alert setInformativeText:abKeepSameLinkHelpMessage];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert addButtonWithTitle:@"Know More"];
    [alert addButtonWithTitle:@"Ok"];
    if ([alert runModal] == NSAlertFirstButtonReturn){
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:abKeepSameLinkReadMoreURL]];
    }
}


#pragma mark → Mail Controls Action
//Send mail option
- (IBAction)sendMailOptionValueChanged:(NSButton *)sender {
    if (sender.state == NSOnState && ![UserData isGmailLoggedIn]){
        [sender setState:NSOffState];
        [self performSegueWithIdentifier:@"MailView" sender:self];
    }
    [self enableMailField:(sender.state == NSOnState)];
}

//Shutdown mac option
- (IBAction)sendMailMacOptionValueChanged:(NSButton *)sender {
    //No action required
}

//email id text field
- (IBAction)textFieldMailValueChanged:(NSTextField *)sender {
    [buttonShutdownMac setEnabled:[MailHandler isValidEmail:sender.stringValue]];
    if ([MailHandler isValidEmail:sender.stringValue]){
        [UserData setUserEmail:sender.stringValue];
    }else{
        [buttonShutdownMac setState:NSOffState];
    }
}

//developer message text field
- (IBAction)textFieldDevMessageValueChanged:(NSTextField *)sender {
    if (sender.stringValue.length > 0){
        [UserData setUserMessage:sender.stringValue];
    }
}

#pragma mark → Final Action Button (Build/IPA)
//Build Button Action
- (IBAction)actionButtonTapped:(NSButton *)sender {
    if (![sender.title.lowercaseString isEqualToString:@"stop"]){
        [[textFieldEmail window] makeFirstResponder:self.view];
        if (project.fullPath){
            [Answers logCustomEventWithName:@"Archive and Upload IPA" customAttributes:[self getBasicViewStateWithOthersSettings:@{
                @"Build Type" : comboBuildType.stringValue,
            }]];
            [project setIsBuildOnly:NO];
            [self runBuildScript];
        }else if (project.ipaFullPath){
            [Answers logCustomEventWithName:@"Upload IPA" customAttributes:[self getBasicViewStateWithOthersSettings:nil]];
            [self uploadIPAFileWithLocalURL:project.ipaFullPath];
        }
        [self viewStateForProgressFinish:NO];
    }else{
        [Common showAlertWithTitle:@"AppBox" andMessage:@"Comming Soon... You can quit and start again :D !!"];
    }
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

#pragma mark → Run and Capture task data

- (void)runTaskWithLaunchPath:(NSString *)launchPath andArgument:(NSArray *)arguments{
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = launchPath;
    task.arguments = arguments;
    [self captureStandardOutputWithTask:task];
    [task launch];
    if (scriptType == ScriptTypeTeamId){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [task terminate];
            [[AppDelegate appDelegate] addSessionLog:@"terminating task!!"];
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
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Task Output - %@\n",outputString]];
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
                            NSDictionary *team = [[allTeamIds filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.teamId LIKE %@",project.teamId]] firstObject];
                            if (team != nil){
                                [comboTeamId selectItemAtIndex:[allTeamIds indexOfObject:team]];
                            }else{
                                [comboTeamId addItemWithObjectValue:project.teamId];
                                [comboTeamId selectItemWithObjectValue:project.teamId];
                            }
                            [self showStatus:@"Now please select ipa type (save for). You can view log from File -> View Log." andShowProgressBar:NO withProgress:-1];
                        }
                    }
                } else if ([outputString.lowercaseString containsString:@"endofteamidscript"] || outputString.lowercaseString.length == 0) {
                    [self showStatus:@"Can't able to find Team ID! Please select/enter manually!" andShowProgressBar:NO withProgress:-1];
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
                    //Check and Upload IPA File
                    if (project.isBuildOnly){
                        [self showStatus:[NSString stringWithFormat:@"Export Succeeded - %@",project.buildUUIDDirectory] andShowProgressBar:NO withProgress:-1];
                    }else{
                        [self checkIPACreated];
                        [self showStatus:@"Export Succeeded" andShowProgressBar:YES withProgress:-1];
                    }
                    
                } else if ([outputString.lowercaseString containsString:@"export failed"]){
                    [self showStatus:@"Export Failed" andShowProgressBar:NO withProgress:-1];
                    [self viewStateForProgressFinish:YES];
                } else if ([outputString.lowercaseString containsString:@"archive failed"]){
                    [self showStatus:@"Archive Failed" andShowProgressBar:NO withProgress:-1];
                    [self viewStateForProgressFinish:YES];
                } else {
                    [pipe.fileHandleForReading waitForDataInBackgroundAndNotify];
                }
            }
        });
    }];
}

#pragma mark - Get IPA Info -

-(void)checkIPACreated{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([[NSFileManager defaultManager] fileExistsAtPath:project.ipaFullPath.resourceSpecifier]){
            [self getIPAInfoFromLocalURL:project.ipaFullPath];
        }else{
            [self checkIPACreated];
        }
    });
}

- (void)getIPAInfoFromLocalURL:(NSURL *)ipaFileURL{
    NSString *fromPath = [ipaFileURL.resourceSpecifier stringByRemovingPercentEncoding];
    if ([[NSFileManager defaultManager] fileExistsAtPath:fromPath]) {
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"\n\n======\nUploading IPA - %@\n======\n\n",fromPath]];
        //Unzip ipa
        __block NSString *payloadEntry;
        __block NSString *infoPlistPath;
        [SSZipArchive unzipFileAtPath:fromPath toDestination:NSTemporaryDirectory() overwrite:YES password:nil progressHandler:^(NSString * _Nonnull entry, unz_file_info zipInfo, long entryNumber, long total) {
            if ((entry.lastPathComponent.length > 4) && [[entry.lastPathComponent substringFromIndex:(entry.lastPathComponent.length-4)].lowercaseString isEqualToString: @".app"]) {
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
                [self viewStateForProgressFinish:YES];
                [Common showAlertWithTitle:@"AppBox - Error" andMessage:error.localizedDescription];
                return;
            }
            
            //get info.plist
            [project setIpaInfoPlist: [NSDictionary dictionaryWithContentsOfFile:[NSTemporaryDirectory() stringByAppendingPathComponent:infoPlistPath]]];
            if (project.ipaInfoPlist == nil) {
                [self viewStateForProgressFinish:YES];
                [Common showAlertWithTitle:@"AppBox - Error" andMessage:@"AppBox can't able to find Info.plist in you IPA."];
                return;
            }
            
            //set dropbox folder name
            if (textFieldBundleIdentifier.stringValue.length == 0){
                [textFieldBundleIdentifier setStringValue: project.identifer];
            }
            [self showStatus:@"Ready to upload..." andShowProgressBar:NO withProgress:-1];
            
            //upload ipa file directly if archive and ipa selected
            if (tabView.tabViewItems.firstObject.tabState == NSSelectedTab){
                [self uploadIPAFileWithLocalURL:project.ipaFullPath];
            }
        }];
    }else{
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"\n\n======\nFile Not Exist - %@\n======\n\n",fromPath]];
        [self viewStateForProgressFinish:YES];
    }
}

-(void)uploadIPAFileWithLocalURL:(NSURL *)ipaURL{
    if(ipaURL == nil){
        [Common showAlertWithTitle:@"IPA File Missing" andMessage:@"Please select the IPA file and try again."];
        return;
    }
    if (tabView.tabViewItems.lastObject.tabState == NSSelectedTab){
        [self getIPAInfoFromLocalURL:project.ipaFullPath];
    }
    if(![textFieldBundleIdentifier.stringValue isEqualToString:project.identifer] && textFieldBundleIdentifier.stringValue.length>0){
        NSString *bundlePath = [NSString stringWithFormat:@"/%@",textFieldBundleIdentifier.stringValue];
        bundlePath = [bundlePath stringByReplacingOccurrencesOfString:@" " withString:abEmptyString];
        [project setBundleDirectory:[NSURL URLWithString:bundlePath]];
        [project upadteDbDirectoryByBundleDirectory];
    }
    NSString *fromPath = [project.ipaFullPath.resourceSpecifier stringByRemovingPercentEncoding];
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"\n\n======\nIPA Info.plist\n======\n\n - %@",project.ipaInfoPlist]];
    
    //upload ipa
    fileType = FileTypeIPA;
    [self.restClient uploadFile:project.ipaFullPath.lastPathComponent toPath:project.dbDirectory.absoluteString withParentRev:nil fromPath:fromPath];
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Temporaray folder %@",NSTemporaryDirectory()]];
}

#pragma mark - Updating Unique Link -
-(void)updateUniquLinkDictinory:(NSMutableDictionary *)dictUniqueLink{
    if(![dictUniqueLink isKindOfClass:[NSDictionary class]])
        dictUniqueLink = [NSMutableDictionary new];
    NSDictionary *latestVersion = @{
                                    @"name" : project.name,
                                    @"version" : project.version,
                                    @"build" : project.build,
                                    @"identifier" : project.identifer,
                                    @"manifestLink" : project.manifestFileSharableURL.absoluteString,
                                    @"timestamp" : [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]
                                    };
    NSMutableArray *versionHistory = [[dictUniqueLink objectForKey:@"versions"] mutableCopy];
    if(!versionHistory){
        versionHistory = [NSMutableArray new];
    }
    [versionHistory addObject:latestVersion];
    [dictUniqueLink setObject:versionHistory forKey:@"versions"];
    [dictUniqueLink setObject:latestVersion forKey:@"latestVersion"];
    [self writeUniqueJsonWithDict:dictUniqueLink];
    project.uniquelinkShareableURL = [NSURL URLWithString:[dictUniqueLink objectForKey:UNIQUE_LINK_SHARED]];
    project.appShortShareableURL = [NSURL URLWithString:[dictUniqueLink objectForKey:UNIQUE_LINK_SHORT]];
    [self uploadUniqueLinkJsonFile];
}

- (NSDictionary *)getUniqueJsonDict{
    NSError *error;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[NSTemporaryDirectory() stringByAppendingPathComponent:FILE_NAME_UNIQUE_JSON]] options:kNilOptions error:&error];
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"%@ : %@",FILE_NAME_UNIQUE_JSON,dictionary]];
    return dictionary;
}

-(void)writeUniqueJsonWithDict:(NSDictionary *)jsonDict{
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:FILE_NAME_UNIQUE_JSON];
    if([[NSFileManager defaultManager] fileExistsAtPath:path]){
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:nil];
    [jsonData writeToFile:path atomically:YES];
}

-(void)uploadUniqueLinkJsonFile{
    fileType = FileTypeJson;
    [self.restClient uploadFile:FILE_NAME_UNIQUE_JSON toPath:project.bundleDirectory.absoluteString withParentRev:project.uniqueLinkJsonMetaData.rev fromPath:[NSTemporaryDirectory() stringByAppendingPathComponent:FILE_NAME_UNIQUE_JSON]];
}

-(void)handleAfterUniqueJsonMetaDataLoaded{
    if(project.uniqueLinkJsonMetaData){
        NSString *tempUniqueJsonPath = [NSTemporaryDirectory() stringByAppendingPathComponent:FILE_NAME_UNIQUE_JSON];
        [self.restClient loadFile:project.uniqueLinkJsonMetaData.path intoPath:tempUniqueJsonPath];
    }else{
        [self updateUniquLinkDictinory:[NSMutableDictionary new]];
    }
}

#pragma mark - DB and RestClient Delegate -
#pragma mark → DB Delegate
- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId{
    
}

#pragma mark →RestClient Delegate
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata{
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Loaded Meta Data %@",metadata]];
    if([metadata.path isEqualToString:project.bundleDirectory.absoluteString]){
        for (DBMetadata *contentMetaData in [metadata contents]) {
            if([contentMetaData.filename isEqualToString:FILE_NAME_UNIQUE_JSON]){
                project.uniqueLinkJsonMetaData = contentMetaData;
                break;
            }
        }
        [self handleAfterUniqueJsonMetaDataLoaded];
    }
}

- (void)restClient:(DBRestClient*)client metadataUnchangedAtPath:(NSString*)path{
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Meta unchanged path %@",path]];
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error{
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Error while loading metadata %@",error]];
    [self handleAfterUniqueJsonMetaDataLoaded];
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath{
    if([destPath hasSuffix:FILE_NAME_UNIQUE_JSON]){
        [self updateUniquLinkDictinory:[[self getUniqueJsonDict] mutableCopy]];
    }
}

-(void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error{
    
}

//Upload File
-(void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error{
    [Common showAlertWithTitle:@"Error" andMessage:error.localizedDescription];
    [self viewStateForProgressFinish:YES];;
}

-(void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata{
    if(fileType == FileTypeJson){
        project.uniqueLinkJsonMetaData = metadata;
        if(project.appShortShareableURL){
            [self showURL];
            return;
        }
    }
    else if (fileType == FileTypeIPA){
        
    }
    [restClient loadSharableLinkForFile:metadata.path shortUrl:NO];
    NSString *status = [NSString stringWithFormat:@"Creating Sharable Link for %@",(fileType == FileTypeIPA)?@"IPA":@"Manifest"];
    [self showStatus:status andShowProgressBar:YES withProgress:-1];
    [Common showLocalNotificationWithTitle:@"AppBox" andMessage:[NSString stringWithFormat:@"%@ file uploaded.",(fileType == FileTypeIPA)?@"IPA":@"Manifest"]];
}

-(void)restClient:(DBRestClient *)client uploadProgress:(CGFloat)progress forFile:(NSString *)destPath from:(NSString *)srcPath{
    if (fileType == FileTypeIPA) {
        NSString *status = [NSString stringWithFormat:@"Uploading IPA (%@%%)",[NSNumber numberWithInt:progress * 100]];
        [self showStatus:status andShowProgressBar:YES withProgress:progress];
    }else if (fileType == FileTypeManifest){
        NSString *status = [NSString stringWithFormat:@"Uploading Manifest (%@%%)",[NSNumber numberWithInt:progress * 100]];
        [self showStatus:status andShowProgressBar:YES withProgress:progress];
    }else if (fileType == FileTypeJson){
        NSString *status = [NSString stringWithFormat:@"Uploading AppInfo (%@%%)",[NSNumber numberWithInt:progress * 100]];
        [self showStatus:status andShowProgressBar:YES withProgress:progress];
    }
}

//Shareable Link
-(void)restClient:(DBRestClient *)restClient loadSharableLinkFailedWithError:(NSError *)error{
    [Common showAlertWithTitle:@"Error" andMessage:error.localizedDescription];
    [self viewStateForProgressFinish:YES];
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
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Manifest Sharable link - %@",shareableLink]];
        project.manifestFileSharableURL = [NSURL URLWithString:shareableLink];
        if(buttonUniqueLink.state){
            [self.restClient loadMetadata:project.bundleDirectory.absoluteString];
        }else{
            [self createManifestShortSharableUrl];
        }
    }else if (fileType == FileTypeJson){
        NSString *shareableLink = [link substringToIndex:link.length-5];
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"APPInfo Sharable link - %@",shareableLink]];
        project.uniquelinkShareableURL = [NSURL URLWithString:shareableLink];
        NSMutableDictionary *dictUniqueFile = [[self getUniqueJsonDict] mutableCopy];
        [dictUniqueFile setObject:shareableLink forKey:UNIQUE_LINK_SHARED];
        [self writeUniqueJsonWithDict:dictUniqueFile];
        if(project.appShortShareableURL){
            [self showURL];
        }else{
            [self createUniqueShortSharableUrl];
        }
        
    }
}


#pragma mark → Dropbox Helper
- (void)authHelperStateChangedNotification:(NSNotification *)notification {
    [self updateMenuButtons];
    if ([[DBSession sharedSession] isLinked]) {
        [self viewStateForProgressFinish:YES];
    }
}

- (void)dropboxLogoutHandler:(id)sender{
    if ([[DBSession sharedSession] isLinked]){
        [[DBSession sharedSession] unlinkAll];
        restClient = nil;
        [self viewStateForProgressFinish:YES];
        [self performSegueWithIdentifier:@"DropBoxLogin" sender:self];
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

#pragma mark - Create ShortSharable URL -
-(void)createUniqueShortSharableUrl{
    NSString *originalURL = [project.uniquelinkShareableURL.absoluteString componentsSeparatedByString:@"dropbox.com"][1];
    //create short url
    GooglURLShortenerService *service = [GooglURLShortenerService serviceWithAPIKey: abGoogleTiny];
    [Tiny shortenURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?url=%@", abInstallWebAppBaseURL, originalURL]] withService:service completion:^(NSURL *shortURL, NSError *error) {
        project.appShortShareableURL = shortURL;
        NSMutableDictionary *dictUniqueFile = [[self getUniqueJsonDict] mutableCopy];
        [dictUniqueFile setObject:shortURL.absoluteString forKey:UNIQUE_LINK_SHORT];
        [self writeUniqueJsonWithDict:dictUniqueFile];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self uploadUniqueLinkJsonFile];
        });
    }];
}

-(void)createManifestShortSharableUrl{
    NSString *originalURL = [project.manifestFileSharableURL.absoluteString componentsSeparatedByString:@"dropbox.com"][1];
    //create short url
    GooglURLShortenerService *service = [GooglURLShortenerService serviceWithAPIKey: abGoogleTiny];
    [Tiny shortenURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?url=%@", abInstallWebAppBaseURL,originalURL]] withService:service completion:^(NSURL *shortURL, NSError *error) {
        project.appShortShareableURL = shortURL;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showURL];
        });
    }];
}


#pragma mark - Controller Helpers -

-(void)viewStateForProgressFinish:(BOOL)finish{
    [[AppDelegate appDelegate] setProcessing:!finish];
    
    //reset project
    if (finish){
        project = [[XCProject alloc] init];
        [project setBuildDirectory:[UserData buildLocation]];
        [progressIndicator setHidden:YES];
        [labelStatus setStringValue:abEmptyString];
    }
    
    //unique link
    [buttonUniqueLink setEnabled:finish];
    [buttonUniqueLink setState: finish ? NSOffState : buttonUniqueLink.state];
    [textFieldBundleIdentifier setEnabled:(finish && buttonUniqueLink.state == NSOnState)];
    [textFieldBundleIdentifier setStringValue: finish ? abEmptyString : textFieldBundleIdentifier.stringValue];
    
    //ipa path
    [pathIPAFile setEnabled:finish];
    [pathIPAFile setURL: finish ? nil : pathIPAFile.URL];
    
    //project path
    [pathProject setEnabled:finish];
    [pathProject setURL: finish ? nil : pathProject.URL];
    
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

-(void)updateViewState{
    //update action button
    BOOL enable = ((comboBuildScheme.stringValue != nil && comboBuildType.stringValue.length > 0 && //build scheme
                    comboBuildType.stringValue != nil && comboBuildType.stringValue.length > 0 && //build type
                    comboTeamId.stringValue != nil && comboTeamId.stringValue.length > 0 && //team id
                    tabView.tabViewItems.firstObject.tabState == NSSelectedTab) ||
                   
                   //if ipa selected
                   (project.ipaFullPath != nil && tabView.tabViewItems.lastObject.tabState == NSSelectedTab));
    [buttonAction setEnabled:(enable && (pathProject.enabled || pathIPAFile.enabled))];
    [buttonAction setTitle:(tabView.selectedTabViewItem.label)];
    
    //update advanced button
    [buttonAdcanced setEnabled:buttonAction.enabled];
    
}

-(void)updateMenuButtons{
    //Menu Buttons
    BOOL enable = ([[DBSession sharedSession] isLinked] && pathProject.enabled && pathIPAFile.enabled);
    [[[AppDelegate appDelegate] gmailLogoutButton] setEnabled:([UserData isGmailLoggedIn] && enable)];
    [[[AppDelegate appDelegate] dropboxLogoutButton] setEnabled:enable];
}

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

#pragma mark - MailDelegate -
-(void)mailViewLoadedWithWebView:(WebView *)webView{
    
}

-(void)mailSentWithWebView:(WebView *)webView{
    if (buttonShutdownMac.state == NSOnState){
        [self viewStateForProgressFinish:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MacHandler shutdownSystem];
        });
    }else if(![self.presentedViewControllers.lastObject isKindOfClass:[ShowLinkViewController class]]){
        [self performSegueWithIdentifier:@"ShowLink" sender:self];
    }
}

-(void)invalidPerametersWithWebView:(WebView *)webView{
    [Common showAlertWithTitle:@"AppBox Error" andMessage:@"Can't able to send email right now!!"];
    [self viewStateForProgressFinish:YES];
}

-(void)loginSuccessWithWebView:(WebView *)webView{
    [UserData setIsGmailLoggedIn:YES];
    [buttonSendMail setState:NSOnState];
    [self enableMailField:YES];
}

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

- (void)gmailLogoutHandler:(id)sender{
    [buttonSendMail setState:NSOffState];
}

#pragma mark - TabView Delegate
-(void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem{
    [self updateViewState];
}

#pragma mark - Navigation -
-(void)showURL{
    //Log IPA Upload Success Rate with Other Options
    [Answers logCustomEventWithName:@"IPA Uploaded Success" customAttributes:[self getBasicViewStateWithOthersSettings:nil]];
    
    //Send mail if valid email address othervise show link
    if (textFieldEmail.stringValue.length > 0 && [MailHandler isValidEmail:textFieldEmail.stringValue]) {
        [self performSegueWithIdentifier:@"MailView" sender:self];
    }else{
        [self performSegueWithIdentifier:@"ShowLink" sender:self];
    }
}

-(void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender{
    
    //prepare to show link
    if ([segue.destinationController isKindOfClass:[ShowLinkViewController class]]) {
        ((ShowLinkViewController *)segue.destinationController).appLink = project.appShortShareableURL.absoluteString;
        NSString *status = [NSString stringWithFormat:@"App URL - %@",project.appShortShareableURL.absoluteString];
        [self showStatus:status andShowProgressBar:NO withProgress:0];
        [self viewStateForProgressFinish:YES];
    }
    
    //prepare to send mail
    else if([segue.destinationController isKindOfClass:[MailViewController class]]){
        MailViewController *mailViewController = ((MailViewController *)segue.destinationController);
        [mailViewController setDelegate:self];
        if (project.appShortShareableURL == nil){
            [mailViewController setUrl: abMailerBaseURL];
        }else{
            NSString *mailURL = [project buildMailURLStringForEmailId:textFieldEmail.stringValue andMessage:textFieldMessage.stringValue];
            [mailViewController setUrl: mailURL];
        }
    }
    
    //prepare to show advanced project settings
    else if([segue.destinationController isKindOfClass:[ProjectAdvancedViewController class]]){
        ProjectAdvancedViewController *projectAdvancedViewController = ((ProjectAdvancedViewController *)segue.destinationController);
        [projectAdvancedViewController setProject:project];
    }
}

@end
