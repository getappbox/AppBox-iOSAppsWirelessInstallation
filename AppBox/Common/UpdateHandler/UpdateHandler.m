//
//  UpdateHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "UpdateHandler.h"

@implementation UpdateHandler

//MARK: - Check for update

+ (void)showUpdateAlertWithUpdateURL:(NSURL *)url{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText: @"New Version Available"];
    [alert setInformativeText:@"A newer version of the \"AppBox\" is available. Do you want to update it? \n\n\n"];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert addButtonWithTitle:@"YES"];
    [alert addButtonWithTitle:@"NO"];
    if ([alert runModal] == NSAlertFirstButtonReturn){
        [[NSWorkspace sharedWorkspace] openURL:url];
        [EventTracker logEventWithType:LogEventTypeUpdateExternalLink];
    }
}

+ (void)showAlreadyUptoDateAlert{
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
    [Common showAlertWithTitle:@"You’re up-to-date!" andMessage:[NSString stringWithFormat:@"AppBox %@ is currently the newest version available.", versionString]];
}

+ (void)isNewVersionAvailableCompletion:(void (^)(bool available, NSURL *url))completion{
    @try {
        [ABLog log:@"Checking for new version..."];
        [NetworkHandler requestWithURL:abGitHubLatestRelease withParameters:nil andRequestType:RequestGET andCompletetion:^(id responseObj, NSInteger httpStatus, NSError *error) {
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
                [ABLog log:@"\n\nCurrent Version - %@ <=> Latest Version - %@\n\n", versionString, tag];
                
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
