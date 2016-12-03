//
//  HomeViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 29/08/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "HomeViewController.h"


@implementation HomeViewController{
    NSString *projectName;
    NSString *buildLocation;
    NSString *projectLocation;
    ScriptType scriptType;
    
    //IPA upload
    NSString *uuid;
    FileType fileType;
    NSString *ipaFileDBURL;
    NSString *manifestFileDBURL;
    NSDictionary *manifestData;
    NSURL *appShortSharedURL;
    
    __block NSDictionary *ipaInfoPlist;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    DBSession *session = [[DBSession alloc] initWithAppKey:DbAppkey appSecret:DbScreatkey root:DbRoot];
    [session setDelegate:self];
    [DBSession setSharedSession:session];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authHelperStateChangedNotification:) name:DBAuthHelperOSXStateChangedNotification object:[DBAuthHelperOSX sharedHelper]];
    
    NSAppleEventManager *em = [NSAppleEventManager sharedAppleEventManager];
    [em setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
    [pathBuild setURL:[NSURL URLWithString:[@"~/Desktop" stringByExpandingTildeInPath]]];
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
    [self runGetSchemeScript];
}
    
- (IBAction)buttonBuildAndUploadTapped:(NSButton *)sender {
    [self runGetSchemeScript];
}
    
- (IBAction)projectPathHandler:(NSPathControl *)sender {
    projectLocation = [Common getFileDirectoryForFilePath:sender.URL.relativePath];
    labelStatus.stringValue = @"Getting project info";
    [self progressStartedViewState];
    [self runGetSchemeScript];
}

- (IBAction)ipaFilePathHandle:(NSPathControl *)sender {
    [self uploadBuildWithIPAFileURL:sender.URL];
}
    
- (IBAction)buildPathHandler:(NSPathControl *)sender {
    buildLocation = sender.URL.relativePath;
}

#pragma mark - Task

- (void)runGetSchemeScript{
    scriptType = ScriptTypeGetScheme;
    NSString *schemeScriptPath = [[NSBundle mainBundle] pathForResource:@"GetSchemeScript" ofType:@"sh"];
    [self runTaskWithLaunchPath:schemeScriptPath andArgument:@[projectLocation]];
}

- (void)runTeamIDScript{
    scriptType = ScriptTypeTeamId;
    NSString *teamIdScriptPath = [[NSBundle mainBundle] pathForResource:@"TeamIDScript" ofType:@"sh"];
    [self runTaskWithLaunchPath:teamIdScriptPath andArgument:@[projectLocation]];
}

- (void)runBuildScript{
    scriptType = ScriptTypeBuild;
    NSString *teamIdScriptPath = [[NSBundle mainBundle] pathForResource:@"BuildScript" ofType:@"sh"];
    NSMutableArray *buildArgument = [[NSMutableArray alloc] init];
    //${1} Project Location
    [buildArgument addObject:projectLocation];
    
    //${2} Project type workspace/scheme
    if ([pathProject.URL.pathExtension.lowercaseString  isEqual: @"xcworkspace"]){
        [buildArgument addObject:[NSString stringWithFormat:@"-workspace %@",pathProject.URL.lastPathComponent]];
    }else{
        [buildArgument addObject:[NSString stringWithFormat:@"-project %@",pathProject.URL.lastPathComponent]];
    }
    
    //${3} Build Scheme
    [buildArgument addObject:comboBuildScheme.stringValue];
    
    //${4} Archive Location
//    [pathBuild.URL URLByAppendingPathComponent:<#(nonnull NSString *)#>]
//    [buildArgument addObject:[b]]
    
    [self runTaskWithLaunchPath:teamIdScriptPath andArgument:@[projectLocation]];
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
                NSDictionary *project = [NSJSONSerialization JSONObjectWithData:outputData options:NSJSONReadingAllowFragments error:&error];
                if (project != nil && [[project valueForKey:@"project"] valueForKey:@"schemes"] !=nil ){
                    projectName = [[project valueForKey:@"poject"] valueForKey:@"name"];
                    [progressIndicator setDoubleValue:50];
                    [comboBuildScheme removeAllItems];
                    [comboBuildScheme addItemsWithObjectValues:[[project valueForKey:@"project"] valueForKey:@"schemes"]];
                    [comboBuildScheme selectItemAtIndex:0];
                    //TODO: Run Team Id Script Here
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
        uuid = [Common generateUUID];
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
            ipaInfoPlist = [NSDictionary dictionaryWithContentsOfFile:[NSTemporaryDirectory() stringByAppendingPathComponent:infoPlistPath]];
            if (ipaInfoPlist == nil) {
                [self progressCompletedViewState];
                [Common showAlertWithTitle:@"AppBox - Error" andMessage:@"AppBox can't able to find Info.plist in you IPA."];
                return;
            }
            NSLog(@"ipaInfo - %@", ipaInfoPlist);
            
            //upload ipa
            fileType = FileTypeIPA;
            [self.restClient uploadFile:ipaFileURL.lastPathComponent toPath:[self getDBDirForThisVersion] withParentRev:nil fromPath:fromPath];
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
    [restClient loadSharableLinkForFile:[NSString stringWithFormat:@"%@/%@",[self getDBDirForThisVersion],metadata.filename] shortUrl:NO];
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

-(void)restClient:(DBRestClient *)restClient loadedSharableLink:(NSString *)link forFile:(NSString *)path{
    if (fileType == FileTypeIPA) {
        NSString *shareableLink = [link stringByReplacingCharactersInRange:NSMakeRange(link.length-1, 1) withString:@"1"];
        [self createAndUploadManifestWithInfo:ipaInfoPlist andIPAURL:shareableLink];
    }else if (fileType == FileTypeManifest){
        NSString *shareableLink = [link substringToIndex:link.length-5];
        NSLog(@"manifest link - %@",shareableLink);
        NSString *requiredLink = [shareableLink componentsSeparatedByString:@"dropbox.com"][1];
        
        //create short url
        GooglURLShortenerService *service = [GooglURLShortenerService serviceWithAPIKey:@"AIzaSyD5c0jmblitp5KMZy2crCbueTU-yB1jMqI"];
        [Tiny shortenURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://tryapp.github.io?url=%@",requiredLink]] withService:service completion:^(NSURL *shortURL, NSError *error) {
            NSLog(@"Short URL - %@", shortURL);
            appShortSharedURL = shortURL;
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

-(void)createAndUploadManifestWithInfo:(NSDictionary *)infoPlist andIPAURL:(NSString *)ipaURL{
    NSMutableDictionary *assetsDict = [[NSMutableDictionary alloc] init];
    [assetsDict setValue:ipaURL forKey:@"url"];
    [assetsDict setValue:@"software-package" forKey:@"kind"];
    
    NSMutableDictionary *metadataDict = [[NSMutableDictionary alloc] init];
    [metadataDict setValue:@"software" forKey:@"kind"];
    [metadataDict setValue:[ipaInfoPlist valueForKey:@"CFBundleName"] forKey:@"title"];
    [metadataDict setValue:[ipaInfoPlist valueForKey:@"CFBundleIdentifier"] forKey:@"bundle-identifier"];
    [metadataDict setValue:[ipaInfoPlist valueForKey:@"CFBundleShortVersionString"] forKey:@"bundle-version"];
    
    NSMutableDictionary *mainItemDict = [[NSMutableDictionary alloc] init];
    [mainItemDict setValue:[NSArray arrayWithObjects:assetsDict, nil] forKey:@"assets"];
    [mainItemDict setValue:metadataDict forKey:@"metadata"];
    
    NSMutableDictionary *manifestDict = [[NSMutableDictionary alloc] init];
    [manifestDict setValue:[NSArray arrayWithObjects:mainItemDict, nil] forKey:@"items"];
    
    NSString *manifestPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"manifest.plist"];
    [manifestDict writeToFile:manifestPath atomically:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        fileType = FileTypeManifest;
        [restClient uploadFile:@"manifest.plist" toPath:[self getDBDirForThisVersion] withParentRev:nil fromPath:manifestPath];
    });
}

-(NSString *)getDBDirForThisVersion{
    NSString *toPath = [NSString stringWithFormat:@"/%@-ver%@(%@)-%@",[ipaInfoPlist valueForKey:@"CFBundleName"],[ipaInfoPlist valueForKey:@"CFBundleShortVersionString"],[ipaInfoPlist valueForKey:@"CFBundleVersion"],uuid];
    return toPath;
}


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
        ((ShowLinkViewController *)segue.destinationController).appLink = appShortSharedURL.absoluteString;
    }
}
@end
