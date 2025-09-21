//
//  RepoBuilder.m
//  AppBox
//
//  Created by Vineet Choudhary on 07/04/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "CIProjectBuilder.h"

//Project
NSString * const RepoProjectKey = @"project";
NSString * const RepoSchemeKey = @"scheme";
NSString * const RepoBuildTypeKey = @"buildtype";
NSString * const RepoTeamIdKey = @"teamid";
NSString * const RepoKeepSameLinkKey = @"keepsamelink";
NSString * const RepoDropboxFolderNameKey = @"dropboxfoldername";
NSString * const RepoEmailKey = @"email";
NSString * const RepoPersonalMessageKey = @"personalmessage";

//xcode
NSString * const XcodeVersionKey = @"xcode";
NSString * const XcodeVersionIdentifier = @"{VERSION}";

//Certificate
NSString * const RepoCertificateNameKey = @"name";
NSString * const RepoCertificatePasswordKey = @"password";
NSString * const RepoCertificateDirectoryName = @"cert";

//iTunesConnect
NSString *const RepoITCEmail = @"itcemail";
NSString *const RepoITCPassword = @"itcpassword";

@implementation CIProjectBuilder{
    
}

//MARK: - IPA
+ (XCProject *)xcProjectWithIPAPath:(NSString *)ipaPath {
    XCProject *project = [[XCProject alloc] initEmpty];
    project.ipaFullPath = [NSURL fileURLWithPath:ipaPath];
    [[self class] setCommonArgumentsToProject:project];
    return project;
}


//MARK: - Common Arguments
+(void)setCommonArgumentsToProject:(XCProject *)project {
    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
	for (NSString *argument in arguments) {

		//Project Emails
		if ([argument containsString:abArgsEmails]) {
			NSArray *components = [argument componentsSeparatedByString:abArgsEmails];
			if (components.count == 2) {
				DDLogInfo(@"Changing project Emails to \"%@\" from \"%@\"", [components lastObject], project.emails);
				project.emails = [components lastObject];
			} else {
				DDLogInfo(@"Invalid Emails Argument \"%@\"",arguments);
				exit(abExitCodeForInvalidCommand);
			}
		}

		//Project Personal Messages
		else if ([argument containsString:abArgsPersonalMessage]) {
			NSArray *components = [argument componentsSeparatedByString:abArgsPersonalMessage];
			if (components.count == 2) {
				DDLogInfo(@"Changing project personal message to \"%@\" from \"%@\"", [components lastObject], project.personalMessage);
				project.personalMessage = [components lastObject];
			} else {
				DDLogInfo(@"Invalid Personal Message Argument \"%@\"",arguments);
				exit(abExitCodeForInvalidCommand);
			}
		}

		//Project Keep Same Link
		else if ([argument containsString:abArgsKeepSameLink]) {
			NSArray *components = [argument componentsSeparatedByString:abArgsKeepSameLink];
			if (components.count == 2) {
				DDLogInfo(@"Changing Keep Same Link to \"%@\" from \"%@\"", [components lastObject], project.keepSameLink);
				project.keepSameLink = ([[components lastObject] isEqualToString:@"0"] || ((BOOL)[[components lastObject] boolValue]) == NO) ? @0 : @1;
			} else {
				DDLogInfo(@"Invalid Keep Same Link Argument \"%@\"",arguments);
				exit(abExitCodeForInvalidCommand);
			}
		}

		//Project dropbox folder name
		else if ([argument containsString:abArgsDropBoxFolderName]) {
			NSArray *components = [argument componentsSeparatedByString:abArgsDropBoxFolderName];
			if (components.count == 2) {
				DDLogInfo(@"Changing Dropbox folder name to \"%@\" from \"%@\"", [components lastObject], project.personalMessage);
				NSString *bundlePath = [NSString stringWithFormat:@"/%@",[components lastObject]];
				bundlePath = [bundlePath stringByReplacingOccurrencesOfString:@" " withString:abEmptyString];
				project.bundleDirectory = [NSURL URLWithString:bundlePath];
			} else {
				DDLogInfo(@"Invalid Dropbox Folder Name Argument \"%@\"",arguments);
				exit(abExitCodeForInvalidCommand);
			}
		}

		//Webhook Message
		else if ([argument containsString:abArgsWebHookMessage]) {
			NSArray *components = [argument componentsSeparatedByString:abArgsWebHookMessage];
			if (components.count == 2) {
				DDLogInfo(@"Set Webhook message to \"%@\"", [components lastObject]);
				project.webhookMessage = [components lastObject];
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
				project.slackWebhook = [components lastObject];
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
				project.msTeamsWebhook = [components lastObject];
			} else {
				DDLogInfo(@"Invalid MS Teams Webhook Argument \"%@\"",arguments);
				exit(abExitCodeForInvalidCommand);
			}
		}

		//Email and Email Subject Prefix
		NSMutableSet *emails = [[NSMutableSet alloc] init];

		if (project.emails && project.emails.length > 0) {
			[emails addObjectsFromArray:[project.emails componentsSeparatedByString:@","]];
		}

		[emails removeObject:@""];
		if (emails.count > 0) {
			project.emails = [emails.allObjects componentsJoinedByString:@","];
		}

	}
}

@end

