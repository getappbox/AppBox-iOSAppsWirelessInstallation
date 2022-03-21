//
//  UploadManager.m
//  AppBox
//
//  Created by Vineet Choudhary on 20/10/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "UploadManager.h"

@implementation UploadManager {
    //For Large Upload
    NSString *sessionId;
    NSData *ipaFileData;
    NSData *nextChunkToUpload;
    NSUInteger chunkSize;
    NSUInteger offset;
    NSFileHandle *fileHandle;
    DBFILESCommitInfo *fileCommitInfo;
    
    //For retry
    NSInteger retryCount;
}

+(void)setupDBClientsManager{
    //Force Foreground Session
    DBUserClient *client = [DBClientsManager authorizedClient];
    if (!client) {
        DBTransportDefaultConfig *transportConfig = [[DBTransportDefaultConfig alloc] initWithAppKey:[[Common currentDBManager] getDBKey] forceForegroundSession:YES];
        [DBClientsManager setupWithTransportConfigDesktop:transportConfig];
        //Default Session (Background)
        //[DBClientsManager setupWithAppKeyDesktop:[DBManager dbKey]];
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        retryCount = 0;
    }
    return self;
}

#pragma mark - UnZip IPA File

-(void)uploadIPAFile:(NSURL *)ipaFileURL{
    [ABLog log:@"Preparing to Upload IPA - %@", ipaFileURL];
    NSString *ipaPath = [ipaFileURL.resourceSpecifier stringByRemovingPercentEncoding];
    if ([[NSFileManager defaultManager] fileExistsAtPath:ipaPath]) {
        [ABLog log:@"Uploading IPA -  %@", ipaPath];
        //Unzip ipa
        __block NSString *payloadEntry;
        __block NSString *infoPlistPath;
        
        NSString *tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];

        [ABLog log:@"Extracting Files to - %@", tempDir];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [SSZipArchive unzipFileAtPath:ipaPath toDestination:tempDir overwrite:YES password:nil progressHandler:^(NSString * _Nonnull entry, unz_file_info zipInfo, long entryNumber, long total) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showStatus:@"Extracting files..." andShowProgressBar:YES withProgress:-1];
                    
                    //Get payload entry
                    if (payloadEntry == nil && [entry containsString:@".app"]) {
                        [[entry pathComponents] enumerateObjectsUsingBlock:^(NSString * _Nonnull pathComponent, NSUInteger idx, BOOL * _Nonnull stop) {
                            if ((pathComponent.length > 4) && [[pathComponent substringFromIndex:(pathComponent.length-4)].lowercaseString isEqualToString: @".app"]) {
                                
                                [ABLog log:@"Found payload at path = %@",entry];
                                payloadEntry = [NSString pathWithComponents:[[entry pathComponents] subarrayWithRange:NSMakeRange(0, idx+1)]];
                                *stop = YES;
                            }
                        }];
                    }
                    
                    //Get Info.plist entry
                    NSString *mainInfoPlistPath = [payloadEntry stringByAppendingPathComponent:@"Info.plist"].lowercaseString;
                    if ([entry.lowercaseString isEqualToString:mainInfoPlistPath]) {
                        [ABLog log:@"Found Info.plist at path = %@",mainInfoPlistPath];
                        infoPlistPath = entry;
                    }
                    
                    //Get embedded mobile provision
                    if (self.project.mobileProvision == nil){
                        NSString *mobileProvisionPath = [payloadEntry stringByAppendingPathComponent:@"embedded.mobileprovision"].lowercaseString;
                        if ([entry.lowercaseString isEqualToString:mobileProvisionPath]){
                            [ABLog log:@"Found mobileprovision at path = %@",mobileProvisionPath];
                            mobileProvisionPath = [tempDir stringByAppendingPathComponent: mobileProvisionPath];
                            self.project.mobileProvision = [[MobileProvision alloc] initWithPath:mobileProvisionPath];
                        }
                    }
                    
                    //show status and log files entry
                    [ABLog log:@"%@-%@-%@",[NSNumber numberWithLong:entryNumber], [NSNumber numberWithLong:total], entry];
                });
            } completionHandler:^(NSString * _Nonnull path, BOOL succeeded, NSError * _Nonnull error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        //show error and return
                        if (self.ciRepoProject) {
                            NSString *log = [NSString stringWithFormat:@"Error - %@", error.localizedDescription];
                            [[AppDelegate appDelegate] addSessionLog:log];
                            exit(abExitCodeUnZipIPAError);
                        } else {
                            [Common showAlertWithTitle:@"AppBox - Error" andMessage:error.localizedDescription];
                        }
                        self.errorBlock(nil, YES);
                        return;
                    }
                    
                    //get info.plist
                    [ABLog log:@"Final Info.plist path = %@",infoPlistPath];
                    [self.project setIpaInfoPlist: [NSDictionary dictionaryWithContentsOfFile:[tempDir stringByAppendingPathComponent:infoPlistPath]]];
                    
                    //show error if info.plist is nil or invalid
                    if (![self.project isValidProjectInfoPlist]) {
                        NSString *log = @"AppBox was not able to find Info.plist in your IPA.";
                        if (self.ciRepoProject) {
                            [[AppDelegate appDelegate] addSessionLog:log];
                            exit(abExitCodeInfoPlistNotFound);
                        } else {
                            [Common showAlertWithTitle:@"AppBox - Error" andMessage:log];
                        }
                        self.errorBlock(nil, YES);
                        return;
                    }
                    
                    //set dropbox folder name & log if user changing folder name or not
                    if (self.project.bundleDirectory.absoluteString.length == 0){
                        [EventTracker logEventWithType:LogEventTypeUploadWithDefaultDBFolderName];
                    }else{
                        [self.project upadteDbDirectoryByBundleDirectory];
                        [EventTracker logEventWithType:LogEventTypeUploadWithCustomBDFolderName];
                    }
                    
                    
                    if (![AppDelegate appDelegate].isInternetConnected){
                        [self showStatus:abNotConnectedToInternet andShowProgressBar:YES withProgress:-1];
                    }
                    
                    //prepare for upload and check ipa type
                    NSURL *ipaFileURL = ([self.project.ipaFullPath isFileURL]) ? self.project.ipaFullPath : [NSURL fileURLWithPath:ipaPath];
                    [self.project setIpaFullPath:ipaFileURL];
                    if (self.project.distributeOverLocalNetwork){
                        [self distributeLocalIPAWithURL:ipaFileURL];
                    } else {
                        [self uploadIPAFileWithoutUnzip:ipaFileURL];
                    }
                });
            }];
        });
    }else{
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"\n\n======\nFile Not Exist - %@\n======\n\n",ipaPath]];
        if (self.ciRepoProject) {
            exit(abExitCodeIPAFileNotFound);
        } else {
            [Common showAlertWithTitle:@"IPA File Missing" andMessage:[NSString stringWithFormat:@"AppBox was not able to find IPA file at %@.",ipaFileURL.absoluteString]];
        }
        self.errorBlock(nil, YES);
    }
}

-(void)distributeLocalIPAWithURL:(NSURL *)ipaURL{
    if(ipaURL){
        //Create IPA file path for server directory
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *ipaName = [[ipaURL URLByDeletingPathExtension] lastPathComponent];
        NSString *appboxServerBuildsPath = [NSString stringWithFormat:@"%@/%@-%@/", abAppBoxLocalServerBuildsDirectory, ipaName, [Common generateUUID]];
        NSURL *toURL = [[UserData buildLocation] URLByAppendingPathComponent:appboxServerBuildsPath];
        NSError *error;
        //Create AppBox Server Directory
        if ([fileManager createDirectoryAtPath:toURL.resourceSpecifier withIntermediateDirectories:YES attributes:nil error:&error]){
            //Copy  IPA file to Server Directory
            NSString *toPath = [NSString stringWithFormat:@"%@/%@.ipa",toURL.resourceSpecifier,ipaName];
            if ([fileManager copyItemAtPath:ipaURL.resourceSpecifier toPath:toPath error:&error]){
                NSString *serverURLString = [self.project.ipaFileLocalShareableURL.absoluteString stringByAppendingFormat:@"/%@%@.ipa", appboxServerBuildsPath, ipaName];
                self.dbFileType = DBFileTypeIPA;
                [self handleSharedURLResult:serverURLString];
            } else if (error) {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"AppBoxServer Copy Error - %@", error]];
            }
        } else if (error) {
            [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"AppBoxServer Copy Error - %@", error]];
        }
    } else {
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"AppBoxServer Copy Error - IPA URL is nil."]];
    }
}

-(void)uploadIPAFileWithoutUnzip:(NSURL *)ipaURL{
    if ([self.project.buildType isEqualToString: BuildTypeAppStore] && self.project.projectFullPath == nil){
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText: @"Please confirm"];
        [alert setInformativeText:@"AppBox found an AppStore provisioning profile in this IPA file. Do you want to upload this on AppStore?"];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert addButtonWithTitle:@"YES! Upload on AppStore."];
        [alert addButtonWithTitle:@"NO! Upload on Dropbox"];
        if ([alert runModal] == NSAlertFirstButtonReturn){
            self.itcLoginBlock();
            return;
        }
    }
    
    [ABLog log:@"IPA Info.plist %@", self.project.ipaInfoPlist];
    
    //upload ipa
    self.dbFileType = DBFileTypeIPA;
    if ([AppDelegate appDelegate].isInternetConnected) {
        [self dbUploadFile:ipaURL.resourceSpecifier.stringByRemovingPercentEncoding to:self.project.dbIPAFullPath.absoluteString mode:[[DBFILESWriteMode alloc] initWithOverwrite]];
    } else {
        self.lastfailedOperation = [NSBlockOperation blockOperationWithBlock:^{
            [self dbUploadFile:ipaURL.resourceSpecifier.stringByRemovingPercentEncoding to:self.project.dbIPAFullPath.absoluteString mode:[[DBFILESWriteMode alloc] initWithOverwrite]];
        }];
    }
    [ABLog log:@"Temporaray Folder %@", NSTemporaryDirectory()];
}


#pragma mark - UNIQUE Link Handlers
-(void)handleAfterUniqueJsonMetaDataLoaded{
    if(self.project.uniqueLinkJsonMetaData){
        NSURL *path = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:FILE_NAME_UNIQUE_JSON]];
        
        //download appinfo.json file
        [[[DBClientsManager authorizedClient].filesRoutes downloadUrl:self.project.uniqueLinkJsonMetaData.pathDisplay overwrite:YES destination:path]
         setResponseBlock:^(DBFILESFileMetadata * _Nullable response, DBFILESDownloadError * _Nullable routeError, DBRequestError * _Nullable error, NSURL * _Nonnull destination) {
             if (response){
                 if([response.name hasSuffix:FILE_NAME_UNIQUE_JSON]){
                     [self updateUniquLinkDictinory:[[self getUniqueJsonDict] mutableCopy]];
                 }
             }
             else if (error){
                 if (self.uploadRecord) {
                     self.errorBlock(error.nsError, NO);
                     [DBErrorHandler handleNetworkErrorWith:error abErrorMessage:@"Unable to fetch app records from Dropbox."];
                 }
                 //create new appinfo.json
                 [self handleAfterUniqueJsonMetaDataLoaded];
             }
         }];
    }else{
        [self updateUniquLinkDictinory:[NSMutableDictionary new]];
    }
}

-(NSDictionary *)getUniqueJsonDict{
    NSError *error;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[NSTemporaryDirectory() stringByAppendingPathComponent:FILE_NAME_UNIQUE_JSON]] options:kNilOptions error:&error];
    [ABLog log:@"%@ : %@",FILE_NAME_UNIQUE_JSON,dictionary];
    return dictionary;
}

-(void)updateUniquLinkDictinory:(NSMutableDictionary *)dictUniqueLink{
    if(![dictUniqueLink isKindOfClass:[NSDictionary class]]){
        dictUniqueLink = [NSMutableDictionary new];
    }
    if (self.uploadRecord) {
        NSMutableArray *versionHistory = [[dictUniqueLink objectForKey:@"versions"] mutableCopy];
        if(versionHistory){
            //remove version from history
            [versionHistory enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([[obj valueForKey:@"manifestLink"] isEqualToString:self.uploadRecord.dbSharedManifestURL]) {
                    [versionHistory removeObject:obj];
                    *stop = YES;
                }
            }];
            
            if (versionHistory.count > 0) {
                //replace latest version with last version, if user removed first version
                NSMutableDictionary *latestVersion = [dictUniqueLink objectForKey:@"latestVersion"];
                if (latestVersion && [[latestVersion valueForKey:@"manifestLink"] isEqualToString:self.uploadRecord.dbSharedManifestURL]){
                    latestVersion = [versionHistory lastObject];
                }
                [dictUniqueLink setObject:versionHistory forKey:@"versions"];
                [dictUniqueLink setObject:latestVersion forKey:@"latestVersion"];
            } else {
                [self deleteBuildRootFolder];
                return;
            }
        }
    } else {
        NSNumber *currentTimeStamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
        NSMutableDictionary *latestVersion = [[NSMutableDictionary alloc] init];
        [latestVersion setObject:self.project.name forKey:@"name"];
        [latestVersion setObject:self.project.version forKey:@"version"];
        [latestVersion setObject:self.project.build forKey:@"build"];
        [latestVersion setObject:self.project.identifer forKey:@"identifier"];
        [latestVersion setObject:self.project.manifestFileSharableURL.absoluteString forKey:@"manifestLink"];
        [latestVersion setObject:currentTimeStamp forKey:@"timestamp"];
        
        //check if developer want to show donwload button IPA file button to the user
        if ([UserData downloadIPAEnable]) {
            [latestVersion setObject:self.project.ipaFileDBShareableURL.absoluteString forKey:@"ipaFileLink"];
        }
        
        //check if developer want to show more information about build
        if ([UserData moreDetailsEnable]) {
            //set basic details of app
            if (self.project.miniOSVersion){
                [latestVersion setObject:self.project.miniOSVersion forKey:@"minosversion"];
            }
            if (self.project.supportedDevice){
                [latestVersion setObject:self.project.supportedDevice forKey:@"supporteddevice"];
            }
            if (self.project.buildType){
                [latestVersion setObject:self.project.buildType forKey:@"buildtype"];
            }
            if (self.project.ipaFileSize) {
                [latestVersion setObject:self.project.ipaFileSize forKey:@"ipafilesize"];
            }
            
            //set details which obtains from mobile provisioing profile
            NSMutableDictionary *mobileProvision = [[NSMutableDictionary alloc] init];
            if (self.project.mobileProvision.createDate) {
                NSNumber *create = [NSNumber numberWithDouble: self.project.mobileProvision.createDate.timeIntervalSince1970];
                [mobileProvision setObject:create forKey:@"createdate"];
            }
            if (self.project.mobileProvision.expirationDate) {
                NSNumber *expire = [NSNumber numberWithDouble: self.project.mobileProvision.expirationDate.timeIntervalSince1970];
                [mobileProvision setObject:expire forKey:@"expirationdata"];
            }
            if (self.project.mobileProvision.teamId) {
                [mobileProvision setObject:self.project.mobileProvision.teamId forKey:@"teamid"];
            }
            if (self.project.mobileProvision.teamName) {
                [mobileProvision setObject:self.project.mobileProvision.teamName forKey:@"teamname"];
            }
            if (self.project.mobileProvision.uuid) {
                [mobileProvision setObject:self.project.mobileProvision.uuid forKey:@"uuid"];
            }
            if (mobileProvision.allKeys.count > 0) {
                [latestVersion setObject:mobileProvision forKey:@"mobileprovision"];
            }
            
            //Hide some information of provisioned deviecs UDIDs
            NSMutableArray *modifiedProvisionedDevices = [[NSMutableArray alloc] init];
            [self.project.mobileProvision.provisionedDevices enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.length > 30) {
                    NSString *modifiedProvisioning = [obj stringByReplacingCharactersInRange:NSMakeRange(10, 20) withString:@"....."];
                    [modifiedProvisionedDevices addObject:modifiedProvisioning];
                }
            }];
            if (self.project.mobileProvision.provisionedDevices) {
                [mobileProvision setObject:modifiedProvisionedDevices forKey:@"devicesudid"];
            }
        }
        
        NSMutableArray *versionHistory = [[dictUniqueLink objectForKey:@"versions"] mutableCopy];
        if ([UserData showPreviousVersions]) {
            if(!versionHistory){
                versionHistory = [NSMutableArray new];
            }
        } else {
            versionHistory = [NSMutableArray new];
        }
        [versionHistory addObject:latestVersion];
        [dictUniqueLink setObject:versionHistory forKey:@"versions"];
        [dictUniqueLink setObject:latestVersion forKey:@"latestVersion"];
    }
    [self writeUniqueJsonWithDict:dictUniqueLink];
    self.project.uniquelinkShareableURL = [NSURL URLWithString:[dictUniqueLink objectForKey:UNIQUE_LINK_SHARED]];
    self.project.appShortShareableURL = [NSURL URLWithString:[dictUniqueLink objectForKey:UNIQUE_LINK_SHORT]];
    [self uploadUniqueLinkJsonFile];
}

-(void)writeUniqueJsonWithDict:(NSDictionary *)jsonDict{
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:FILE_NAME_UNIQUE_JSON];
    if([[NSFileManager defaultManager] fileExistsAtPath:path]){
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&error];
    [jsonData writeToFile:path atomically:YES];
}

-(void)uploadUniqueLinkJsonFile{
    self.dbFileType = DBFileTypeJson;
    NSURL *path = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:FILE_NAME_UNIQUE_JSON]];
    
    //set mode for appinfo.json file to upload/update
    DBFILESWriteMode *mode = (self.project.uniqueLinkJsonMetaData) ? [[DBFILESWriteMode alloc] initWithUpdate:self.project.uniqueLinkJsonMetaData.rev] : [[DBFILESWriteMode alloc] initWithOverwrite];
    [self dbUploadFile:path.resourceSpecifier to:self.project.dbAppInfoJSONFullPath.absoluteString mode:mode];
}

#pragma mark - Update AppInfo.JSON file
-(void)loadAppInfoMetaData{
    DBFILESListRevisionsMode *revisionMode = [[DBFILESListRevisionsMode alloc] initWithPath];
    [[[DBClientsManager authorizedClient].filesRoutes listRevisions:self.project.dbAppInfoJSONFullPath.absoluteString mode:revisionMode limit:@1 ] setResponseBlock:^(DBFILESListRevisionsResult * _Nullable response, DBFILESListRevisionsError * _Nullable routeError, DBRequestError * _Nullable error) {
        //check there is any rev available
        if (response && response.isDeleted.boolValue == NO && response.entries.count > 0){
            [ABLog log:@"Loaded Meta Data %@",response];
            self.project.uniqueLinkJsonMetaData = [response.entries firstObject];
        }
        
        //handle meta data
        [self handleAfterUniqueJsonMetaDataLoaded];
    }];
     
}

#pragma mark - Upload Files

-(void)dbUploadFile:(NSString *)file to:(NSString *)path mode:(DBFILESWriteMode *)mode{
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Uploading - %@", file.lastPathComponent]];
    
    //Upload large ipa file with dropbox session api
    if (_project.ipaFileSize.integerValue > 150 && self.dbFileType == DBFileTypeIPA) {
        [self dbUploadLargeFile:file to:path mode:mode];
        return;
    }
    
    //uploadUrl:path inputUrl:file
    [[[[DBClientsManager authorizedClient].filesRoutes uploadUrl:path mode:mode autorename:@NO clientModified:nil mute:@NO propertyGroups:nil strictConflict:@NO inputUrl:file]
      //Track response with result and error
      setResponseBlock:^(DBFILESFileMetadata * _Nullable response, DBFILESUploadError * _Nullable routeError, DBRequestError * _Nullable error) {
          if (response) {
              //reset retry count
              retryCount = 0;
              
              [ABLog log:@"Uploaded file metadata = %@", response];
              
              //AppInfo.json file uploaded and creating shared url
              if(self.dbFileType == DBFileTypeJson){
                  self.project.uniqueLinkJsonMetaData = response;
                  if(self.project.appShortShareableURL){
                      if (self.uploadRecord) {
                          [self deleteBuildFolder];
                      } else {
                          self.completionBlock();
                      }
                      return;
                  }else{
                      //create shared url for appinfo.json
                      [self dbCreateSharedURLForFile:response.pathDisplay];
                  }
              }
              //IPA file uploaded and creating shared url
              else if (self.dbFileType == DBFileTypeIPA){
                  NSString *status = [NSString stringWithFormat:@"Creating Sharable Link for IPA"];
                  [self showStatus:status andShowProgressBar:YES withProgress:-1];
                  
                  //create shared url for ipa
                  [self dbCreateSharedURLForFile:response.pathDisplay];
              }
              //Manifest file uploaded and creating shared url
              else if (self.dbFileType == DBFileTypeManifest){
                  NSString *status = [NSString stringWithFormat:@"Creating Sharable Link for Manifest"];
                  [self showStatus:status andShowProgressBar:YES withProgress:-1];
                  
                  //create shared url for manifest
                  [self dbCreateSharedURLForFile:response.pathDisplay];
              }
          }
          //unable to upload file, show error
          else {
              NSBlockOperation *retryOperation = [NSBlockOperation blockOperationWithBlock:^{ [self dbUploadFile:file to:path mode:mode]; }];
              [self handleChunkUploadWithLookupError:nil finishError:nil uploadError:nil networkError:error retryBlock:retryOperation];
          }
      }]
     
     //Track and show upload progress
     setProgressBlock:^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
         if (!self.uploadRecord) {
             //Calculate and show progress based on file type
             CGFloat progress = ((totalBytesWritten * 100) / totalBytesExpectedToWrite) ;
             if (self.dbFileType == DBFileTypeIPA) {
                 NSString *status = [NSString stringWithFormat:@"Uploading IPA (%@%%)",[NSNumber numberWithInt:progress]];
                 [self showStatus:status andShowProgressBar:YES withProgress:progress/100];
             }else if (self.dbFileType == DBFileTypeManifest){
                 NSString *status = [NSString stringWithFormat:@"Uploading Manifest (%@%%)",[NSNumber numberWithInt:progress]];
                 [self showStatus:status andShowProgressBar:YES withProgress:progress/100];
             }else if (self.dbFileType == DBFileTypeJson){
                 NSString *status = [NSString stringWithFormat:@"Uploading AppInfo (%@%%)",[NSNumber numberWithInt:progress]];
                 [self showStatus:status andShowProgressBar:YES withProgress:progress/100];
             }
         }
     }];
}

-(void)dbUploadLargeFile:(NSString *)file to:(NSString *)path mode:(DBFILESWriteMode *)mode{
    offset = 0;
    chunkSize = [UserData uploadChunkSize] * abBytesToMB;
    ipaFileData = [NSData dataWithContentsOfFile:file];
    fileHandle = [NSFileHandle fileHandleForReadingAtPath:file];
    nextChunkToUpload = [fileHandle readDataOfLength:chunkSize];
    fileCommitInfo = [[DBFILESCommitInfo alloc] initWithPath:path mode:mode autorename:@NO clientModified:nil mute:@NO propertyGroups:nil strictConflict:@NO];
    
    [[[[DBClientsManager authorizedClient].filesRoutes uploadSessionStartData:nextChunkToUpload] setResponseBlock:^(DBFILESUploadSessionStartResult * _Nullable result, DBFILESUploadSessionStartError * _Nullable routeError, DBRequestError * _Nullable networkError) {
        if (result) {
            sessionId = result.sessionId;
            offset += nextChunkToUpload.length;
            [self uploadNextChunk];
        } else {
            NSBlockOperation *retryOperation = [NSBlockOperation blockOperationWithBlock:^{ [self dbUploadLargeFile:file to:path mode:mode]; }];
            [self handleChunkUploadWithLookupError:nil finishError:nil uploadError:nil networkError:networkError retryBlock:retryOperation];
        }
    }] setProgressBlock:^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        [self updateProgressBytesWritten:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }];
}

-(void)uploadNextChunk{
    nextChunkToUpload = [fileHandle readDataOfLength:chunkSize];
    DBFILESUploadSessionCursor *cursor = [[DBFILESUploadSessionCursor alloc] initWithSessionId:sessionId offset:[NSNumber numberWithUnsignedInteger:offset]];
    if (nextChunkToUpload.length < chunkSize) {
        [[[[DBClientsManager authorizedClient].filesRoutes uploadSessionFinishData:cursor commit:fileCommitInfo inputData:nextChunkToUpload] setResponseBlock:^(DBFILESFileMetadata * _Nullable result, DBFILESUploadSessionFinishError * _Nullable routeError, DBRequestError * _Nullable networkError) {
            if (result) {
                //reset retry count
                retryCount = 0;
                
                if (self.dbFileType == DBFileTypeIPA){
                    NSString *status = [NSString stringWithFormat:@"Creating Sharable Link for IPA"];
                    [self showStatus:status andShowProgressBar:YES withProgress:-1];
                    
                    //create shared url for ipa
                    [self dbCreateSharedURLForFile:result.pathDisplay];
                }
            } else {
                NSBlockOperation *retryOperation = [NSBlockOperation blockOperationWithBlock:^{ [self uploadNextChunk]; }];
                [self handleChunkUploadWithLookupError:nil finishError:routeError uploadError:nil networkError:networkError retryBlock:retryOperation];
            }
        }] setProgressBlock:^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
            [self updateProgressBytesWritten:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
        }];
    } else {
        [[[[DBClientsManager authorizedClient].filesRoutes uploadSessionAppendV2Data:cursor inputData:nextChunkToUpload] setResponseBlock:^(DBNilObject * _Nullable result, DBFILESUploadSessionLookupError * _Nullable routeError, DBRequestError * _Nullable networkError) {
            if (result) {
                offset += nextChunkToUpload.length;
                [self uploadNextChunk];
            } else {
                NSBlockOperation *retryOperation = [NSBlockOperation blockOperationWithBlock:^{ [self uploadNextChunk]; }];
                [self handleChunkUploadWithLookupError:routeError finishError:nil uploadError:nil networkError:networkError retryBlock:retryOperation];
            }
        }] setProgressBlock:^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
            [self updateProgressBytesWritten:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
        }];
    }
}

#pragma mark - Upload File Helper
//Helper to Handle Chunk Upload Error
-(void)handleChunkUploadWithLookupError:(DBFILESUploadSessionLookupError * _Nullable)lookupError
                            finishError:(DBFILESUploadSessionFinishError * _Nullable)finishError
                            uploadError:(DBFILESUploadError * _Nullable)uploadError
                           networkError:(DBRequestError * _Nullable)networkError
                             retryBlock:(NSBlockOperation *)operation{
    //Handle Internet Connection Lost
    if (networkError && networkError.nsError.code == -1009) {
        self.lastfailedOperation = operation;
    }
    
    //Handle DB Client and Server error by Retrying Upto 3 times
    else if (networkError && retryCount < abOnErrorMaxRetryCount && [[AppDelegate appDelegate] isInternetConnected] &&
             (networkError.tag == DBRequestErrorClient || networkError.tag == DBRequestErrorInternalServer)) {
        retryCount++;
        [[AppDelegate appDelegate] addSessionLog: [NSString stringWithFormat:@"Retrying (%ld) IPA Upload due to some error.", (long)retryCount]];
        [operation start];
    }
    
    //Handle other errors
    else {
        retryCount = 0;
        
        //Exit AppBox if CI Project
        if (self.ciRepoProject) {
            exit(abExitCodeForUploadFailed);
        }
        //Call Error Block
        self.errorBlock(nil, YES);
        
        //Handle Route and Network Errors
        if (lookupError) {
            [DBErrorHandler handleUploadSessionLookupError:lookupError];
        } else if (finishError) {
            [DBErrorHandler handleUploadSessionFinishError:finishError];
        } else if (uploadError) {
            [DBErrorHandler handleUploadErrorWith:uploadError];
        } else {
            [DBErrorHandler handleNetworkErrorWith:networkError abErrorMessage:nil];
        }
    }
}

-(void)updateProgressBytesWritten:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    //CGFloat progress = ((totalBytesWritten * 100) / totalBytesExpectedToWrite) ;
    NSUInteger newBytesWritten = offset + totalBytesWritten;
    CGFloat progress = (newBytesWritten * 100 / ipaFileData.length );
    NSString *status = [NSString stringWithFormat:@"Uploading IPA (%@%%)", [NSNumber numberWithInt:progress]];
    [self showStatus:status andShowProgressBar:YES withProgress:progress/100];
}

#pragma mark - Dropbox Create/Get Shared Link
-(void)dbCreateSharedURLForFile:(NSString *)file{
    [[[DBClientsManager authorizedClient].sharingRoutes createSharedLinkWithSettings:file]
     //Track response with result and error
     setResponseBlock:^(DBSHARINGSharedLinkMetadata * _Nullable response, DBSHARINGCreateSharedLinkWithSettingsError * _Nullable routeError, DBRequestError * _Nullable error) {
         if (response){
             [self handleSharedURLResult:response.url];
         }else{
             [self handleSharedURLError:error forFile:file];
         }
     }];
}

-(void)dbGetSharedURLForFile:(NSString *)file{
    [[[DBClientsManager authorizedClient].sharingRoutes listSharedLinks:file cursor:nil directOnly:nil] setResponseBlock:^(DBSHARINGListSharedLinksResult * _Nullable response, DBSHARINGListSharedLinksError * _Nullable routeError, DBRequestError * _Nullable error) {
        if (response && response.links && response.links.count > 0){
            [self handleSharedURLResult:[[response.links firstObject] url]];
        }else{
            [self handleSharedURLError:error forFile:file];
        }
    }];
}

-(void)handleSharedURLError:(DBRequestError *)error forFile:(NSString *)file{
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Create Share Link Error - %@",error]];
    
    //Handle clint side SDK error
    if ([error isClientError]){
        if ([[AppDelegate appDelegate] isInternetConnected]){
            [self dbCreateSharedURLForFile:file];
        }else{
            self.lastfailedOperation = [NSBlockOperation blockOperationWithBlock:^{
                [self dbCreateSharedURLForFile:file];
            }];
        }
    }
    
    //Retry upload if there is any conflict in file upload
    else if([error isHttpError] && error.statusCode.integerValue == 409 && retryCount < abOnErrorMaxRetryCount){
        [self dbGetSharedURLForFile:file];
    }
    
    //Handle DB Client and Server error by Retrying Upto 3 times
    else if (retryCount < abOnErrorMaxRetryCount) {
        retryCount++;
        [self dbCreateSharedURLForFile:file];
        [[AppDelegate appDelegate] addSessionLog: [NSString stringWithFormat:@"Retrying (%ld) Shared URL due to some error.", (long)retryCount]];
    }
    
    //Handle other errors
    else {
        if (self.ciRepoProject) {
            exit(abExitCodeForUploadFailed);
        }
        retryCount = 0;
        [DBErrorHandler handleNetworkErrorWith:error abErrorMessage:@"Unable to create a share URL for the file."];
        self.errorBlock(nil, YES);
    }
}

-(void)handleSharedURLResult:(NSString *)url{
    //Create manifest file with share IPA url and upload manifest file
    if (self.dbFileType == DBFileTypeIPA) {
        NSString *shareableLink = url;
        if(!self.project.distributeOverLocalNetwork){
            shareableLink = [shareableLink stringByReplacingOccurrencesOfString:@"https://www.dropbox.com" withString:abDropBoxDirectDownload];
            shareableLink = [shareableLink stringByReplacingOccurrencesOfString:@"https://dropbox.com" withString:abDropBoxDirectDownload];
            shareableLink = [shareableLink substringToIndex:shareableLink.length-5];
        }
        self.project.ipaFileDBShareableURL = [NSURL URLWithString:shareableLink];
        [self.project createManifestWithIPAURL:self.project.ipaFileDBShareableURL completion:^(NSURL *manifestURL) {
            if (manifestURL == nil){
                //show error if manifest file url is nil
                if (self.ciRepoProject) {
                    exit(abExitCodeUnableToCreateManiFestFile);
                }
                [Common showAlertWithTitle:@"Error" andMessage:@"Unable to create manifest file!!"];
                self.errorBlock(nil, YES);
            }else{
                //change file type and upload manifest
                self.dbFileType = DBFileTypeManifest;
                [self dbUploadFile:manifestURL.resourceSpecifier to:self.project.dbManifestFullPath.absoluteString mode:[[DBFILESWriteMode alloc] initWithOverwrite]];
            }
        }];
        
    }
    //if same link enable load appinfo.json otherwise Create short shareable url of manifest
    else if (self.dbFileType == DBFileTypeManifest){
        NSString *shareableLink = [url substringToIndex:url.length-5];
        [ABLog log:@"Manifest Sharable link - %@",shareableLink];
        self.project.manifestFileSharableURL = [NSURL URLWithString:shareableLink];
        if(self.project.isKeepSameLinkEnabled){
            //Download previously uploaded appinfo
            DBFILESListRevisionsMode *revisionMode = [[DBFILESListRevisionsMode alloc] initWithPath];
            [[[DBClientsManager authorizedClient].filesRoutes listRevisions:self.project.dbAppInfoJSONFullPath.absoluteString mode:revisionMode  limit:@1] setResponseBlock:^(DBFILESListRevisionsResult * _Nullable response, DBFILESListRevisionsError * _Nullable routeError, DBRequestError * _Nullable error) {
                //check there is any rev available
                if (response && response.isDeleted.boolValue == NO && response.entries.count > 0){
                    [ABLog log:@"Loaded Meta Data %@",response];
                    self.project.uniqueLinkJsonMetaData = [response.entries firstObject];
                }
                
                //handle meta data
                [self handleAfterUniqueJsonMetaDataLoaded];
            }];
        }else{
            [self updateUniquLinkDictinory:nil];
        }
    }
    
    //create app info file short sharable url
    else if (self.dbFileType == DBFileTypeJson){
        NSString *shareableLink = [url substringToIndex:url.length-5];
        [ABLog log:@"APPInfo Sharable link - %@",shareableLink];
        self.project.uniquelinkShareableURL = [NSURL URLWithString:shareableLink];
        NSMutableDictionary *dictUniqueFile = [[self getUniqueJsonDict] mutableCopy];
        [dictUniqueFile setObject:shareableLink forKey:UNIQUE_LINK_SHARED];
        [self writeUniqueJsonWithDict:dictUniqueFile];
        if(self.project.appShortShareableURL){
            self.completionBlock();
        }else{
            [self createUniqueShortSharableUrl];
        }
    }
}

#pragma mark - Create ShortSharable URL
-(void)createUniqueShortSharableUrl{
    //Create Short URL
    [[TinyURL shared] shortenURLForProject:self.project.abpProject completion:^(NSURL *shortURL, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                self.project.appLongShareableURL = shortURL;
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Error in creating short URL - %@", error.localizedDescription]];
            }
            [self createAndUploadJsonWithURL:shortURL];
        });
    }];
}

-(void)createAndUploadJsonWithURL:(NSURL *)shareURL{
    self.project.appShortShareableURL = shareURL;
    NSMutableDictionary *dictUniqueFile = [[self getUniqueJsonDict] mutableCopy];
    [dictUniqueFile setObject:shareURL.absoluteString forKey:UNIQUE_LINK_SHORT];
    [self writeUniqueJsonWithDict:dictUniqueFile];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //upload file unique short url
        [self uploadUniqueLinkJsonFile];
    });
}

#pragma mark - Delete Files
-(void)deleteBuildFromDropbox{
    [self showStatus:@"Deleting..." andShowProgressBar:YES withProgress:-1];
    if (self.project.isKeepSameLinkEnabled) {
        [self deleteBuildDetailsFromAppInfoJSON];
    } else {
        [self deleteBuildFolder];
    }
}

-(void)deleteBuildFolder{
    [[[[DBClientsManager authorizedClient] filesRoutes] delete_V2:self.project.dbDirectory.absoluteString] setResponseBlock:^(DBFILESDeleteResult * _Nullable result, DBFILESDeleteError * _Nullable routeError, DBRequestError * _Nullable networkError) {
        [ABHudViewController hideAllHudFromView:self.currentViewController.view after:0];
        if (result) {
            self.completionBlock();
        } else if (routeError) {
            [DBErrorHandler handleDeleteErrorWith:routeError];
        } else if (networkError) {
            [DBErrorHandler handleNetworkErrorWith:networkError abErrorMessage:@"Unable to delete build folder."];
        }
    }];
}

-(void)deleteBuildRootFolder{
    [[[[DBClientsManager authorizedClient] filesRoutes] delete_V2:self.uploadRecord.dbFolderName] setResponseBlock:^(DBFILESDeleteResult * _Nullable result, DBFILESDeleteError * _Nullable routeError, DBRequestError * _Nullable networkError) {
        [ABHudViewController hideAllHudFromView:self.currentViewController.view after:0];
        if (result) {
            self.completionBlock();
        } else if (routeError) {
            [DBErrorHandler handleDeleteErrorWith:routeError];
        } else if (networkError) {
            [DBErrorHandler handleNetworkErrorWith:networkError abErrorMessage:@"Unable to delete file."];
        }
    }];
}

-(void)deleteBuildDetailsFromAppInfoJSON{
    [self loadAppInfoMetaData];
}

#pragma mark - Show Status
-(void)showStatus:(NSString *)status andShowProgressBar:(BOOL)showProgressBar withProgress:(double)progress{
    //log status in session log
    [ABLog log:@"%@",status];
    
    //start/stop/progress based on showProgressBar and progress
    if (progress == -1){
        if (showProgressBar){
            [ABHudViewController showStatus:status onView:self.currentViewController.view];
        }else{
            [ABHudViewController showOnlyStatus:status onView:self.currentViewController.view];
        }
    }else{
        if (showProgressBar){
            [ABHudViewController showStatus:status witProgress:progress onView:self.currentViewController.view];
        }else{
            [ABHudViewController showOnlyStatus:status onView:self.currentViewController.view];
        }
    }
}

@end
