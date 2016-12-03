//
//  XCProject.h
//  AppBox
//
//  Created by Vineet Choudhary on 03/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XCProject : NSObject

//Project Basic Properties
@property(nonatomic, retain) NSString *uuid;
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *version;
@property(nonatomic, retain) NSString *build;
@property(nonatomic, retain) NSString *identifer;

//Local URLS
@property(nonatomic, retain) NSURL *fullPath;
@property(nonatomic, retain) NSURL *ipaFilePath;
@property(nonatomic, retain) NSURL *dbDirectory;
@property(nonatomic, retain) NSURL *rootDirectory;
@property(nonatomic, retain) NSURL *buildDirectory;
@property(nonatomic, retain) NSURL *buildArchivePath;
@property(nonatomic, retain) NSURL *buildUUIDDirectory;

//Project Schemes and Targets
@property(nonatomic, retain) NSArray *schemes;
@property(nonatomic, retain) NSArray *targets;

//Info.plist, manifest.plist and buildlist information
@property(nonatomic, retain) NSDictionary *ipaInfoPlist;
@property(nonatomic, retain) NSDictionary *manifestData;
@property(nonatomic, retain) NSDictionary *buildListInfo;

//Shareable URL DropBox or Google Shortern
@property(nonatomic, retain) NSURL *ipaFileDBShareableURL;
@property(nonatomic, retain) NSURL *manifestFileSharableURL;
@property(nonatomic, retain) NSURL *appShortShareableURL;

-(void)createUDIDAnsIsNew:(BOOL)isNew;
-(void)createManifestWithIPAURL:(NSURL *)ipaURL completion:(void(^)(NSString *mainfestPath))completion;
@end
