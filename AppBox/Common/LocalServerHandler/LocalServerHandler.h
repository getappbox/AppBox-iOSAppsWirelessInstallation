//
//  LocalServerHandler.h
//  AppBox
//
//  Created by Vineet Choudhary on 12/08/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SSZipArchive/SSZipArchive.h>

@interface LocalServerHandler : NSObject

@property(nonatomic, strong) NSTask *task;

+(void)setupAppBoxInstallationServices:(void (^)(BOOL isSuccess))completion;
+(void)getLocalIPAddressWithCompletion:(void (^)(NSString *ipAddress))completion;

@end
