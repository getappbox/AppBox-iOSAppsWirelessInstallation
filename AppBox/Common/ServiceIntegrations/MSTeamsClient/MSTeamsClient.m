//
//  MSTeamsClient.m
//  AppBox
//
//  Created by Vineet Choudhary on 19/03/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import "MSTeamsClient.h"

@implementation MSTeamsClient

+ (void)sendMessage:(IPAUploadInfo *)ipaUploadInfo
			webhook:(NSString *)webhook
			message:(NSString *)message
		 completion:(void (^) (BOOL success))completion{
	// Validate webhook URL
	if (![Common isValidWebhookURL:webhook]) {
		DDLogError(@"MS Teams Error - Invalid webhook URL: %@", webhook);
		completion(NO);
		return;
	}

	//set slack message
	NSString *finalMessage;
	if (message.length > 0) {
		finalMessage = [MailHandler parseMessage:message forIPAUploadInfo:ipaUploadInfo];
	} else {
		finalMessage = [NSString stringWithFormat:@"%@ - %@ (%@) link - %@", ipaUploadInfo.name, ipaUploadInfo.version, ipaUploadInfo.build, ipaUploadInfo.appShortShareableURL];
	}


	NSDictionary *parameters = @{@"text" : finalMessage};

	//send message
	[NetworkHandler requestWithURL:webhook withParameters:parameters andRequestType:RequestPOST andCompletetion:^(id responseObj, NSInteger httpStatus, NSError *error) {
		if (responseObj && error == nil) {
			DDLogInfo(@"Microsoft Team Response - %@", responseObj);
			completion(YES);
		} else if (error) {
			DDLogInfo(@"Microsoft Team Error - %@", error.localizedDescription);
			completion(NO);
		} else {
			DDLogInfo(@"Microsoft Team Error - Unknown Error");
			completion(NO);
		}
	}];
}

@end
