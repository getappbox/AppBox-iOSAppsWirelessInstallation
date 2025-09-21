//
//  RepoBuilder.m
//  AppBox
//
//  Created by Vineet Choudhary on 07/04/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "CLIIPAUpload.h"

@implementation CLIIPAUpload{
    
}

//MARK: - IPA
+ (IPAUploadInfo *)ipaUploadInfoWithIPAPath:(NSString *)ipaPath {
    IPAUploadInfo *ipaUploadInfo = [[IPAUploadInfo alloc] initEmpty];
    ipaUploadInfo.ipaFullPath = [NSURL fileURLWithPath:ipaPath];
    [[self class] setCommonArgumentsToIPAUploadInfo:ipaUploadInfo];
    return ipaUploadInfo;
}


//MARK: - Common Arguments
+(void)setCommonArgumentsToIPAUploadInfo:(IPAUploadInfo *)ipaUploadInfo {
    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
	for (NSString *argument in arguments) {

		//Webhook Message
		if ([argument containsString:abArgsWebHookMessage]) {
			NSArray *components = [argument componentsSeparatedByString:abArgsWebHookMessage];
			if (components.count == 2) {
				DDLogInfo(@"Set Webhook message to \"%@\"", [components lastObject]);
				ipaUploadInfo.webhookMessage = [components lastObject];
			} else {
				DDLogInfo(@"Invalid Webhook Message Argument \"%@\"",arguments);
				exit(abExitCodeForInvalidCommand);
			}
		}

		//Slack Webhook
		else if ([argument containsString:abArgsSlackWebHook]) {
			NSArray *components = [argument componentsSeparatedByString:abArgsSlackWebHook];
			if (components.count == 2) {
				DDLogInfo(@"Set Slack Webhook to \"%@\"", [components lastObject]);
				ipaUploadInfo.slackWebhook = [components lastObject];
			} else {
				DDLogInfo(@"Invalid Slack Webhook Argument \"%@\"",arguments);
				exit(abExitCodeForInvalidCommand);
			}
		}

		//MS Teams Webhook
		else if ([argument containsString:abArgsMSTeamsWebHook]) {
			NSArray *components = [argument componentsSeparatedByString:abArgsMSTeamsWebHook];
			if (components.count == 2) {
				DDLogInfo(@"Set MS Teams Webhook to \"%@\"", [components lastObject]);
				ipaUploadInfo.msTeamsWebhook = [components lastObject];
			} else {
				DDLogInfo(@"Invalid MS Teams Webhook Argument \"%@\"",arguments);
				exit(abExitCodeForInvalidCommand);
			}
		}

		//Emails
		else if ([argument containsString:abArgsEmails]) {
			NSArray *components = [argument componentsSeparatedByString:abArgsEmails];
			if (components.count == 2) {
				DDLogInfo(@"Changing Emails to \"%@\" from \"%@\"", [components lastObject], ipaUploadInfo.emails);
				ipaUploadInfo.emails = [components lastObject];
			} else {
				DDLogInfo(@"Invalid Emails Argument \"%@\"",arguments);
				exit(abExitCodeForInvalidCommand);
			}
		}

		//Personal Messages
		else if ([argument containsString:abArgsPersonalMessage]) {
			NSArray *components = [argument componentsSeparatedByString:abArgsPersonalMessage];
			if (components.count == 2) {
				DDLogInfo(@"Changing personal message to \"%@\" from \"%@\"", [components lastObject], ipaUploadInfo.personalMessage);
				ipaUploadInfo.personalMessage = [components lastObject];
			} else {
				DDLogInfo(@"Invalid Personal Message Argument \"%@\"",arguments);
				exit(abExitCodeForInvalidCommand);
			}
		}

		//Keep Same Link
		else if ([argument containsString:abArgsKeepSameLink]) {
			NSArray *components = [argument componentsSeparatedByString:abArgsKeepSameLink];
			if (components.count == 2) {
				DDLogInfo(@"Changing Keep Same Link to \"%@\" from \"%@\"", [components lastObject], ipaUploadInfo.keepSameLink);
				ipaUploadInfo.keepSameLink = ([[components lastObject] isEqualToString:@"0"] || ((BOOL)[[components lastObject] boolValue]) == NO) ? @0 : @1;
			} else {
				DDLogInfo(@"Invalid Keep Same Link Argument \"%@\"",arguments);
				exit(abExitCodeForInvalidCommand);
			}
		}

		//dropbox folder name
		else if ([argument containsString:abArgsDropBoxFolderName]) {
			NSArray *components = [argument componentsSeparatedByString:abArgsDropBoxFolderName];
			if (components.count == 2) {
				DDLogInfo(@"Changing Dropbox folder name to \"%@\" from \"%@\"", [components lastObject], ipaUploadInfo.personalMessage);
				NSString *bundlePath = [NSString stringWithFormat:@"/%@",[components lastObject]];
				bundlePath = [bundlePath stringByReplacingOccurrencesOfString:@" " withString:abEmptyString];
				ipaUploadInfo.bundleDirectory = [NSURL URLWithString:bundlePath];
			} else {
				DDLogInfo(@"Invalid Dropbox Folder Name Argument \"%@\"",arguments);
				exit(abExitCodeForInvalidCommand);
			}
		}

		//Email and Email Subject Prefix
		NSMutableSet *emails = [[NSMutableSet alloc] init];

		if (ipaUploadInfo.emails && ipaUploadInfo.emails.length > 0) {
			[emails addObjectsFromArray:[ipaUploadInfo.emails componentsSeparatedByString:@","]];
		}

		[emails removeObject:@""];
		if (emails.count > 0) {
			ipaUploadInfo.emails = [emails.allObjects componentsJoinedByString:@","];
		}

	}
}

@end

