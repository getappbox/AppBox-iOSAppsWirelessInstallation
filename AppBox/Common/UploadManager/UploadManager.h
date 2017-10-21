//
//  UploadManager.h
//  AppBox
//
//  Created by Vineet Choudhary on 20/10/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MobileProvision.h"
#import "UploadRecord+CoreDataClass.h"

typedef void(^ProgressBlock)(NSString *title);
typedef void(^ErrorBlock)(NSError *error, BOOL terminate);
typedef void(^ITCLoginBlock)();
typedef void(^CompletionBlock)();


@interface UploadManager : NSObject{
    
}

@property(nonatomic, strong) XCProject *project;
@property(nonatomic, assign) DBFileType dbFileType;
@property(nonatomic, weak) NSViewController *currentViewController;
@property(nonatomic, weak) UploadRecord *uploadRecord;
@property(nonatomic, strong) NSBlockOperation *lastfailedOperation;

//blocks
@property(nonatomic, strong) ProgressBlock progressBlock;
@property(nonatomic, strong) ErrorBlock errorBlock;
@property(nonatomic, strong) ITCLoginBlock itcLoginBlock;
@property(nonatomic, strong) CompletionBlock completionBlock;


+(void)setupDBClientsManager;
-(void)uploadIPAFile:(NSURL *)ipaFileURL;
-(void)uploadIPAFileWithoutUnzip:(NSURL *)ipaURL;

-(void)deleteBuildFromDropbox;

@end
