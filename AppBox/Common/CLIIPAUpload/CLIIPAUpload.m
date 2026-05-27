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
				[AppDelegate terminateWithExitCode:abExitCodeForInvalidCommand];
			}
		}

		//Slack Webhook
		else if ([argument containsString:abArgsSlackWebHook]) {
			NSArray *components = [argument componentsSeparatedByString:abArgsSlackWebHook];
			if (components.count == 2) {
				NSString *webhookURL = [components lastObject];
				if (![Common isValidWebhookURL:webhookURL]) {
					DDLogError(@"Invalid Slack Webhook URL format. Must be a valid HTTP/HTTPS URL.");
					[AppDelegate terminateWithExitCode:abExitCodeForInvalidCommand];
				}
				DDLogInfo(@"Slack webhook configured.");
				ipaUploadInfo.slackWebhook = webhookURL;
			} else {
				DDLogInfo(@"Invalid Slack Webhook Argument.");
				[AppDelegate terminateWithExitCode:abExitCodeForInvalidCommand];
			}
		}

		//MS Teams Webhook
		else if ([argument containsString:abArgsMSTeamsWebHook]) {
			NSArray *components = [argument componentsSeparatedByString:abArgsMSTeamsWebHook];
			if (components.count == 2) {
				NSString *webhookURL = [components lastObject];
				if (![Common isValidWebhookURL:webhookURL]) {
					DDLogError(@"Invalid MS Teams Webhook URL format. Must be a valid HTTP/HTTPS URL.");
					[AppDelegate terminateWithExitCode:abExitCodeForInvalidCommand];
				}
				DDLogInfo(@"MS Teams webhook configured.");
				ipaUploadInfo.msTeamsWebhook = webhookURL;
			} else {
				DDLogInfo(@"Invalid MS Teams Webhook Argument.");
				[AppDelegate terminateWithExitCode:abExitCodeForInvalidCommand];
			}
		}

		//Emails
		else if ([argument containsString:abArgsEmails]) {
			NSArray *components = [argument componentsSeparatedByString:abArgsEmails];
			if (components.count == 2) {
				NSString *emailList = [components lastObject];
				if (![MailHandler isAllValidEmail:emailList]) {
					DDLogError(@"Invalid email format. Provide comma-separated valid email addresses.");
					[AppDelegate terminateWithExitCode:abExitCodeForInvalidCommand];
				}
				DDLogInfo(@"Email recipients configured.");
				ipaUploadInfo.emails = emailList;
			} else {
				DDLogInfo(@"Invalid Emails Argument.");
				[AppDelegate terminateWithExitCode:abExitCodeForInvalidCommand];
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
				[AppDelegate terminateWithExitCode:abExitCodeForInvalidCommand];
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
				[AppDelegate terminateWithExitCode:abExitCodeForInvalidCommand];
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
				[AppDelegate terminateWithExitCode:abExitCodeForInvalidCommand];
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
