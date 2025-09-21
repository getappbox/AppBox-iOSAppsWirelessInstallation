//
//  ABPIPAUploadInfo.h
//  ABPrivate
//
//  Created by Vineet Choudhary on 25/04/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBManager.h"

@interface ABPIPAUploadInfo : NSObject

//Basic Properties
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *version;
@property(nonatomic, retain) NSString *build;
@property(nonatomic, retain) NSString *identifer;
@property(nonatomic, retain) NSString *teamId;
@property(nonatomic, retain) NSString *buildType;
@property(nonatomic, retain) NSNumber *ipaFileSize;
@property(nonatomic, retain) NSString *miniOSVersion;
@property(nonatomic, retain) NSString *supportedDevice;

//UniqueLink.json
@property(nonatomic, assign) BOOL isKeepSameLinkEnabled;
@property(nonatomic, retain) NSURL *uniquelinkShareableURL;

//Shareable URL DropBox or Google Shortern
@property(nonatomic, retain) NSURL *dbAppInfoJSONFullPath;
@property(nonatomic, retain) NSURL *appShortShareableURL;

//Emails
@property(nonatomic, retain) NSString *emails;
@property(nonatomic, retain) NSString *personalMessage;

//Client
@property(nonatomic, retain) DBManager *dbManager;

@end
