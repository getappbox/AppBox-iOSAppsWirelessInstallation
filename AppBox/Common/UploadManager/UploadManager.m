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
}

+(void)setupDBClientsManager{
    //Force Foreground Session
    if (![DBClientsManager authorizedClient]) {
        DBTransportDefaultConfig *transportConfig = [[DBTransportDefaultConfig alloc] initWithAppKey:abDbAppkey forceForegroundSession:YES];
        [DBClientsManager setupWithTransportConfigDesktop:transportConfig];
    }
    
    //Default Session (Background)
    //    [DBClientsManager setupWithAppKeyDesktop:abDbAppkey];
}

#pragma mark - UnZip IPA File

-(void)uploadIPAFile:(NSURL *)ipaFileURL{
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"\n\n======\n Preparing to Upload IPA - %@\n======\n\n",ipaFileURL]];
    NSString *ipaPath = [ipaFileURL.resourceSpecifier stringByRemovingPercentEncoding];
    if ([[NSFileManager defaultManager] fileExistsAtPath:ipaPath]) {
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"\n\n======\nUploading IPA - %@\n======\n\n",ipaPath]];
        //Unzip ipa
        __block NSString *payloadEntry;
        __block NSString *infoPlistPath;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [SSZipArchive unzipFileAtPath:ipaPath toDestination:NSTemporaryDirectory() overwrite:YES password:nil progressHandler:^(NSString * _Nonnull entry, unz_file_info zipInfo, long entryNumber, long total) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showStatus:@"Extracting files..." andShowProgressBar:YES withProgress:-1];
                    
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
                    
                    //Get embedded mobile provision
                    if (self.project.mobileProvision == nil){
                        NSString *mobileProvisionPath = [NSString stringWithFormat:@"%@embedded.mobileprovision",payloadEntry].lowercaseString;
                        if ([entry.lowercaseString isEqualToString:mobileProvisionPath]){
                            [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Found mobileprovision at path = %@",mobileProvisionPath]];
                            mobileProvisionPath = [NSTemporaryDirectory() stringByAppendingPathComponent: mobileProvisionPath];
                            self.project.mobileProvision = [[MobileProvision alloc] initWithPath:mobileProvisionPath];
                        }
                    }
                    
                    //show status and log files entry
                    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"%@-%@-%@",[NSNumber numberWithLong:entryNumber], [NSNumber numberWithLong:total], entry]];
                });
            } completionHandler:^(NSString * _Nonnull path, BOOL succeeded, NSError * _Nonnull error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        //show error and return
                        [Common showAlertWithTitle:@"AppBox - Error" andMessage:error.localizedDescription];
                        self.errorBlock(nil, YES);
                        return;
                    }
                    
                    //get info.plist
                    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Final Info.plist path = %@",infoPlistPath]];
                    [self.project setIpaInfoPlist: [NSDictionary dictionaryWithContentsOfFile:[NSTemporaryDirectory() stringByAppendingPathComponent:infoPlistPath]]];
                    
                    //show error if info.plist is nil or invalid
                    if (![self.project isValidProjectInfoPlist]) {
                        [Common showAlertWithTitle:@"AppBox - Error" andMessage:@"AppBox can't able to find Info.plist in you IPA."];
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
                    
                    
                    if ([AppDelegate appDelegate].isInternetConnected){
                        [self showStatus:@"Ready to upload..." andShowProgressBar:NO withProgress:-1];
                    }else{
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
        [Common showAlertWithTitle:@"IPA File Missing" andMessage:[NSString stringWithFormat:@"AppBox can't able to find ipa file at %@.",ipaFileURL.absoluteString]];
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
    if ([self.project.buildType isEqualToString: BuildTypeAppStore] && self.project.fullPath == nil){
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
    
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"\n\n======\nIPA Info.plist\n======\n\n - %@",self.project.ipaInfoPlist]];
    
    //upload ipa
    self.dbFileType = DBFileTypeIPA;
    if ([AppDelegate appDelegate].isInternetConnected) {
        [self dbUploadFile:ipaURL.resourceSpecifier.stringByRemovingPercentEncoding to:self.project.dbIPAFullPath.absoluteString mode:[[DBFILESWriteMode alloc] initWithOverwrite]];
    } else {
        self.lastfailedOperation = [NSBlockOperation blockOperationWithBlock:^{
            [self dbUploadFile:ipaURL.resourceSpecifier.stringByRemovingPercentEncoding to:self.project.dbIPAFullPath.absoluteString mode:[[DBFILESWriteMode alloc] initWithOverwrite]];
        }];
    }
    
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Temporaray folder %@",NSTemporaryDirectory()]];
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
                     [DBErrorHandler handleNetworkErrorWith:error];
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
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"%@ : %@",FILE_NAME_UNIQUE_JSON,dictionary]];
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
        NSDictionary *latestVersion = @{
                                        @"name" : self.project.name,
                                        @"version" : self.project.version,
                                        @"build" : self.project.build,
                                        @"identifier" : self.project.identifer,
                                        @"manifestLink" : self.project.manifestFileSharableURL.absoluteString,
                                        @"timestamp" : [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]
                                        };
        NSMutableArray *versionHistory = [[dictUniqueLink objectForKey:@"versions"] mutableCopy];
        if(!versionHistory){
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
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:nil];
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
            [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Loaded Meta Data %@",response]];
            self.project.uniqueLinkJsonMetaData = [response.entries firstObject];
        }
        
        //handle meta data
        [self handleAfterUniqueJsonMetaDataLoaded];
    }];
     
}

#pragma mark - Upload Files
-(void)dbUploadLargeFile:(NSString *)file to:(NSString *)path mode:(DBFILESWriteMode *)mode{
    offset = 0;
    chunkSize = 1 * 1024 * 1024;
    ipaFileData = [NSData dataWithContentsOfFile:file];
    fileHandle = [NSFileHandle fileHandleForReadingAtPath:file];
    nextChunkToUpload = [fileHandle readDataOfLength:chunkSize];
    fileCommitInfo = [[DBFILESCommitInfo alloc] initWithPath:path mode:mode autorename:@NO clientModified:nil mute:@NO];
    
    [[[[DBClientsManager authorizedClient].filesRoutes uploadSessionStartData:nextChunkToUpload] setResponseBlock:^(DBFILESUploadSessionStartResult * _Nullable result, DBNilObject * _Nullable routeError, DBRequestError * _Nullable networkError) {
        if (result) {
            sessionId = result.sessionId;
            offset += nextChunkToUpload.length;
            [self uploadNextChunk];
        } else if (networkError .nsError.code == -1009) {
            self.lastfailedOperation = [NSBlockOperation blockOperationWithBlock:^{
                [self dbUploadLargeFile:file to:path mode:mode];
            }];
        } else if (networkError) {
            [DBErrorHandler handleNetworkErrorWith:networkError];
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
                if (self.dbFileType == DBFileTypeIPA){
                    [Common showLocalNotificationWithTitle:@"AppBox" andMessage:@"IPA file uploaded."];
                    NSString *status = [NSString stringWithFormat:@"Creating Sharable Link for IPA"];
                    [self showStatus:status andShowProgressBar:YES withProgress:-1];
                    
                    //create shared url for ipa
                    [self dbCreateSharedURLForFile:result.pathDisplay];
                }
            } else if (networkError.nsError.code == -1009) {
                self.lastfailedOperation = [NSBlockOperation blockOperationWithBlock:^{
                    [self uploadNextChunk];
                }];
            } else if (routeError) {
                [DBErrorHandler handleUploadSessionFinishError:routeError];
            } else {
                [DBErrorHandler handleNetworkErrorWith:networkError];
            }
        }] setProgressBlock:^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
            [self updateProgressBytesWritten:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
        }];
    } else {
        [[[[DBClientsManager authorizedClient].filesRoutes uploadSessionAppendV2Data:cursor inputData:nextChunkToUpload] setResponseBlock:^(DBNilObject * _Nullable result, DBFILESUploadSessionLookupError * _Nullable routeError, DBRequestError * _Nullable networkError) {
            if (result) {
                offset += nextChunkToUpload.length;
                [self uploadNextChunk];
            } else if (networkError.nsError.code == -1009) {
                self.lastfailedOperation = [NSBlockOperation blockOperationWithBlock:^{
                    [self uploadNextChunk];
                }];
            }else if (routeError) {
                [DBErrorHandler handleUploadSessionLookupError:routeError];
            } else {
                [DBErrorHandler handleNetworkErrorWith:networkError];
            }
        }] setProgressBlock:^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
            [self updateProgressBytesWritten:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
        }];
    }
}

-(void)updateProgressBytesWritten:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    //CGFloat progress = ((totalBytesWritten * 100) / totalBytesExpectedToWrite) ;
    NSUInteger newBytesWritten = offset + totalBytesWritten;
    CGFloat progress = (newBytesWritten * 100 / ipaFileData.length );
    NSString *status = [NSString stringWithFormat:@"Uploading IPA (%@%%)", [NSNumber numberWithInt:progress]];
    [self showStatus:status andShowProgressBar:YES withProgress:progress/100];
}


-(void)dbUploadFile:(NSString *)file to:(NSString *)path mode:(DBFILESWriteMode *)mode{
    //Upload large ipa file with dropbox session api
    if (self.dbFileType == DBFileTypeIPA) {
        [self dbUploadLargeFile:file to:path mode:mode];
        return;
    }
    
    //uploadUrl:path inputUrl:file
    [[[[DBClientsManager authorizedClient].filesRoutes uploadUrl:path mode:mode autorename:@NO clientModified:nil mute:@NO inputUrl:file]
      //Track response with result and error
      setResponseBlock:^(DBFILESFileMetadata * _Nullable response, DBFILESUploadError * _Nullable routeError, DBRequestError * _Nullable error) {
          if (response) {
              [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Uploaded file metadata = %@", response]];
              
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
                  [Common showLocalNotificationWithTitle:@"AppBox" andMessage:@"IPA file uploaded."];
                  NSString *status = [NSString stringWithFormat:@"Creating Sharable Link for IPA"];
                  [self showStatus:status andShowProgressBar:YES withProgress:-1];
                  
                  //create shared url for ipa
                  [self dbCreateSharedURLForFile:response.pathDisplay];
              }
              //Manifest file uploaded and creating shared url
              else if (self.dbFileType == DBFileTypeManifest){
                  [Common showLocalNotificationWithTitle:@"AppBox" andMessage:@"Manifest file uploaded."];
                  NSString *status = [NSString stringWithFormat:@"Creating Sharable Link for Manifest"];
                  [self showStatus:status andShowProgressBar:YES withProgress:-1];
                  
                  //create shared url for manifest
                  [self dbCreateSharedURLForFile:response.pathDisplay];
              }
          }
          //unable to upload file, show error
          else {
              //The Internet connection appears to be offline
              if (error.nsError.code == -1009) {
                  self.lastfailedOperation = [NSBlockOperation blockOperationWithBlock:^{
                      [self dbUploadFile:file to:path mode:mode];
                  }];
              } else {
                  [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Upload DB Error - %@ \n Route Error - %@",error, routeError]];
                  self.errorBlock(nil, YES);
                  if (error) {
                      [DBErrorHandler handleNetworkErrorWith:error];
                  } else if (routeError) {
                      [DBErrorHandler handleUploadErrorWith:routeError];
                  }
              }
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
    if ([error isClientError]){
        if ([[AppDelegate appDelegate] isInternetConnected]){
            [self dbCreateSharedURLForFile:file];
        }else{
            self.lastfailedOperation = [NSBlockOperation blockOperationWithBlock:^{
                [self dbCreateSharedURLForFile:file];
            }];
        }
    }else if([error isHttpError] && error.statusCode.integerValue == 409){
        [self dbGetSharedURLForFile:file];
    }else{
        [DBErrorHandler handleNetworkErrorWith:error];
        self.errorBlock(nil, YES);
    }
}

-(void)handleSharedURLResult:(NSString *)url{
    //Create manifest file with share IPA url and upload manifest file
    if (self.dbFileType == DBFileTypeIPA) {
        NSString *shareableLink = url;
        if(!self.project.distributeOverLocalNetwork){
            shareableLink = [url stringByReplacingCharactersInRange:NSMakeRange(url.length-1, 1) withString:@"1"];
        }
        self.project.ipaFileDBShareableURL = [NSURL URLWithString:shareableLink];
        [self.project createManifestWithIPAURL:self.project.ipaFileDBShareableURL completion:^(NSURL *manifestURL) {
            if (manifestURL == nil){
                //show error if manifest file url is nil
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
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Manifest Sharable link - %@",shareableLink]];
        self.project.manifestFileSharableURL = [NSURL URLWithString:shareableLink];
        if(self.project.isKeepSameLinkEnabled){
            //Download previously uploaded appinfo
            DBFILESListRevisionsMode *revisionMode = [[DBFILESListRevisionsMode alloc] initWithPath];
            [[[DBClientsManager authorizedClient].filesRoutes listRevisions:self.project.dbAppInfoJSONFullPath.absoluteString mode:revisionMode  limit:@1] setResponseBlock:^(DBFILESListRevisionsResult * _Nullable response, DBFILESListRevisionsError * _Nullable routeError, DBRequestError * _Nullable error) {
                //check there is any rev available
                if (response && response.isDeleted.boolValue == NO && response.entries.count > 0){
                    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Loaded Meta Data %@",response]];
                    self.project.uniqueLinkJsonMetaData = [response.entries firstObject];
                }
                
                //handle meta data
                [self handleAfterUniqueJsonMetaDataLoaded];
            }];
        }else{
            //[self createManifestShortSharableUrl];
            [self updateUniquLinkDictinory:nil];
        }
    }
    
    //create app info file short sharable url
    else if (self.dbFileType == DBFileTypeJson){
        NSString *shareableLink = [url substringToIndex:url.length-5];
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"APPInfo Sharable link - %@",shareableLink]];
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
    //Build URL
    NSString *originalURL = [self.project.uniquelinkShareableURL.absoluteString componentsSeparatedByString:@"dropbox.com"][1];
    self.project.appLongShareableURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?url=%@", abInstallWebAppBaseURL, originalURL]];
    
    //Create Short URL
    GooglURLShortenerService *service = [GooglURLShortenerService serviceWithAPIKey: abGoogleTiny];
    [Tiny shortenURL:self.project.appLongShareableURL withService:service completion:^(NSURL *shortURL, NSError *error) {
        //Retry to create short URL if first try failed
        if (shortURL == nil || error) {
            [Tiny shortenURL:self.project.appLongShareableURL withService:service completion:^(NSURL *shortURL, NSError *error) {
                if (shortURL == nil || error) {
                    [self createAndUploadJsonWithURL:self.project.appLongShareableURL];
                } else {
                    [self createAndUploadJsonWithURL:shortURL];
                }
            }];
        } else {
            [self createAndUploadJsonWithURL:shortURL];
        }
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

-(void)createManifestShortSharableUrl{
    NSString *originalURL = [self.project.manifestFileSharableURL.absoluteString componentsSeparatedByString:@"dropbox.com"][1];
    //create short url
    self.project.appLongShareableURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?url=%@", abInstallWebAppBaseURL,originalURL]];
    GooglURLShortenerService *service = [GooglURLShortenerService serviceWithAPIKey: abGoogleTiny];
    [Tiny shortenURL:self.project.appLongShareableURL withService:service completion:^(NSURL *shortURL, NSError *error) {
        self.project.appShortShareableURL = shortURL;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completionBlock();
        });
    }];
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
    [[[[DBClientsManager authorizedClient] filesRoutes] deleteV2:self.project.dbDirectory.absoluteString] setResponseBlock:^(DBFILESDeleteResult * _Nullable result, DBFILESDeleteError * _Nullable routeError, DBRequestError * _Nullable networkError) {
        [ABHudViewController hideAllHudFromView:self.currentViewController.view after:0];
        if (result) {
            self.completionBlock();
        } else if (routeError) {
            [DBErrorHandler handleDeleteErrorWith:routeError];
        } else if (networkError) {
            [DBErrorHandler handleNetworkErrorWith:networkError];
        }
    }];
}

-(void)deleteBuildRootFolder{
    [[[[DBClientsManager authorizedClient] filesRoutes] deleteV2:self.uploadRecord.dbFolderName] setResponseBlock:^(DBFILESDeleteResult * _Nullable result, DBFILESDeleteError * _Nullable routeError, DBRequestError * _Nullable networkError) {
        [ABHudViewController hideAllHudFromView:self.currentViewController.view after:0];
        if (result) {
            self.completionBlock();
        } else if (routeError) {
            [DBErrorHandler handleDeleteErrorWith:routeError];
        } else if (networkError) {
            [DBErrorHandler handleNetworkErrorWith:networkError];
        }
    }];
}

-(void)deleteBuildDetailsFromAppInfoJSON{
    [self loadAppInfoMetaData];
}

#pragma mark - Show Status
-(void)showStatus:(NSString *)status andShowProgressBar:(BOOL)showProgressBar withProgress:(double)progress{
    //log status in session log
    [[AppDelegate appDelegate]addSessionLog:[NSString stringWithFormat:@"%@",status]];
    
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
