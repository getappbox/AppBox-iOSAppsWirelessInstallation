//
//  XCHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 27/03/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "XCHandler.h"

@implementation XCHandler

+(void)getXCodePathWithCompletion:(void (^) (NSString *xcodePath, NSString *applicationLoaderPath))completion{
    [TaskHandler runTaskWithName:@"XCodePath" andArgument:nil taskLaunch:nil outputStream:^(NSTask *task, NSString *output) {
        NSMutableArray *pathComponents = [[NSMutableArray alloc] initWithArray:[output pathComponents]];
        if (pathComponents.count > 2){
            NSString *xcodePath = [[output stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
            if ([[NSFileManager defaultManager] fileExistsAtPath:xcodePath]){
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"XCode = %@", xcodePath]];
                
                //set xcode location
                [UserData setXCodeLocation:xcodePath];
                NSString *alPath = [[xcodePath stringByAppendingPathComponent:abApplicationLoaderALToolLocation] stringByRemovingPercentEncoding];
                if ([[NSFileManager defaultManager] fileExistsAtPath:alPath]){
                    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Application Loader = %@", alPath]];
                    completion(xcodePath, alPath);
                } else {
                    completion(xcodePath, nil);
                }
            }else{
                completion(nil, nil);
            }
        }
    }];
}

+(void)changeDefaultXcodePath:(NSString *)path withCompletion:(void (^) (BOOL success, NSString *error))completion {
    [TaskHandler runPrivilegeTaskWithName:@"SwitchXcode" andArgument:@[path] outputStream:^(STPrivilegedTask *task, BOOL success, NSString *output) {
        if (success && [output isEqualToString:abEmptyString]) {
            completion(success, nil);
        } else {
            completion(success, output);
        }
    }];
}

+(void)getXcodeVersionWithCompletion:(void (^) (BOOL success, XcodeVersion version, NSString *versionString))completion {
    [TaskHandler runTaskWithName:@"XcodeVersion" andArgument:nil taskLaunch:nil outputStream:^(NSTask *task, NSString *output) {
        if (![output isEqualToString:abEmptyString] && [output.lowercaseString containsString:@"xcode"]){
            NSString *version = [output stringByReplacingOccurrencesOfString:@"Xcode " withString:@""];
            if(version){
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Xcode Version - %@", version]];
                completion(YES, [version integerValue], version);
            } else{
                completion(NO, XcodeVersionNone, nil);
            }
        } else {
            completion(NO, XcodeVersionNone, nil);
        }
    }];
}

@end
