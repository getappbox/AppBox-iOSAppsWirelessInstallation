//
//  SlackClient.m
//  AppBox
//
//  Created by Vineet Choudhary on 10/04/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "SlackClient.h"

@implementation SlackClient

+ (void)sendMessage:(IPAUploadInfo *)ipaUploadInfo
			webhook:(NSString *)webhook
			message:(NSString *)message
		 completion:(void (^) (BOOL success))completion {
	// Validate webhook URL
	if (![Common isValidWebhookURL:webhook]) {
		DDLogError(@"Slack Error - Invalid webhook URL: %@", webhook);
		completion(NO);
		return;
	}

	//set slack channel url and image
	NSString *slackImage = abSlackImage;

	//set slack message
	NSString *finalMessage;
	if (message.length > 0) {
		finalMessage = [MailHandler parseMessage:message forIPAUploadInfo:ipaUploadInfo];
	} else {
		finalMessage = [NSString stringWithFormat:@"%@ - %@ (%@) link - %@", ipaUploadInfo.name, ipaUploadInfo.version, ipaUploadInfo.build, ipaUploadInfo.appShortShareableURL];
	}

	//create parameters dictionary
	NSDictionary *parameters = @{
		@"username": @"AppBox",
		@"icon_url": slackImage,
		@"text": finalMessage
	};

	//send message
	[NetworkHandler requestWithURL:webhook withParameters:parameters andRequestType:RequestPOST andCompletetion:^(id responseObj, NSInteger httpStatus, NSError *error) {
		if (responseObj && error == nil) {
			DDLogInfo(@"Slack Response - %@", responseObj);
			completion(YES);
		} else if (error) {
			DDLogInfo(@"Slack Error - %@", error.localizedDescription);
			completion(NO);
		} else {
			DDLogInfo(@"Slack Error - Unknown Error");
			completion(NO);
		}
	}];
}

@end
