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
				DDLogInfo(@"Webhook message configured.");
				ipaUploadInfo.webhookMessage = [components lastObject];
			} else {
				DDLogInfo(@"Invalid Webhook Message Argument.");
				exit(abExitCodeForInvalidCommand);
			}
		}

		//Slack Webhook
		else if ([argument containsString:abArgsSlackWebHook]) {
			NSArray *components = [argument componentsSeparatedByString:abArgsSlackWebHook];
			if (components.count == 2) {
				DDLogInfo(@"Slack webhook configured.");
				ipaUploadInfo.slackWebhook = [components lastObject];
			} else {
				DDLogInfo(@"Invalid Slack Webhook Argument.");
				exit(abExitCodeForInvalidCommand);
			}
		}

		//MS Teams Webhook
		else if ([argument containsString:abArgsMSTeamsWebHook]) {
			NSArray *components = [argument componentsSeparatedByString:abArgsMSTeamsWebHook];
			if (components.count == 2) {
				DDLogInfo(@"MS Teams webhook configured.");
				ipaUploadInfo.msTeamsWebhook = [components lastObject];
			} else {
				DDLogInfo(@"Invalid MS Teams Webhook Argument.");
				exit(abExitCodeForInvalidCommand);
			}
		}

		//Emails
		else if ([argument containsString:abArgsEmails]) {
			NSArray *components = [argument componentsSeparatedByString:abArgsEmails];
			if (components.count == 2) {
				DDLogInfo(@"Email recipients configured.");
				ipaUploadInfo.emails = [components lastObject];
			} else {
				DDLogInfo(@"Invalid Emails Argument.");
				exit(abExitCodeForInvalidCommand);
			}
		}

		//Personal Messages
		else if ([argument containsString:abArgsPersonalMessage]) {
			NSArray *components = [argument componentsSeparatedByString:abArgsPersonalMessage];
			if (components.count == 2) {
				DDLogInfo(@"Personal message configured.");
				ipaUploadInfo.personalMessage = [components lastObject];
			} else {
				DDLogInfo(@"Invalid Personal Message Argument.");
				exit(abExitCodeForInvalidCommand);
			}
		}

		//Keep Same Link
		else if ([argument containsString:abArgsKeepSameLink]) {
			NSArray *components = [argument componentsSeparatedByString:abArgsKeepSameLink];
			if (components.count == 2) {
				DDLogInfo(@"Keep Same Link set to \"%@\".", [components lastObject]);
				ipaUploadInfo.keepSameLink = ([[components lastObject] isEqualToString:@"0"] || ((BOOL)[[components lastObject] boolValue]) == NO) ? @0 : @1;
			} else {
				DDLogInfo(@"Invalid Keep Same Link Argument.");
				exit(abExitCodeForInvalidCommand);
			}
		}

		//dropbox folder name
		else if ([argument containsString:abArgsDropBoxFolderName]) {
			NSArray *components = [argument componentsSeparatedByString:abArgsDropBoxFolderName];
			if (components.count == 2) {
				DDLogInfo(@"Dropbox folder name configured.");
				NSString *bundlePath = [NSString stringWithFormat:@"/%@",[components lastObject]];
				bundlePath = [bundlePath stringByReplacingOccurrencesOfString:@" " withString:abEmptyString];
				ipaUploadInfo.bundleDirectory = [NSURL URLWithString:bundlePath];
			} else {
				DDLogInfo(@"Invalid Dropbox Folder Name Argument.");
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

