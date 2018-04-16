//
//  SlackClient.m
//  AppBox
//
//  Created by Vineet Choudhary on 10/04/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "SlackClient.h"

@implementation SlackClient

+ (void)sendMessageForProject:(XCProject *)project completion:(void (^) (BOOL success))completion {
    if ([UserData userSlackChannel].length > 0) {
        //set slack channel url and image
        NSString *slackImage = abSlackImage;
        NSString *channelURL = [UserData userSlackChannel];
        
        //set slack message
        NSString *slackMessage;
        if ([UserData userSlackMessage].length > 0) {
            slackMessage = [MailHandler parseMessage:[UserData userSlackMessage] forProject:project];
            slackMessage = [slackMessage stringByAppendingFormat:@" - %@", project.appShortShareableURL];
        } else {
            slackMessage = [NSString stringWithFormat:@"%@ - %@ (%@) link - %@", project.name, project.version, project.build, project.appShortShareableURL];
        }
        
        //create parameters dictionary
        NSDictionary *parameters = @{@"username": @"AppBox",
                                     @"icon_url": slackImage,
                                     @"text": slackMessage,};
        
        //send message
        [NetworkHandler requestWithURL:channelURL withParameters:parameters andRequestType:RequestPOST andCompletetion:^(id responseObj, NSInteger httpStatus, NSError *error) {
            if (responseObj && error == nil) {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Slack Response - %@", responseObj]];
                completion(YES);
            } else if (error) {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Slack Error - %@", error.localizedDescription]];
                completion(NO);
            } else {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Slack Error - Unknown Error"]];
                completion(NO);
            }
        }];
    }
}

@end
