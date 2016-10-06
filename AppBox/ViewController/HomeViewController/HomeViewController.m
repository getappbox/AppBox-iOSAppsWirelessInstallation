//
//  HomeViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 29/08/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "HomeViewController.h"


@implementation HomeViewController{
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
    //dev
    NSString *appKey = @"86tfx5bu3356fqo";
    NSString *appSecret = @"mq4l1damoz8hwrr";
    NSString *root = kDBRootAppFolder;
    
    DBSession *session = [[DBSession alloc] initWithAppKey:appKey appSecret:appSecret root:root];
    session.delegate = self;
    [DBSession setSharedSession:session];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authHelperStateChangedNotification:) name:DBAuthHelperOSXStateChangedNotification object:[DBAuthHelperOSX sharedHelper]];
    
    NSAppleEventManager *em = [NSAppleEventManager sharedAppleEventManager];
    [em setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
    if ([[DBSession sharedSession] isLinked]) {
        [self updateDropBoxLinkButton];
    }
    
    textViewEmailContent.font = textFieldEmail.font;
}

#pragma mark - Controllers Actions
- (IBAction)buttonLinkWithDropboxTapped:(NSButton *)sender {
    if ([[DBSession sharedSession] isLinked]) {
        // The link button turns into an unlink button when you're linked
//        [[DBSession sharedSession] unlinkAll];
//        restClient = nil;
        [self performSegueWithIdentifier:@"ShowDashboard" sender:sender];
        [self updateDropBoxLinkButton];
    } else {
        [[DBAuthHelperOSX sharedHelper] authenticate];
    }
}

- (IBAction)buttonSelectIPAFileTapped:(NSButton *)sender {
    //select ipa file
    NSOpenPanel * panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:NO];
    [panel setCanChooseFiles:YES];
    [panel setFloatingPanel:YES];
    [panel setAllowedFileTypes:[NSArray arrayWithObjects:@"ipa",nil]];
    NSInteger result = [panel runModal];
    NSURL *ipaFileURL;
    if(result == NSModalResponseOK){
         ipaFileURL = [[panel URLs] firstObject];
    }
    //check url
    if (ipaFileURL.isFileURL) {
        uuid = [Common generateUUID];
        //Set progress started view state
        [self progressStartedViewState];
        labelIPAName.stringValue = ipaFileURL.lastPathComponent;
        NSString *fromPath = [[ipaFileURL.absoluteString substringFromIndex:7] stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
        
        //Unzip ipa
        __block NSString *payloadEntry;
        __block NSString *infoPlistPath;
        [SSZipArchive unzipFileAtPath:fromPath toDestination:NSTemporaryDirectory() overwrite:YES password:nil progressHandler:^(NSString * _Nonnull entry, unz_file_info zipInfo, long entryNumber, long total) {
            if ([[entry.lastPathComponent substringFromIndex:(entry.lastPathComponent.length-4)].lowercaseString isEqualToString: @".app"]) {
                payloadEntry = entry;
            }
            if ([[entry lastPathComponent].lowercaseString isEqualToString:@"info.plist"]) {
                infoPlistPath = entry;
            }
            NSLog(@"Extracting file %@-%@",[NSNumber numberWithLong:entryNumber], [NSNumber numberWithLong:total]);
        } completionHandler:^(NSString * _Nonnull path, BOOL succeeded, NSError * _Nonnull error) {
            if (error) {
                [Common showAlertWithTitle:@"AppBox - Error" andMessage:error.localizedDescription];
                return;
            }
            
            //get info.plist
            ipaInfoPlist = [NSDictionary dictionaryWithContentsOfFile:[NSTemporaryDirectory() stringByAppendingPathComponent:infoPlistPath]];
            if (ipaInfoPlist == nil) {
                [Common showAlertWithTitle:@"AppBox - Error" andMessage:@"AppBox can't able to find Info.plist in you IPA."];
                return;
            }
            NSLog(@"ipaInfo - %@", ipaInfoPlist);
            
            //upload ipa
            fileType = FileTypeIPA;
            [restClient uploadFile:ipaFileURL.lastPathComponent toPath:[self getDBDirForThisVersion] withParentRev:nil fromPath:fromPath];
        }];
    }
}

#pragma mark - DBSession Delegate
- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId{
    [Common showAlertWithTitle:@"Authorization Failed" andMessage:@""];
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
                [Common sendEmailToAddress:textFieldEmail.stringValue withSubject:textFieldEmailSubject.stringValue andBody:[NSString stringWithFormat:@"%@\n\n%@\n\n---\n%@",textViewEmailContent.string,shortURL.absoluteString,@"Build generated and distributed by AppBox - http://bit.ly/GetAppBox"]];
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
    [self updateDropBoxLinkButton];
    if ([[DBSession sharedSession] isLinked]) {
        // You can now start using the API!
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
- (void)updateDropBoxLinkButton{
    if ([[DBSession sharedSession] isLinked]) {
        buttonSelectIPAFile.enabled = YES;
        buttonLinkWithDropbox.title = @"Dashboard";
        [self restClient];
    } else {
        buttonSelectIPAFile.enabled = NO;
        buttonLinkWithDropbox.title = @"Link Dropbox";
        buttonLinkWithDropbox.state = [[DBAuthHelperOSX sharedHelper] isLoading] ? NSOffState : NSOnState;
    }
}

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
    labelIPAName.hidden = YES;
    progressIndicator.hidden = YES;
    viewProgressStatus.hidden = YES;
    
    //button
    buttonSelectIPAFile.enabled = YES;
    buttonLinkWithDropbox.enabled = YES;
    buttonShutdownMac.enabled = YES;
    
    //email
    textFieldEmail.enabled = YES;
    textFieldEmailSubject.enabled = YES;
    textViewEmailContent.editable = YES;
}

-(void)progressStartedViewState{
    //label
    labelStatus.hidden = NO;
    labelIPAName.hidden = NO;
    progressIndicator.hidden = NO;
    viewProgressStatus.hidden = NO;
    
    //button
    buttonSelectIPAFile.enabled = NO;
    buttonLinkWithDropbox.enabled = NO;
}

-(void)disableEmailFields{
    textFieldEmail.enabled = NO;
    buttonShutdownMac.enabled = NO;
    textFieldEmailSubject.enabled = NO;
    textViewEmailContent.editable = NO;
}

#pragma mark - Navigation
-(void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender{
    if ([segue.destinationController isKindOfClass:[ShowLinkViewController class]]) {
        ((ShowLinkViewController *)segue.destinationController).appLink = appShortSharedURL.absoluteString;
    }
}


@end
