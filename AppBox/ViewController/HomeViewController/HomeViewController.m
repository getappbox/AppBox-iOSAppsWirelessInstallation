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
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    project = [[XCProject alloc] init];
    
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
    
- (IBAction)buttonBuildTapped:(NSButton *)sender {
    [self runBuildScript];
}
    
- (IBAction)buttonBuildAndUploadTapped:(NSButton *)sender {
    [self runGetSchemeScript];
}
    
- (IBAction)projectPathHandler:(NSPathControl *)sender {
    project.fullPath = sender.URL;
    labelStatus.stringValue = @"Getting project info";
    [self progressStartedViewState];
    [self runGetSchemeScript];
}

- (IBAction)ipaFilePathHandle:(NSPathControl *)sender {
    [self uploadBuildWithIPAFileURL:sender.URL];
}
    
- (IBAction)buildPathHandler:(NSPathControl *)sender {
    [project setBuildDirectory: sender.URL];
}

#pragma mark - Task

- (void)runGetSchemeScript{
    scriptType = ScriptTypeGetScheme;
    NSString *schemeScriptPath = [[NSBundle mainBundle] pathForResource:@"GetSchemeScript" ofType:@"sh"];
    [self runTaskWithLaunchPath:schemeScriptPath andArgument:@[project.rootDirectory]];
}

- (void)runTeamIDScript{
    scriptType = ScriptTypeTeamId;
    NSString *teamIdScriptPath = [[NSBundle mainBundle] pathForResource:@"TeamIDScript" ofType:@"sh"];
    [self runTaskWithLaunchPath:teamIdScriptPath andArgument:@[project.rootDirectory]];
}

- (void)runBuildScript{
    scriptType = ScriptTypeBuild;
    NSString *buildScriptName;
    if ([project.fullPath.pathExtension  isEqual: @"xcworkspace"]){
        buildScriptName = @"WorkspaceBuildScript";
    }else{
        buildScriptName = @"ProjectBuildScript";
    }
    NSString *teamIdScriptPath = [[NSBundle mainBundle] pathForResource:buildScriptName ofType:@"sh"];
    NSMutableArray *buildArgument = [[NSMutableArray alloc] init];
    //${1} Project Location
    [buildArgument addObject:project.rootDirectory];
    
    //${2} Project type workspace/scheme
    [buildArgument addObject:pathProject.URL.lastPathComponent];
    
    //${3} Build Scheme
    [buildArgument addObject:comboBuildScheme.stringValue];
    
    //${4} Archive Location
    [buildArgument addObject:project.buildArchivePath.resourceSpecifier];
    
//    //${5} Archive Location
//    [buildArgument addObject:project.buildArchivePath.resourceSpecifier];
//    
//    //${6} ipa Location
//    [buildArgument addObject:project.buildUUIDDirectory.resourceSpecifier];
//    
    
    
    
    [self runTaskWithLaunchPath:teamIdScriptPath andArgument:buildArgument];
}

#pragma mark - Capture task data

- (void)runTaskWithLaunchPath:(NSString *)launchPath andArgument:(NSArray *)arguments{
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = launchPath;
    task.arguments = arguments;
    [self captureStandardOutputWithTask:task];
    [task launch];
    [task waitUntilExit];
}

- (void)captureStandardOutputWithTask:(NSTask *)task{
    NSPipe *pipe = [[NSPipe alloc] init];
    [task setStandardOutput:pipe];
    [pipe.fileHandleForReading waitForDataInBackgroundAndNotify];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification object:pipe.fileHandleForReading queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        NSData *outputData =  pipe.fileHandleForReading.availableData;
        NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        NSLog(@"%@", outputString);
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
                    //TODO: Run Team Id Script Here
                    [buttonBuild setEnabled:YES];
                    [buttonBuildAndUpload setEnabled:YES];
                }else{
                    NSLog(@"Failed to load scheme information.");
                }
            }
            //Handle Team Id Response
            else if (scriptType == ScriptTypeTeamId){
                
            }
            //Handle Build Response
            else if (scriptType == ScriptTypeBuild){
                
            }
        });
    }];
}

#pragma mark - Upload Build

- (void)uploadBuildWithIPAFileURL:(NSURL *)ipaFileURL{
    if (ipaFileURL.isFileURL) {
        [project createUDIDAnsIsNew:YES];
        //Set progress started view state
        [self progressStartedViewState];
        NSString *fromPath = [[ipaFileURL.absoluteString substringFromIndex:7] stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
        
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
            NSLog(@"Extracting file %@-%@",[NSNumber numberWithLong:entryNumber], [NSNumber numberWithLong:total]);
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
            NSLog(@"ipaInfo - %@", project.ipaInfoPlist);
            
            //upload ipa
            fileType = FileTypeIPA;
            [self.restClient uploadFile:ipaFileURL.lastPathComponent toPath:project.dbDirectory.absoluteString withParentRev:nil fromPath:fromPath];
        }];
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
    labelStatus.stringValue = [NSString stringWithFormat:@"Creating Sharable Link for %@",(fileType == FileTypeIPA)?@"IPA":@"Manifest"];
    [Common showLocalNotificationWithTitle:@"AppBox" andMessage:[NSString stringWithFormat:@"%@ file uploaded.",(fileType == FileTypeIPA)?@"IPA":@"Manifest"]];
}

-(void)restClient:(DBRestClient *)client uploadProgress:(CGFloat)progress forFile:(NSString *)destPath from:(NSString *)srcPath{
    if (fileType == FileTypeIPA) {
        progressIndicator.doubleValue = progress;
        labelStatus.stringValue = [NSString stringWithFormat:@"Uploading IPA (%@%%)",[NSNumber numberWithInt:progress * 100]];
        NSLog(@"ipa upload progress %@",[NSNumber numberWithFloat:progress]);
    }else if (fileType == FileTypeManifest){
        progressIndicator.doubleValue = progress;
        labelStatus.stringValue = [NSString stringWithFormat:@"Uploading Manifest (%@%%)",[NSNumber numberWithInt:progress * 100]];
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
            NSLog(@"Short URL - %@", shortURL);
            project.appShortShareableURL = shortURL;
            if (textFieldEmail.stringValue.length > 0) {
//                [Common sendEmailToAddress:textFieldEmail.stringValue withSubject:textFieldEmailSubject.stringValue andBody:[NSString stringWithFormat:@"%@\n\n%@\n\n---\n%@",textViewEmailContent.string,shortURL.absoluteString,@"Build generated and distributed by AppBox - http://bit.ly/GetAppBox"]];
            }
            if (buttonShutdownMac.state == NSOffState){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self performSegueWithIdentifier:@"ShowLink" sender:self];
                });
            }else{
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(600 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [Common shutdownSystem];
                });
            }
            [self progressCompletedViewState];
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
    labelStatus.hidden = YES;
    progressIndicator.hidden = YES;
    viewProgressStatus.hidden = YES;
    
    //button
    buttonShutdownMac.enabled = YES;
    
    //email
    textFieldEmail.enabled = YES;
}

-(void)progressStartedViewState{
    //label
    labelStatus.hidden = NO;
    progressIndicator.hidden = NO;
    viewProgressStatus.hidden = NO;
}

-(void)disableEmailFields{
    textFieldEmail.enabled = NO;
    buttonShutdownMac.enabled = NO;
}

#pragma mark - Navigation
-(void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender{
    if ([segue.destinationController isKindOfClass:[ShowLinkViewController class]]) {
        ((ShowLinkViewController *)segue.destinationController).appLink = project.appShortShareableURL.absoluteString;
    }
}
@end
