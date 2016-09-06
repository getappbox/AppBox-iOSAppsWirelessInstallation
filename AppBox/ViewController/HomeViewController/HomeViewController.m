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
    
    __block NSDictionary *ipaInfoPlist;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //dev
    NSString *appKey = @"86tfx5bu3356fqo";
    NSString *appSecret = @"mq4l1damoz8hwrr";
    NSString *root = kDBRootAppFolder;
    
    DBSession *session = [[DBSession alloc] initWithAppKey:appKey appSecret:appSecret root:root];
    [DBSession setSharedSession:session];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authHelperStateChangedNotification:) name:DBAuthHelperOSXStateChangedNotification object:[DBAuthHelperOSX sharedHelper]];
    
    NSAppleEventManager *em = [NSAppleEventManager sharedAppleEventManager];
    [em setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:)
          forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
    if ([[DBSession sharedSession] isLinked]) {
        [self updateDropBoxLinkButton];
    }
}

#pragma mark - Controllers Actions
- (IBAction)buttonLinkWithDropboxTapped:(NSButton *)sender {
    if ([[DBSession sharedSession] isLinked]) {
        // The link button turns into an unlink button when you're linked
        [[DBSession sharedSession] unlinkAll];
        restClient = nil;
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
        self.labelIPAName.stringValue = ipaFileURL.lastPathComponent;
        NSString *fromPath = [[ipaFileURL.absoluteString substringFromIndex:7] stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
        
        //Unzip ipa
        [SSZipArchive unzipFileAtPath:fromPath toDestination:NSTemporaryDirectory() overwrite:YES password:nil progressHandler:^(NSString * _Nonnull entry, unz_file_info zipInfo, long entryNumber, long total) {
            NSLog(@"Extracting file %@-%@",[NSNumber numberWithLong:entryNumber], [NSNumber numberWithLong:total]);
        } completionHandler:^(NSString * _Nonnull path, BOOL succeeded, NSError * _Nonnull error) {
            NSString *payloadPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"payload/%@app/Info.plist",[ipaFileURL.lastPathComponent substringToIndex:ipaFileURL.lastPathComponent.length-3]]];
            
            //get info.plist
            ipaInfoPlist = [NSDictionary dictionaryWithContentsOfFile:payloadPath];
            NSLog(@"ipaInfo - %@", ipaInfoPlist);
            
            //upload ipa
            fileType = FileTypeIPA;
            [restClient uploadFile:ipaFileURL.lastPathComponent toPath:[self getDBDirForThisVersion] withParentRev:nil fromPath:fromPath];
        }];
    }
}

#pragma mark - RestClient Delegate

//Upload File
-(void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error{
    [Common showAlertWithTitle:@"Error" andMessage:error.localizedDescription];
    [self progressCompletedViewState];
}

-(void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata{
    [restClient loadSharableLinkForFile:[NSString stringWithFormat:@"%@/%@",[self getDBDirForThisVersion],metadata.filename] shortUrl:NO];
    [Common showLocalNotificationWithTitle:(fileType == FileTypeIPA)?@"IPA file uploaded.":@"Manifest file uploaded."  andMessage:@""];
}

-(void)restClient:(DBRestClient *)client uploadProgress:(CGFloat)progress forFile:(NSString *)destPath from:(NSString *)srcPath{
    if (fileType == FileTypeIPA) {
        self.progressIndicator.doubleValue = progress;
        self.labelStatus.stringValue = [NSString stringWithFormat:@"Uploading IPA (%@%%)",[NSNumber numberWithInt:progress * 100]];
        NSLog(@"ipa upload progress %@",[NSNumber numberWithFloat:progress]);
    }else if (fileType == FileTypeManifest){
        self.progressIndicator.doubleValue = progress;
        self.labelStatus.stringValue = [NSString stringWithFormat:@"Uploading Manifest (%@%%)",[NSNumber numberWithInt:progress * 100]];
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
        GooglURLShortenerService *service = [GooglURLShortenerService serviceWithAPIKey:@"AIzaSyD5c0jmblitp5KMZy2crCbueTU-yB1jMqI"];
        [Tiny shortenURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.developerinsider.in/assets/pages/iOSDistribution.html?url=%@",requiredLink]] withService:service completion:^(NSURL *shortURL, NSError *error) {
            NSLog(@"Short URL - %@", shortURL);
            [self.textViewEmailContent setString:shortURL.absoluteString];
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
        self.buttonLinkWithDropbox.title = @"Unlink Dropbox";
        self.buttonSelectIPAFile.enabled = YES;
        [self restClient];
    } else {
        self.buttonLinkWithDropbox.title = @"Link Dropbox";
        self.buttonLinkWithDropbox.state = [[DBAuthHelperOSX sharedHelper] isLoading] ? NSOffState : NSOnState;
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
    self.labelStatus.hidden = YES;
    self.labelIPAName.hidden = YES;
    self.progressIndicator.hidden = YES;
    self.viewProgressStatus.hidden = YES;
    self.buttonSelectIPAFile.enabled = YES;
    self.buttonLinkWithDropbox.enabled = YES;
}

-(void)progressStartedViewState{
    self.labelStatus.hidden = NO;
    self.labelIPAName.hidden = NO;
    self.progressIndicator.hidden = NO;
    self.viewProgressStatus.hidden = NO;
    self.buttonSelectIPAFile.enabled = NO;
    self.buttonLinkWithDropbox.enabled = NO;
}

#pragma mark - Email Helper

- (void)sendEmailWithMail:(NSString *) toAddress withSubject:(NSString *) subject Attachments:(NSArray *) attachments {
    NSString *bodyText = @"Your body text \n\r";
    NSString *emailString = [NSString stringWithFormat:@"\
                             tell application \"Mail\"\n\
                             set newMessage to make new outgoing message with properties {subject:\"%@\", content:\"%@\" & return} \n\
                             tell newMessage\n\
                             set visible to false\n\
                             set sender to \"%@\"\n\
                             make new to recipient at end of to recipients with properties {name:\"%@\", address:\"%@\"}\n\
                             tell content\n\
                             ",subject, bodyText, @"McAlarm alert", @"McAlarm User", toAddress ];
    
    //add attachments to script
    for (NSString *alarmPhoto in attachments) {
        emailString = [emailString stringByAppendingFormat:@"make new attachment with properties {file name:\"%@\"} at after the last paragraph\n\
                       ",alarmPhoto];
        
    }
    //finish script
    emailString = [emailString stringByAppendingFormat:@"\
                   end tell\n\
                   send\n\
                   end tell\n\
                   end tell"];
    NSAppleScript *emailScript = [[NSAppleScript alloc] initWithSource:emailString];
    [emailScript executeAndReturnError:nil];
    NSLog(@"Message passed to Mail");
}

@end
