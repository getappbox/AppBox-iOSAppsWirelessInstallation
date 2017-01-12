//
//  UpdateHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "UpdateHandler.h"

@implementation UpdateHandler

#pragma mark - Check for update
+ (void)isNewVersionAvailableCompletion:(void (^)(bool available, NSURL *url))completion{
    @try {
        [[AppDelegate appDelegate] addSessionLog:@"Checking for new version..."];
        [NetworkHandler requestWithURL:abGitHubLatestRelease withParameters:nil andRequestType:RequestGET andCompletetion:^(id responseObj, NSError *error) {
            //handle error and check for all required keys
            if (error == nil &&
                [((NSDictionary *)responseObj).allKeys containsObject:@"tag_name"] &&
                [((NSDictionary *)responseObj).allKeys containsObject:@"html_url"]){
                
                //get tag name, because it's always be latest version
                NSString *tag = [responseObj valueForKey:@"tag_name"];
                NSString *newVesion = [[tag componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:abEmptyString];
                
                //get version string from bundle info.plist
                NSString *versionString = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
                NSString *currentVersion = [[versionString componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:abEmptyString];
                
                //log current and latest version
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Current Version - %@ <=> Latest Version - %@", versionString, tag]];
                
                //return result based on version strings
                completion(([newVesion compare:currentVersion] == NSOrderedDescending),[NSURL URLWithString:[responseObj valueForKey:@"html_url"]]);
            }else{
                completion(false, nil);
            }
        }];
    } @catch (NSException *exception) {
        completion(false, nil);
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Exception %@",exception.userInfo]];
    }
}

@end
