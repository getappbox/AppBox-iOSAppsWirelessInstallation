//
//  SlackClient.m
//  AppBox
//
//  Created by Vineet Choudhary on 10/04/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "SlackClient.h"

@implementation SlackClient

+ (void)sendMessage:(NSString *)message completion:(void (^) (BOOL success))completion {
    NSString *channelURL = @"https://hooks.slack.com/services/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";
    NSString *slackImage = @"https://s3-us-west-2.amazonaws.com/slack-files2/avatars/2017-04-06/165993935268_ec0c0ba40483382c7192_512.png";
    NSDictionary *parameters = @{@"username": @"AppBox",
                                 @"icon_url": slackImage,
                                 @"text": message,};
    [NetworkHandler requestWithURL:channelURL withParameters:parameters andRequestType:RequestPOST andCompletetion:^(id responseObj, NSError *error) {
        if (responseObj && error == nil) {
            completion(YES);
        }else{
            completion(NO);
        }
    }];
}

@end
