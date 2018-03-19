//
//  MSTeamsClient.m
//  AppBox
//
//  Created by Vineet Choudhary on 19/03/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import "MSTeamsClient.h"

@implementation MSTeamsClient

+ (void)sendMessageForProject:(XCProject *)project completion:(void (^) (BOOL success))completion{
    if ([UserData userHangoutChatWebHook].length > 0) {
        //set Hangout Webhook url and image
        NSString *webHookURL = [[UserData userHangoutChatWebHook] stringByRemovingPercentEncoding];
        
        //set slack message
        NSString *hangoutMessage;
        if ([UserData userSlackMessage].length > 0) {
            hangoutMessage = [MailHandler parseMessage:[UserData userSlackMessage] forProject:project];
            hangoutMessage = [hangoutMessage stringByAppendingFormat:@" - %@", project.appShortShareableURL];
        } else {
            hangoutMessage = [NSString stringWithFormat:@"%@ - %@ (%@) link - %@", project.name, project.version, project.build, project.appShortShareableURL];
        }
        
        
        NSDictionary *parameters = @{@"text" : hangoutMessage};
        
        //send message
        [NetworkHandler requestWithURL:webHookURL withParameters:parameters andRequestType:RequestPOST andCompletetion:^(id responseObj, NSError *error) {
            if (responseObj && error == nil) {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Microsoft Team Response - %@", responseObj]];
                completion(YES);
            } else if (error) {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Microsoft Team Error - %@", error.localizedDescription]];
                completion(NO);
            } else {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Microsoft Team Error - Unknown Error"]];
                completion(NO);
            }
        }];
    } else {
        completion(NO);
    }
}

@end
