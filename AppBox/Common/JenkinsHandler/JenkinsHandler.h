//
//  JenkinsHandler.h
//  AppBox
//
//  Created by Vineet Choudhary on 09/05/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JenkinsHandler : NSObject

+(void)test;
+(BOOL)copyArtifactsInBuildFolderForProject:(XCProject *)project;

@end
