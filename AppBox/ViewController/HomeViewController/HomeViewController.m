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
    
    //Notification Handler
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gmailLogoutHandler:) name:abGmailLoggedOutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropboxLogoutHandler:) name:abDropBoxLoggedOutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLoggedInNotification:) name:abDropBoxLoggedInNotification object:nil];
    
    //setup initial value
    [project setBuildDirectory: [UserData buildLocation]];
}

- (void)viewWillAppear{
    [super viewWillAppear];
    [self updateMenuButtons];
    
    //Handle Dropbox Login
    if ([DropboxClientsManager authorizedClient] == nil) {
        [self performSegueWithIdentifier:@"DropBoxLogin" sender:self];
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
    [sender setStringValue: [sender.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    [buttonShutdownMac setEnabled:[MailHandler isValidEmail:sender.stringValue]];
    if ([MailHandler isValidEmail:sender.stringValue]){
        [UserData setUserEmail:sender.stringValue];
    }else if (sender.stringValue.length > 0){
        [Common showAlertWithTitle:@"Invalid email address" andMessage:@"The email address entered was invalid. Please reenter it (Example: username@example.com)."];
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
        [[AppDelegate appDelegate] setProcessing:true];
        [[textFieldEmail window] makeFirstResponder:self.view];
        if (project.fullPath){
            [Answers logCustomEventWithName:@"Archive and Upload IPA" customAttributes:[self getBasicViewStateWithOthersSettings:@{@"Build Type" : comboBuildType.stringValue}]];
            [project setIsBuildOnly:NO];
            [self runBuildScript];
        }else if (project.ipaFullPath){
            [Answers logCustomEventWithName:@"Upload IPA" customAttributes:[self getBasicViewStateWithOthersSettings:nil]];
            [self getIPAInfoFromLocalURL:project.ipaFullPath];
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
    [project createExportOptionPlist];
    
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
    
    //${7} export options plist Location
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
            
            //Get payload entry
            if ((entry.lastPathComponent.length > 4) && [[entry.lastPathComponent substringFromIndex:(entry.lastPathComponent.length-4)].lowercaseString isEqualToString: @".app"]) {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Found payload at path = %@",entry]];
                payloadEntry = entry;
            }
            
            //Get Info.plist entry
            NSString *mainInfoPlistPath = [NSString stringWithFormat:@"%@Info.plist",payloadEntry].lowercaseString;
            if ([entry.lowercaseString isEqualToString:mainInfoPlistPath]) {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Found Info.plist at path = %@",mainInfoPlistPath]];
                infoPlistPath = entry;
            }
            
            //show status and log files entry
            [self showStatus:@"Extracting files..." andShowProgressBar:YES withProgress:-1];
            [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"%@-%@-%@",[NSNumber numberWithLong:entryNumber], [NSNumber numberWithLong:total], entry]];
        } completionHandler:^(NSString * _Nonnull path, BOOL succeeded, NSError * _Nonnull error) {
            if (error) {
                //show error and return
                [self viewStateForProgressFinish:YES];
                [Common showAlertWithTitle:@"AppBox - Error" andMessage:error.localizedDescription];
                return;
            }
            
            //get info.plist
            [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Final Info.plist path = %@",infoPlistPath]];
            [project setIpaInfoPlist: [NSDictionary dictionaryWithContentsOfFile:[NSTemporaryDirectory() stringByAppendingPathComponent:infoPlistPath]]];
            
            //show error if info.plist is nil or invalid
            if (![project isValidProjectInfoPlist]) {
                [self viewStateForProgressFinish:YES];
                [Common showAlertWithTitle:@"AppBox - Error" andMessage:@"AppBox can't able to find Info.plist in you IPA."];
                return;
            }
            
            //set dropbox folder name & log if user changing folder name or not
            if (textFieldBundleIdentifier.stringValue.length == 0){
                [textFieldBundleIdentifier setStringValue: project.identifer];
                [Answers logCustomEventWithName:@"DB Folder Name" customAttributes:@{@"Custom Name":@0}];
            }else{
                [Answers logCustomEventWithName:@"DB Folder Name" customAttributes:@{@"Custom Name":@1}];
            }
            [self showStatus:@"Ready to upload..." andShowProgressBar:NO withProgress:-1];
            
            //prepare for upload
            NSURL *ipaFile = ([project.ipaFullPath isFileURL]) ? project.ipaFullPath : [NSURL fileURLWithPath:project.ipaFullPath.absoluteString];
            [self uploadIPAFileWithLocalURL: ipaFile];
        }];
    }else{
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"\n\n======\nFile Not Exist - %@\n======\n\n",fromPath]];
        [Common showAlertWithTitle:@"IPA File Missing" andMessage:[NSString stringWithFormat:@"AppBox can't able to find ipa file at %@.",ipaFileURL.absoluteString]];
        [self viewStateForProgressFinish:YES];
    }
}

-(void)uploadIPAFileWithLocalURL:(NSURL *)ipaURL{
    //check unique link settings for Dropbox folder name
    if(![textFieldBundleIdentifier.stringValue isEqualToString:project.identifer] && textFieldBundleIdentifier.stringValue.length>0){
        NSString *bundlePath = [NSString stringWithFormat:@"/%@",textFieldBundleIdentifier.stringValue];
        bundlePath = [bundlePath stringByReplacingOccurrencesOfString:@" " withString:abEmptyString];
        [project setBundleDirectory:[NSURL URLWithString:bundlePath]];
        [project upadteDbDirectoryByBundleDirectory];
    }
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"\n\n======\nIPA Info.plist\n======\n\n - %@",project.ipaInfoPlist]];
    
    //upload ipa
    fileType = FileTypeIPA;
    [self dbUploadFile:ipaURL to:project.dbIPAFullPath.absoluteString mode:[[DBFILESWriteMode alloc] initWithOverwrite]];
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Temporaray folder %@",NSTemporaryDirectory()]];
}

-(void)dbUploadFile:(NSURL *)file to:(NSString *)path mode:(DBFILESWriteMode *)mode{
    //uploadUrl:path inputUrl:file
    [[[[DropboxClientsManager authorizedClient].filesRoutes uploadUrl:path mode:mode autorename:@NO clientModified:nil mute:@NO inputUrl:file]
      //Track response with result and error
      response:^(DBFILESFileMetadata *result, DBFILESUploadError *routeError, DBRequestError *error) {
          if (result) {
              [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Uploaded file metadata = %@", result]];
              
              //AppInfo.json file uploaded and creating shared url
              if(fileType == FileTypeJson){
                  project.uniqueLinkJsonMetaData = result;
                  if(project.appShortShareableURL){
                      [self showURL];
                      return;
                  }else{
                      //create shared url for appinfo.json
                      [self dbSharedURLForFile:result.pathDisplay];
                  }
              }
              //IPA file uploaded and creating shared url
              else if (fileType == FileTypeIPA){
                  [Common showLocalNotificationWithTitle:@"AppBox" andMessage:@"IPA file uploaded."];
                  NSString *status = [NSString stringWithFormat:@"Creating Sharable Link for IPA"];
                  [self showStatus:status andShowProgressBar:YES withProgress:-1];
                  
                  //create shared url for ipa
                  [self dbSharedURLForFile:result.pathDisplay];
              }
              //Manifest file uploaded and creating shared url
              else if (fileType == FileTypeManifest){
                  [Common showLocalNotificationWithTitle:@"AppBox" andMessage:@"Manifest file uploaded."];
                  NSString *status = [NSString stringWithFormat:@"Creating Sharable Link for Manifest"];
                  [self showStatus:status andShowProgressBar:YES withProgress:-1];
                  
                  //create shared url for manifest
                  [self dbSharedURLForFile:result.pathDisplay];
              }
          }
          //unable to upload file, show error
          else {
              NSLog(@"%@\n%@\n", routeError, error);
              [Common showAlertWithTitle:@"Error" andMessage:error.errorContent];
              [self viewStateForProgressFinish:YES];
          }
      }]
     
     //Track and show upload progress
     progress:^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
         //Calculate and show progress based on file type
         CGFloat progress = ((totalBytesWritten * 100) / totalBytesExpectedToWrite) ;
         if (fileType == FileTypeIPA) {
             NSString *status = [NSString stringWithFormat:@"Uploading IPA (%@%%)",[NSNumber numberWithInt:progress]];
             [self showStatus:status andShowProgressBar:YES withProgress:progress/100];
         }else if (fileType == FileTypeManifest){
             NSString *status = [NSString stringWithFormat:@"Uploading Manifest (%@%%)",[NSNumber numberWithInt:progress]];
             [self showStatus:status andShowProgressBar:YES withProgress:progress/100];
         }else if (fileType == FileTypeJson){
             NSString *status = [NSString stringWithFormat:@"Uploading AppInfo (%@%%)",[NSNumber numberWithInt:progress]];
             [self showStatus:status andShowProgressBar:YES withProgress:progress/100];
         }
     }];
}

-(void)dbSharedURLForFile:(NSString *)file{
    [[[DropboxClientsManager authorizedClient].sharingRoutes createSharedLinkWithSettings:file]
     //Track response with result and error
     response:^(DBSHARINGSharedLinkMetadata * _Nullable result, DBSHARINGCreateSharedLinkWithSettingsError * _Nullable settingError, DBRequestError * _Nullable error) {
         if (result){
             
             //Create manifest file with share IPA url and upload manifest file
             if (fileType == FileTypeIPA) {
                 NSString *shareableLink = [result.url stringByReplacingCharactersInRange:NSMakeRange(result.url.length-1, 1) withString:@"1"];
                 project.ipaFileDBShareableURL = [NSURL URLWithString:shareableLink];
                 [project createManifestWithIPAURL:project.ipaFileDBShareableURL completion:^(NSURL *manifestURL) {
                     if (manifestURL == nil){
                         //show error if manifest file url is nil
                         [Common showAlertWithTitle:@"Error" andMessage:@"Unable to create manifest file!!"];
                         [self viewStateForProgressFinish:YES];
                     }else{
                         //change file type and upload manifest
                         fileType = FileTypeManifest;
                         [self dbUploadFile:manifestURL to:project.dbManifestFullPath.absoluteString mode:[[DBFILESWriteMode alloc] initWithOverwrite]];
                     }
                 }];
                 
             }
             //if same link enable load appinfo.json otherwise Create short shareable url of manifest
             else if (fileType == FileTypeManifest){
                 NSString *shareableLink = [result.url substringToIndex:result.url.length-5];
                 [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Manifest Sharable link - %@",shareableLink]];
                 project.manifestFileSharableURL = [NSURL URLWithString:shareableLink];
                 if(buttonUniqueLink.state){
                     //Download previously uploaded appinfo
                     [[[DropboxClientsManager authorizedClient].filesRoutes listRevisions:project.dbAppInfoJSONFullPath.absoluteString limit:@1]
                      response:^(DBFILESListRevisionsResult * _Nullable result, DBFILESListRevisionsError * _Nullable revError, DBRequestError * _Nullable error) {
                          
                          //check there is any rev available
                          if (result && result.isDeleted.boolValue == NO && result.entries.count > 0){
                              [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Loaded Meta Data %@",result]];
                              project.uniqueLinkJsonMetaData = [result.entries firstObject];
                          }
                          
                          //handle meta data
                          [self handleAfterUniqueJsonMetaDataLoaded];
                      }];
                 }else{
                     [self createManifestShortSharableUrl];
                 }
             }
             
             //create app info file short sharable url
             else if (fileType == FileTypeJson){
                 NSString *shareableLink = [result.url substringToIndex:result.url.length-5];
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
         }else{
             [Common showAlertWithTitle:@"Error" andMessage:error.errorContent];
             [self viewStateForProgressFinish:YES];
         }
     }];
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
    NSURL *path = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:FILE_NAME_UNIQUE_JSON]];
    DBFILESWriteMode *mode = (project.uniqueLinkJsonMetaData) ? [[DBFILESWriteMode alloc] initWithUpdate:project.uniqueLinkJsonMetaData.rev] : [[DBFILESWriteMode alloc] initWithOverwrite];
    [self dbUploadFile:path to:project.dbAppInfoJSONFullPath.absoluteString mode:mode];
}

-(void)handleAfterUniqueJsonMetaDataLoaded{
    if(project.uniqueLinkJsonMetaData){
        NSURL *path = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:FILE_NAME_UNIQUE_JSON]];
        [[[DropboxClientsManager authorizedClient].filesRoutes downloadUrl:project.uniqueLinkJsonMetaData.pathDisplay overwrite:YES destination:path]
         response:^(DBFILESFileMetadata * _Nullable result, DBFILESDownloadError * _Nullable downloadError, DBRequestError * _Nullable error, NSURL * _Nonnull url) {
             if (result){
                 if([result.name hasSuffix:FILE_NAME_UNIQUE_JSON]){
                     [self updateUniquLinkDictinory:[[self getUniqueJsonDict] mutableCopy]];
                 }
             }
             else if (downloadError || error){
                 [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Error while loading metadata %@",error]];
                 [self handleAfterUniqueJsonMetaDataLoaded];
             }
         }];
        //        [self.restClient loadFile:project.uniqueLinkJsonMetaData.path intoPath:tempUniqueJsonPath];
    }else{
        [self updateUniquLinkDictinory:[NSMutableDictionary new]];
    }
}


#pragma mark → Dropbox Helper
- (void)handleLoggedInNotification:(NSNotification *)notification{
    [self updateMenuButtons];
    [self viewStateForProgressFinish:YES];
}

- (void)dropboxLogoutHandler:(id)sender{
    if ([DropboxClientsManager authorizedClient]){
        [DropboxClientsManager unlinkClients];
        [self viewStateForProgressFinish:YES];
        [self performSegueWithIdentifier:@"DropBoxLogin" sender:self];
    }
}

#pragma mark - Create ShortSharable URL -
-(void)createUniqueShortSharableUrl{
    NSString *originalURL = [project.uniquelinkShareableURL.absoluteString componentsSeparatedByString:@"dropbox.com"][1];
    //create short url
    project.appLongShareableURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?url=%@", abInstallWebAppBaseURL, originalURL]];
    GooglURLShortenerService *service = [GooglURLShortenerService serviceWithAPIKey: abGoogleTiny];
    [Tiny shortenURL:project.appLongShareableURL withService:service completion:^(NSURL *shortURL, NSError *error) {
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
    project.appLongShareableURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?url=%@", abInstallWebAppBaseURL,originalURL]];
    GooglURLShortenerService *service = [GooglURLShortenerService serviceWithAPIKey: abGoogleTiny];
    [Tiny shortenURL:project.appLongShareableURL withService:service completion:^(NSURL *shortURL, NSError *error) {
        project.appShortShareableURL = shortURL;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showURL];
        });
    }];
}


#pragma mark - Controller Helpers -

-(void)viewStateForProgressFinish:(BOOL)finish{
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Updating view setting for finish - %@", [NSNumber numberWithBool:finish]]];
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
    BOOL enable = ([DropboxClientsManager authorizedClient] && pathProject.enabled && pathIPAFile.enabled);
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
        //set project to destination
        [((ShowLinkViewController *)segue.destinationController) setProject:project];
        
        //set status
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
