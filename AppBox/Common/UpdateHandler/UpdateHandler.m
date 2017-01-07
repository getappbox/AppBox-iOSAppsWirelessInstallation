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
            if (error == nil &&
                [((NSDictionary *)responseObj).allKeys containsObject:@"tag_name"] &&
                [((NSDictionary *)responseObj).allKeys containsObject:@"html_url"]){
                NSString *tag = [responseObj valueForKey:@"tag_name"];
                NSString *newVesion = [[tag componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:abEmptyString];
                NSString *versionString = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
                NSString *currentVersion = [[versionString componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:abEmptyString];
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
