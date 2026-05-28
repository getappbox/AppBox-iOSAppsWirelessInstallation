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
	
	//
	NSString *workingDirectory;
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
        fileHandle = nil;
    }
    return self;
}

- (void)dealloc {
    [self closeFileHandle];
    [self cleanupWorkingDirectory];
}

- (void)closeFileHandle {
    if (fileHandle) {
        @try {
            [fileHandle closeFile];
        } @catch (NSException *exception) {
            DDLogError(@"Error closing file handle: %@", exception);
        }
        fileHandle = nil;
    }
}

- (void)cleanupWorkingDirectory {
    if (workingDirectory && [[NSFileManager defaultManager] fileExistsAtPath:workingDirectory]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:workingDirectory error:&error];
        if (error) {
            DDLogWarn(@"Failed to clean temp directory: %@", error.localizedDescription);
        } else {
            DDLogDebug(@"Cleaned up working directory: %@", workingDirectory);
        }
    }
}

- (void)createNewWorkingDirectory {
	workingDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSUUID UUID] UUIDString]];
	NSError *error = nil;
	[[NSFileManager defaultManager] createDirectoryAtPath:workingDirectory withIntermediateDirectories:YES attributes:nil error:&error];
	if (error == nil) {
		DDLogDebug(@"New temporaray working directory %@", workingDirectory);
	} else {
		DDLogInfo(@"Unable to create temporary working directory %@", workingDirectory);
	}
}

//MARK: - UnZip IPA File

-(void)uploadIPAFile:(NSURL *)ipaFileURL{
    DDLogDebug(@"Preparing to Upload IPA - %@", ipaFileURL);
    NSString *ipaPath = [ipaFileURL.resourceSpecifier stringByRemovingPercentEncoding];
	weakify(self);
    if ([[NSFileManager defaultManager] fileExistsAtPath:ipaPath]) {
        DDLogDebug(@"Uploading IPA -  %@", ipaPath);
        //Unzip ipa
        __block NSString *payloadEntry;
        __block NSString *infoPlistPath;
        
		// Create new temp working directory
		[self createNewWorkingDirectory];

		DDLogInfo(@"Extracting IPA file...");
        DDLogDebug(@"Extracting Files to - %@", workingDirectory);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [SSZipArchive unzipFileAtPath:ipaPath
							toDestination:self->workingDirectory
								overwrite:YES
								 password:nil
						  progressHandler:^(NSString * _Nonnull entry, unz_file_info zipInfo, long entryNumber, long total) {
                dispatch_async(dispatch_get_main_queue(), ^{
					strongify(self);
					
                    [self showStatus:@"Extracting files..." andShowProgressBar:YES withProgress:-1];
                    
                    //Get payload entry
                    if (payloadEntry == nil && [entry containsString:@".app"]) {
                        [[entry pathComponents] enumerateObjectsUsingBlock:^(NSString * _Nonnull pathComponent, NSUInteger idx, BOOL * _Nonnull stop) {
                            if ((pathComponent.length > 4) && [[pathComponent substringFromIndex:(pathComponent.length-4)].lowercaseString isEqualToString: @".app"]) {
                                
                                DDLogDebug(@"Found payload at path = %@",entry);
                                payloadEntry = [NSString pathWithComponents:[[entry pathComponents] subarrayWithRange:NSMakeRange(0, idx+1)]];
                                *stop = YES;
                            }
                        }];
                    }
                    
                    //Get Info.plist entry
                    NSString *mainInfoPlistPath = [payloadEntry stringByAppendingPathComponent:@"Info.plist"].lowercaseString;
                    if ([entry.lowercaseString isEqualToString:mainInfoPlistPath]) {
                        DDLogDebug(@"Found Info.plist at path = %@",mainInfoPlistPath);
                        infoPlistPath = entry;
                    }
                    
                    //Get embedded mobile provision
                    if (self.ipaUploadInfo.mobileProvision == nil){
                        NSString *mobileProvisionPath = [payloadEntry stringByAppendingPathComponent:@"embedded.mobileprovision"].lowercaseString;
                        if ([entry.lowercaseString isEqualToString:mobileProvisionPath]){
                            DDLogDebug(@"Found mobileprovision at path = %@",mobileProvisionPath);
							mobileProvisionPath = [self->workingDirectory stringByAppendingPathComponent: mobileProvisionPath];
                            self.ipaUploadInfo.mobileProvision = [[MobileProvision alloc] initWithPath:mobileProvisionPath];
                        }
                    }
                    
                    //show status and log files entry
                    DDLogDebug(@"%@-%@-%@",[NSNumber numberWithLong:entryNumber], [NSNumber numberWithLong:total], entry);
                });
            } completionHandler:^(NSString * _Nonnull path, BOOL succeeded, NSError * _Nonnull error) {
				strongify(self);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        //show error and return
                        if (self.isCLIActive) {
							DDLogInfo(@"Error - %@", error.localizedDescription);
                            [AppDelegate terminateWithExitCode:abExitCodeUnZipIPAError];
                        } else {
                            [Common showAlertWithTitle:@"AppBox - Error" andMessage:error.localizedDescription];
                        }
                        self.errorBlock(nil, YES);
                        return;
                    }
                    
                    //get info.plist
                    DDLogDebug(@"Final Info.plist path = %@",infoPlistPath);
					[self.ipaUploadInfo setIpaInfoPlist: [NSDictionary dictionaryWithContentsOfFile:[self->workingDirectory stringByAppendingPathComponent:infoPlistPath]]];
                    
                    //show error if info.plist is nil or invalid
                    if (![self.ipaUploadInfo isValidInfoPlist]) {
                        if (self.isCLIActive) {
							DDLogInfo(@"AppBox was not able to find Info.plist in your IPA.");
                            [AppDelegate terminateWithExitCode:abExitCodeInfoPlistNotFound];
                        } else {
                            [Common showAlertWithTitle:@"AppBox - Error" andMessage:@"AppBox was not able to find Info.plist in your IPA."];
                        }
                        self.errorBlock(nil, YES);
                        return;
                    }
                    
                    //set dropbox folder name
                    if (!self.ipaUploadInfo.bundleDirectory.absoluteString.isEmpty){
						[self.ipaUploadInfo upadteDbDirectoryByBundleDirectory];
                    }
                    
                    if (![AppDelegate appDelegate].isInternetConnected){
                        [self showStatus:abNotConnectedToInternet andShowProgressBar:YES withProgress:-1];
                    }
                    
                    //prepare for upload and check ipa type
                    NSURL *ipaFileURL = ([self.ipaUploadInfo.ipaFullPath isFileURL]) ? self.ipaUploadInfo.ipaFullPath : [NSURL fileURLWithPath:ipaPath];
                    [self.ipaUploadInfo setIpaFullPath:ipaFileURL];
					[self uploadIPAFileWithoutUnzip:ipaFileURL];
                });
            }];
        });
    }else{
		DDLogInfo(@"\n\n======\nFile Not Exist - %@\n======\n\n",ipaPath);
        if (self.isCLIActive) {
            [AppDelegate terminateWithExitCode:abExitCodeIPAFileNotFound];
        } else {
            [Common showAlertWithTitle:@"IPA File Missing" andMessage:[NSString stringWithFormat:@"AppBox was not able to find IPA file at %@.",ipaFileURL.absoluteString]];
        }
        self.errorBlock(nil, YES);
    }
}

-(void)uploadIPAFileWithoutUnzip:(NSURL *)ipaURL{
	DDLogDebug(@"\n=========\nInfo.plist\n========\n %@", self.ipaUploadInfo.ipaInfoPlist);

    //upload ipa
    self.dbFileType = DBFileTypeIPA;
    if ([AppDelegate appDelegate].isInternetConnected) {
        [self dbUploadFile:ipaURL.resourceSpecifier.stringByRemovingPercentEncoding to:self.ipaUploadInfo.dbIPAFullPath.absoluteString mode:[[DBFILESWriteMode alloc] initWithOverwrite]];
    } else {
        self.lastfailedOperation = [NSBlockOperation blockOperationWithBlock:^{
            [self dbUploadFile:ipaURL.resourceSpecifier.stringByRemovingPercentEncoding to:self.ipaUploadInfo.dbIPAFullPath.absoluteString mode:[[DBFILESWriteMode alloc] initWithOverwrite]];
        }];
    }
}


//MARK: - UNIQUE Link Handlers
-(void)handleAfterUniqueJsonMetaDataLoaded{
    if(self.ipaUploadInfo.uniqueLinkJsonMetaData){
        NSURL *path = [NSURL fileURLWithPath:[workingDirectory stringByAppendingPathComponent:FILE_NAME_UNIQUE_JSON]];
		weakify(self);
        //download appinfo.json file
        [[[DBClientsManager authorizedClient].filesRoutes downloadUrl:self.ipaUploadInfo.uniqueLinkJsonMetaData.pathDisplay overwrite:YES destination:path]
         setResponseBlock:^(DBFILESFileMetadata * _Nullable response, DBFILESDownloadError * _Nullable routeError, DBRequestError * _Nullable error, NSURL * _Nonnull destination) {
			strongify(self);
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
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[workingDirectory stringByAppendingPathComponent:FILE_NAME_UNIQUE_JSON]] options:kNilOptions error:&error];
    if (error) {
		DDLogInfo(@"Error while parsing unique json file - %@", error.localizedDescription);
	}
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
        [latestVersion setObject:self.ipaUploadInfo.name forKey:@"name"];
        [latestVersion setObject:self.ipaUploadInfo.version forKey:@"version"];
        [latestVersion setObject:self.ipaUploadInfo.build forKey:@"build"];
        [latestVersion setObject:self.ipaUploadInfo.identifer forKey:@"identifier"];
        [latestVersion setObject:self.ipaUploadInfo.manifestFileSharableURL.absoluteString forKey:@"manifestLink"];
        [latestVersion setObject:currentTimeStamp forKey:@"timestamp"];
        
        //check if developer want to show donwload button IPA file button to the user
        if ([UserData downloadIPAEnable]) {
            [latestVersion setObject:self.ipaUploadInfo.ipaFileDBShareableURL.absoluteString forKey:@"ipaFileLink"];
        }
        
        //check if developer want to show more information about build
        if ([UserData moreDetailsEnable]) {
            //set basic details of app
            if (self.ipaUploadInfo.miniOSVersion){
                [latestVersion setObject:self.ipaUploadInfo.miniOSVersion forKey:@"minosversion"];
            }
            if (self.ipaUploadInfo.supportedDevice){
                [latestVersion setObject:self.ipaUploadInfo.supportedDevice forKey:@"supporteddevice"];
            }
            if (self.ipaUploadInfo.buildType){
                [latestVersion setObject:self.ipaUploadInfo.buildType forKey:@"buildtype"];
            }
            if (self.ipaUploadInfo.ipaFileSize) {
                [latestVersion setObject:self.ipaUploadInfo.ipaFileSize forKey:@"ipafilesize"];
            }
            
            //set details which obtains from mobile provisioing profile
            NSMutableDictionary *mobileProvision = [[NSMutableDictionary alloc] init];
            if (self.ipaUploadInfo.mobileProvision.createDate) {
                NSNumber *create = [NSNumber numberWithDouble: self.ipaUploadInfo.mobileProvision.createDate.timeIntervalSince1970];
                [mobileProvision setObject:create forKey:@"createdate"];
            }
            if (self.ipaUploadInfo.mobileProvision.expirationDate) {
                NSNumber *expire = [NSNumber numberWithDouble: self.ipaUploadInfo.mobileProvision.expirationDate.timeIntervalSince1970];
                [mobileProvision setObject:expire forKey:@"expirationdata"];
            }
            if (self.ipaUploadInfo.mobileProvision.teamId) {
                [mobileProvision setObject:self.ipaUploadInfo.mobileProvision.teamId forKey:@"teamid"];
            }
            if (self.ipaUploadInfo.mobileProvision.teamName) {
                [mobileProvision setObject:self.ipaUploadInfo.mobileProvision.teamName forKey:@"teamname"];
            }
            if (self.ipaUploadInfo.mobileProvision.uuid) {
                [mobileProvision setObject:self.ipaUploadInfo.mobileProvision.uuid forKey:@"uuid"];
            }
            if (mobileProvision.allKeys.count > 0) {
                [latestVersion setObject:mobileProvision forKey:@"mobileprovision"];
            }
            
            //Hide some information of provisioned deviecs UDIDs
            NSMutableArray *modifiedProvisionedDevices = [[NSMutableArray alloc] init];
            [self.ipaUploadInfo.mobileProvision.provisionedDevices enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.length > 30) {
                    NSString *modifiedProvisioning = [obj stringByReplacingCharactersInRange:NSMakeRange(10, 20) withString:@"....."];
                    [modifiedProvisionedDevices addObject:modifiedProvisioning];
                } else if (obj.length > 20) {
					NSString *modifiedProvisioning = [obj stringByReplacingCharactersInRange:NSMakeRange(8, 5) withString:@"....."];
					[modifiedProvisionedDevices addObject:modifiedProvisioning];
				}
            }];
            if (self.ipaUploadInfo.mobileProvision.provisionedDevices) {
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
    self.ipaUploadInfo.uniquelinkShareableURL = [NSURL URLWithString:[dictUniqueLink objectForKey:UNIQUE_LINK_SHARED]];
    self.ipaUploadInfo.appShortShareableURL = [NSURL URLWithString:[dictUniqueLink objectForKey:UNIQUE_LINK_SHORT]];
    [self uploadUniqueLinkJsonFile];
}

-(void)writeUniqueJsonWithDict:(NSDictionary *)jsonDict{
    NSString *path = [workingDirectory stringByAppendingPathComponent:FILE_NAME_UNIQUE_JSON];
    if([[NSFileManager defaultManager] fileExistsAtPath:path]){
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&error];
    [jsonData writeToFile:path atomically:YES];
}

-(void)uploadUniqueLinkJsonFile{
    self.dbFileType = DBFileTypeJson;
    NSURL *path = [NSURL fileURLWithPath:[workingDirectory stringByAppendingPathComponent:FILE_NAME_UNIQUE_JSON]];
    
    //set mode for appinfo.json file to upload/update
    DBFILESWriteMode *mode = (self.ipaUploadInfo.uniqueLinkJsonMetaData) ? [[DBFILESWriteMode alloc] initWithUpdate:self.ipaUploadInfo.uniqueLinkJsonMetaData.rev] : [[DBFILESWriteMode alloc] initWithOverwrite];
    [self dbUploadFile:path.resourceSpecifier to:self.ipaUploadInfo.dbAppInfoJSONFullPath.absoluteString mode:mode];
}

//MARK: - Update AppInfo.JSON file
-(void)loadAppInfoMetaData{
	weakify(self);
    DBFILESListRevisionsMode *revisionMode = [[DBFILESListRevisionsMode alloc] initWithPath];
    [[[DBClientsManager authorizedClient].filesRoutes listRevisions:self.ipaUploadInfo.dbAppInfoJSONFullPath.absoluteString mode:revisionMode limit:@1 ] setResponseBlock:^(DBFILESListRevisionsResult * _Nullable response, DBFILESListRevisionsError * _Nullable routeError, DBRequestError * _Nullable error) {
		strongify(self);
        //check there is any rev available
        if (response && response.isDeleted.boolValue == NO && response.entries.count > 0){
            DDLogDebug(@"Loaded Meta Data %@",response);
            self.ipaUploadInfo.uniqueLinkJsonMetaData = [response.entries firstObject];
        }
        
        //handle meta data
        [self handleAfterUniqueJsonMetaDataLoaded];
    }];
     
}

//MARK: - Upload Files

-(void)dbUploadFile:(NSString *)file to:(NSString *)path mode:(DBFILESWriteMode *)mode{
	DDLogInfo(@"Uploading - %@", file.lastPathComponent);
    
    //Upload large ipa file with dropbox session api
    if (self.ipaUploadInfo.ipaFileSize.integerValue > 150 && self.dbFileType == DBFileTypeIPA) {
        [self dbUploadLargeFile:file to:path mode:mode];
        return;
    }
    
    //uploadUrl:path inputUrl:file
	weakify(self);
	[[[[DBClientsManager authorizedClient].filesRoutes uploadUrl:path mode:mode autorename:@NO clientModified:nil mute:@NO propertyGroups:nil strictConflict:@NO contentHash:nil inputUrl:file]
      //Track response with result and error
      setResponseBlock:^(DBFILESFileMetadata * _Nullable response, DBFILESUploadError * _Nullable routeError, DBRequestError * _Nullable error) {
		strongify(self);
          if (response) {
              //reset retry count
			  self->retryCount = 0;
              
              //AppInfo.json file uploaded and creating shared url
              if(self.dbFileType == DBFileTypeJson){
                  self.ipaUploadInfo.uniqueLinkJsonMetaData = response;
                  if(self.ipaUploadInfo.appShortShareableURL){
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
              [self handleChunkUploadWithRouteError:nil finishError:nil uploadError:nil networkError:error retryBlock:retryOperation];
          }
      }]
     
     //Track and show upload progress
     setProgressBlock:^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
		strongify(self);
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
    // Close any previously open file handle before opening a new one
    [self closeFileHandle];
    fileHandle = [NSFileHandle fileHandleForReadingAtPath:file];
    nextChunkToUpload = [fileHandle readDataOfLength:chunkSize];
    fileCommitInfo = [[DBFILESCommitInfo alloc] initWithPath:path mode:mode autorename:@NO clientModified:nil mute:@NO propertyGroups:nil strictConflict:@NO];
    
	weakify(self);
    [[[[DBClientsManager authorizedClient].filesRoutes uploadSessionStartData:nextChunkToUpload] setResponseBlock:^(DBFILESUploadSessionStartResult * _Nullable result, DBFILESUploadSessionStartError * _Nullable routeError, DBRequestError * _Nullable networkError) {
		strongify(self);
        if (result) {
			self->sessionId = result.sessionId;
			self->offset += self->nextChunkToUpload.length;
            [self uploadNextChunk];
        } else {
            NSBlockOperation *retryOperation = [NSBlockOperation blockOperationWithBlock:^{ [self dbUploadLargeFile:file to:path mode:mode]; }];
            [self handleChunkUploadWithRouteError:nil finishError:nil uploadError:nil networkError:networkError retryBlock:retryOperation];
        }
    }] setProgressBlock:^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        [self updateProgressBytesWritten:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }];
}

-(void)uploadNextChunk{
    nextChunkToUpload = [fileHandle readDataOfLength:chunkSize];
    DBFILESUploadSessionCursor *cursor = [[DBFILESUploadSessionCursor alloc] initWithSessionId:sessionId offset:[NSNumber numberWithUnsignedInteger:offset]];
	
	weakify(self);
    if (nextChunkToUpload.length < chunkSize) {
        [[[[DBClientsManager authorizedClient].filesRoutes uploadSessionFinishData:cursor commit:fileCommitInfo inputData:nextChunkToUpload] setResponseBlock:^(DBFILESFileMetadata * _Nullable result, DBFILESUploadSessionFinishError * _Nullable routeError, DBRequestError * _Nullable networkError) {
			strongify(self);
            // Close file handle after upload finishes
            [self closeFileHandle];
            if (result) {
                //reset retry count
                self->retryCount = 0;
                
                if (self.dbFileType == DBFileTypeIPA){
                    NSString *status = [NSString stringWithFormat:@"Creating Sharable Link for IPA"];
                    [self showStatus:status andShowProgressBar:YES withProgress:-1];
                    
                    //create shared url for ipa
                    [self dbCreateSharedURLForFile:result.pathDisplay];
                }
            } else {
                NSBlockOperation *retryOperation = [NSBlockOperation blockOperationWithBlock:^{ [self uploadNextChunk]; }];
                [self handleChunkUploadWithRouteError:nil finishError:routeError uploadError:nil networkError:networkError retryBlock:retryOperation];
            }
        }] setProgressBlock:^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
			strongify(self);
            [self updateProgressBytesWritten:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
        }];
    } else {
        [[[[DBClientsManager authorizedClient].filesRoutes uploadSessionAppendV2Data:cursor inputData:nextChunkToUpload] setResponseBlock:^(DBNilObject * _Nullable result, DBFILESUploadSessionAppendError * _Nullable routeError, DBRequestError * _Nullable networkError) {
			strongify(self);
            if (result) {
				self->offset += self->nextChunkToUpload.length;
                [self uploadNextChunk];
            } else {
                NSBlockOperation *retryOperation = [NSBlockOperation blockOperationWithBlock:^{ [self uploadNextChunk]; }];
                [self handleChunkUploadWithRouteError:routeError finishError:nil uploadError:nil networkError:networkError retryBlock:retryOperation];
            }
        }] setProgressBlock:^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
			strongify(self);
            [self updateProgressBytesWritten:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
        }];
    }
}

//MARK: - Upload File Helper
//Helper to Handle Chunk Upload Error
-(void)handleChunkUploadWithRouteError:(DBFILESUploadSessionAppendError * _Nullable)routeError
						   finishError:(DBFILESUploadSessionFinishError * _Nullable)finishError
						   uploadError:(DBFILESUploadError * _Nullable)uploadError
						  networkError:(DBRequestError * _Nullable)networkError
							retryBlock:(NSBlockOperation *)operation {
    BOOL connectivityLost = (networkError != nil && [UploadManager isConnectivityError:networkError.nsError]);

    if (connectivityLost && ![[AppDelegate appDelegate] isInternetConnected]) {
        self.lastfailedOperation = operation;
    }

    else if (networkError && retryCount < abOnErrorMaxRetryCount && [[AppDelegate appDelegate] isInternetConnected] &&
             (connectivityLost || networkError.tag == DBRequestErrorClient || networkError.tag == DBRequestErrorInternalServer)) {
        retryCount++;
		DDLogInfo(@"Retrying (%ld) IPA Upload due to some error.", (long)retryCount);
        [operation start];
    }
    
    //Handle other errors
    else {
        retryCount = 0;
        
        //Exit AppBox if running from CLI
        if (self.isCLIActive) {
            [AppDelegate terminateWithExitCode:abExitCodeForUploadFailed];
        }

        //Call Error Block
        self.errorBlock(nil, YES);
        
        //Handle Route and Network Errors
        if (routeError) {
            [DBErrorHandler handleUploadSessionAppendError:routeError];
        } else if (finishError) {
            [DBErrorHandler handleUploadSessionFinishError:finishError];
        } else if (uploadError) {
            [DBErrorHandler handleUploadErrorWith:uploadError];
        } else {
            [DBErrorHandler handleNetworkErrorWith:networkError abErrorMessage:nil];
        }
    }
}

// NSURLError codes that mean the network path is unavailable, so the upload
// should pause and resume on reconnect rather than be treated as a hard failure.
+ (BOOL)isConnectivityError:(NSError *)error {
    if (error == nil || ![error.domain isEqualToString:NSURLErrorDomain]) {
        return NO;
    }
    switch (error.code) {
        case NSURLErrorNotConnectedToInternet:  // -1009
        case NSURLErrorNetworkConnectionLost:   // -1005
        case NSURLErrorCannotConnectToHost:     // -1004
        case NSURLErrorCannotFindHost:          // -1003
        case NSURLErrorDNSLookupFailed:         // -1006
        case NSURLErrorTimedOut:                // -1001
        case NSURLErrorDataNotAllowed:          // -1020
        case NSURLErrorInternationalRoamingOff: // -1018
            return YES;
        default:
            return NO;
    }
}

-(void)updateProgressBytesWritten:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    //CGFloat progress = ((totalBytesWritten * 100) / totalBytesExpectedToWrite) ;
    NSUInteger newBytesWritten = offset + totalBytesWritten;
    CGFloat progress = (newBytesWritten * 100 / ipaFileData.length );
    NSString *status = [NSString stringWithFormat:@"Uploading IPA (%@%%)", [NSNumber numberWithInt:progress]];
    [self showStatus:status andShowProgressBar:YES withProgress:progress/100];
}

//MARK: - Dropbox Create/Get Shared Link
-(void)dbCreateSharedURLForFile:(NSString *)file{
	weakify(self);
    [[[DBClientsManager authorizedClient].sharingRoutes createSharedLinkWithSettings:file]
     //Track response with result and error
     setResponseBlock:^(DBSHARINGSharedLinkMetadata * _Nullable response, DBSHARINGCreateSharedLinkWithSettingsError * _Nullable routeError, DBRequestError * _Nullable error) {
		strongify(self);
         if (response){
             [self handleSharedURLResult:response.url];
         }else{
             [self handleSharedURLError:error forFile:file];
         }
     }];
}

-(void)dbGetSharedURLForFile:(NSString *)file{
	weakify(self);
    [[[DBClientsManager authorizedClient].sharingRoutes listSharedLinks:file cursor:nil directOnly:nil] setResponseBlock:^(DBSHARINGListSharedLinksResult * _Nullable response, DBSHARINGListSharedLinksError * _Nullable routeError, DBRequestError * _Nullable error) {
		strongify(self);
        if (response && response.links && response.links.count > 0){
            [self handleSharedURLResult:[[response.links firstObject] url]];
        }else{
            [self handleSharedURLError:error forFile:file];
        }
    }];
}

-(void)handleSharedURLError:(DBRequestError *)error forFile:(NSString *)file{
	DDLogInfo(@"Create Share Link Error - %@",error);
    
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
		DDLogInfo(@"Retrying (%ld) Shared URL due to some error.", (long)retryCount);
    }
    
    //Handle other errors
    else {
        if (self.isCLIActive) {
            [AppDelegate terminateWithExitCode:abExitCodeForUploadFailed];
        }
        retryCount = 0;
        [DBErrorHandler handleNetworkErrorWith:error abErrorMessage:@"Unable to create a share URL for the file."];
        self.errorBlock(nil, YES);
    }
}

-(void)handleSharedURLResult:(NSString *)url{
	weakify(self);
	
    //Create manifest file with share IPA url and upload manifest file
    if (self.dbFileType == DBFileTypeIPA) {
        NSString *shareableLink = url;
		shareableLink = [shareableLink substringToIndex:shareableLink.length-5];
        self.ipaUploadInfo.ipaFileDBShareableURL = [NSURL URLWithString:shareableLink];
        [self.ipaUploadInfo createManifestWithIPAURL:self.ipaUploadInfo.ipaFileDBShareableURL completion:^(NSURL *manifestURL) {
			strongify(self);
            if (manifestURL == nil){
                //show error if manifest file url is nil
                if (self.isCLIActive) {
                    [AppDelegate terminateWithExitCode:abExitCodeUnableToCreateManiFestFile];
                }
                [Common showAlertWithTitle:@"Error" andMessage:@"Unable to create manifest file!!"];
                self.errorBlock(nil, YES);
            } else {
                //change file type and upload manifest
                self.dbFileType = DBFileTypeManifest;
                [self dbUploadFile:manifestURL.resourceSpecifier to:self.ipaUploadInfo.dbManifestFullPath.absoluteString mode:[[DBFILESWriteMode alloc] initWithOverwrite]];
            }
        }];
        
    }
    //if same link enable load appinfo.json otherwise Create short shareable url of manifest
    else if (self.dbFileType == DBFileTypeManifest){
        NSString *shareableLink = [url substringToIndex:url.length-5];
        DDLogDebug(@"Manifest Sharable link - %@",shareableLink);
        self.ipaUploadInfo.manifestFileSharableURL = [NSURL URLWithString:shareableLink];
        if(self.ipaUploadInfo.isKeepSameLinkEnabled){
            //Download previously uploaded appinfo
            DBFILESListRevisionsMode *revisionMode = [[DBFILESListRevisionsMode alloc] initWithPath];
            [[[DBClientsManager authorizedClient].filesRoutes listRevisions:self.ipaUploadInfo.dbAppInfoJSONFullPath.absoluteString mode:revisionMode  limit:@1] setResponseBlock:^(DBFILESListRevisionsResult * _Nullable response, DBFILESListRevisionsError * _Nullable routeError, DBRequestError * _Nullable error) {
				strongify(self);
                //check there is any rev available
                if (response && response.isDeleted.boolValue == NO && response.entries.count > 0){
                    DDLogDebug(@"Loaded Meta Data %@",response);
                    self.ipaUploadInfo.uniqueLinkJsonMetaData = [response.entries firstObject];
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
        DDLogDebug(@"AppInfo Sharable link - %@",shareableLink);
        self.ipaUploadInfo.uniquelinkShareableURL = [NSURL URLWithString:shareableLink];
        NSMutableDictionary *dictUniqueLink = [[self getUniqueJsonDict] mutableCopy];
        [dictUniqueLink setObject:shareableLink forKey:UNIQUE_LINK_SHARED];
        [self writeUniqueJsonWithDict:dictUniqueLink];
		DDLogDebug(@"\n=======\nAppInfo\n=======\n %@", dictUniqueLink);
        if(self.ipaUploadInfo.appShortShareableURL){
            self.completionBlock();
        }else{
            [self createUniqueShortSharableUrl];
        }
    }
}

//MARK: - Create ShortSharable URL
-(void)createUniqueShortSharableUrl{
    //Create Short URL
	weakify(self);
    [[TinyURL shared] shortenURLWithIPAUploadInfo:self.ipaUploadInfo.abpIPAUploadInfo completion:^(NSURL *shortURL, NSError *error) {
		strongify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                self.ipaUploadInfo.appLongShareableURL = shortURL;
				DDLogInfo(@"Error in creating short URL - %@", error.localizedDescription);
            }
            [self createAndUploadJsonWithURL:shortURL];
        });
    }];
}

-(void)createAndUploadJsonWithURL:(NSURL *)shareURL{
    self.ipaUploadInfo.appShortShareableURL = shareURL;
    NSMutableDictionary *dictUniqueFile = [[self getUniqueJsonDict] mutableCopy];
    [dictUniqueFile setObject:shareURL.absoluteString forKey:UNIQUE_LINK_SHORT];
    [self writeUniqueJsonWithDict:dictUniqueFile];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //upload file unique short url
        [self uploadUniqueLinkJsonFile];
    });
}

//MARK: - Delete Files
-(void)deleteBuildFromDropboxAndDashboard {
	[self createNewWorkingDirectory];
    [self showStatus:@"Deleting..." andShowProgressBar:YES withProgress:-1];
    if (self.ipaUploadInfo.isKeepSameLinkEnabled) {
        [self deleteBuildDetailsFromAppInfoJSON];
    } else {
        [self deleteBuildFolder];
    }
}

-(void)deleteBuildFromDashboard {
	[self showStatus:@"Deleting..." andShowProgressBar:YES withProgress:-1];
	self.completionBlock();
}

-(void)deleteBuildFolder {
	weakify(self);
    [[[[DBClientsManager authorizedClient] filesRoutes] delete_V2:self.ipaUploadInfo.dbDirectory.absoluteString] setResponseBlock:^(DBFILESDeleteResult * _Nullable result, DBFILESDeleteError * _Nullable routeError, DBRequestError * _Nullable networkError) {
		strongify(self);
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
	weakify(self);
    [[[[DBClientsManager authorizedClient] filesRoutes] delete_V2:self.uploadRecord.dbFolderName] setResponseBlock:^(DBFILESDeleteResult * _Nullable result, DBFILESDeleteError * _Nullable routeError, DBRequestError * _Nullable networkError) {
		strongify(self);
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

//MARK: - Show Status
-(void)showStatus:(NSString *)status andShowProgressBar:(BOOL)showProgressBar withProgress:(double)progress{
    //log status in session log
    DDLogDebug(@"%@",status);
    
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
