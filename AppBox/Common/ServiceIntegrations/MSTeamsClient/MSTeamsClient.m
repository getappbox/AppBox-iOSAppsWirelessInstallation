//
//  MSTeamsClient.m
//  AppBox
//
//  Created by Vineet Choudhary on 19/03/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import "MSTeamsClient.h"

@implementation MSTeamsClient

+ (void)sendMessageForProject:(XCProject *)project
					  webhook:(NSString *)webhook
					  message:(NSString *)message
				   completion:(void (^) (BOOL success))completion{
	//set slack message
	NSString *finalMessage;
	if (message.length > 0) {
		finalMessage = [MailHandler parseMessage:message forProject:project];
	} else {
		finalMessage = [NSString stringWithFormat:@"%@ - %@ (%@) link - %@", project.name, project.version, project.build, project.appShortShareableURL];
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
