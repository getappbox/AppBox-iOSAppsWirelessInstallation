//
//  HangoutClient.m
//  AppBox
//
//  Created by Vineet Choudhary on 19/03/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import "HangoutClient.h"

@implementation HangoutClient

+ (void)sendMessageForProject:(XCProject *)project completion:(void (^) (BOOL success))completion{
    if ([UserData userHangoutChatWebHook].length > 0) {
        //set Hangout Webhook url and image
        NSString *webHookURL = [[UserData userHangoutChatWebHook] stringByRemovingPercentEncoding];
        
        //set slack message
        NSString *hangoutMessage;
        if ([UserData userSlackMessage].length > 0) {
            hangoutMessage = [MailHandler parseMessage:[UserData userSlackMessage] forProject:project];
        } else {
            hangoutMessage = [NSString stringWithFormat:@"%@ - %@ (%@) link - %@", project.name, project.version, project.build, project.appShortShareableURL];
        }

        
        NSDictionary *parameters = @{@"text" : hangoutMessage};
        
        //send message
        [NetworkHandler requestWithURL:webHookURL withParameters:parameters andRequestType:RequestPOST andCompletetion:^(id responseObj, NSInteger httpStatus, NSError *error) {
            if (responseObj && error == nil) {
				[ABLog logImp:@"Hangout  Response - %@", responseObj];
                completion(YES);
            } else if (error) {
				[ABLog logImp:@"Hangout Chat Error - %@", error.localizedDescription];
                completion(NO);
            } else {
				[ABLog logImp:@"Hangout Chat Error - Unknown Error"];
                completion(NO);
            }
        }];
    } else {
        completion(NO);
    }
}

+(NSDictionary *)parametersForProject:(XCProject *)project {
    //KeyValue Dict
    NSMutableDictionary *keyValues = [[NSMutableDictionary alloc] init];
    [keyValues setObject:project.name forKey:@"topLabel"];
    [keyValues setObject:[NSString stringWithFormat:@"%@ (%@)", project.version, project.build] forKey:@"content"];
    [keyValues setObject:@"false" forKey:@"contentMultiline"];
    NSDictionary *cardAction = @{@"openLink" : @{ @"url" : project.appShortShareableURL.stringValue }};
    [keyValues setObject:cardAction forKey:@"onClick"];
    [keyValues setObject:@"DESCRIPTION" forKey:@"icon"];
    
    //Download Button
    NSMutableDictionary *downloadButton = [[NSMutableDictionary alloc] init];
    [downloadButton setObject:@"Install Application" forKey:@"text"];
    NSDictionary *downloadButtonAction = @{@"openLink" : @{ @"url" : project.appShortShareableURL.stringValue }};
    [downloadButton setObject:downloadButtonAction forKey:@"onClick"];
    [keyValues setObject:@{@"textButton": downloadButton} forKey:@"button"];
    
    NSDictionary *keyValueDict = @{@"keyValue" : keyValues};
    NSDictionary *widgets = @{@"widgets" : @[keyValueDict]};
    NSDictionary *sections = @{@"sections" : @[widgets]};
    NSDictionary *cards = @{@"cards" : @[sections]};
    
    return cards;
}

@end
