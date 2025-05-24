//
//  EventTracker.m
//  AppBox
//
//  Created by Vineet Choudhary on 14/09/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "EventTracker.h"

@implementation EventTracker

+(void)logScreen:(NSString *)name{
//	NSString *screenName = [NSString stringWithFormat:@"Screen-%@", name];
}

+(void)logEventWithName:(NSString *)eventName customAttributes:(NSDictionary *)attributes {

}

+(void)logEventWithType:(LogEventTypes)eventType{
/*
    switch (eventType) {
        case LogEventTypeCopyToClipboard:{
            NSString *name = @"Copy to Clipboard";
        }break;
            
        case LogEventTypeCopyToClipboardFromDashboard:{
            NSString *name = @"Copy to Clipboard from Dashboard";
        }break;
            
        case LogEventTypeUpdateExternalLink:{
			NSString *name = @"External Links";
			NSDictionary *attributes = @{
				@"Title": @"Update"
			};
        }break;
            
        case LogEventTypeUploadWithCustomBDFolderName:{
			NSString *name = @"DB Folder Name";
			NSDictionary *attributes = @{
				@"Custom Name": @"YES"
			};
        }break;
            
        case LogEventTypeUploadWithDefaultDBFolderName:{
			NSString *name = @"DB Folder Name";
			NSDictionary *attributes = @{
				@"Custom Name": @"NO"
			};
        }break;
            
        case LogEventTypeShortURLFailedInFirstRequest:{
			NSString *name = @"Short URL Failed";
			NSDictionary *attributes = @{
				@"Request No": @"1"
			};
        }break;
            
        case LogEventTypeShortURLFailedInSecondRequest:{
			NSString *name = @"Short URL Failed";
			NSDictionary *attributes = @{
				@"Request No": @"2"
			};
        }break;
            
        case LogEventTypeShortURLSuccessInFirstRequest:{
			NSString *name = @"Short URL Success";
			NSDictionary *attributes = @{
				@"Request No": @"1"
			};
        }break;
            
        case LogEventTypeShortURLSuccessInSecondRequest:{
			NSString *name = @"Short URL Success";
			NSDictionary *attributes = @{
				@"Request No": @"2"
			};
        }break;
            
        case LogEventTypeShortURLElseBlockExecuted: {
			NSString *name = @"Short URL Else Block Executed";
			NSDictionary *attributes = @{
				@"Request No": @"1"
			};
        }break;
            
        case LogEventTypeExternalLinkHelp:{
			NSString *name = @"External Links";
			NSDictionary *attributes = @{
				@"Title": @"Help"
			};
        }break;
            
        case LogEventTypeExternalLinkTwitter:{
			NSString *name = @"External Links";
			NSDictionary *attributes = @{
				@"Title": @"Twitter"
			};
        }break;
            
        case LogEventTypeExternalLinkReleaseNote:{
			NSString *name = @"External Links";
			NSDictionary *attributes = @{
				@"Title": @"Release Notes"
			};
        }break;
            
        case LogEventTypeExternalLinkLicense:{
			NSString *name = @"External Links";
			NSDictionary *attributes = @{
				@"Title": @"License"
			};
        }break;
            
        case LogEventTypeAuthDropbox:{
			NSString *name = @"Authenticating Dropbox Start";
        }break;
            
        case LogEventTypeExitWithoutAuth:{
			NSString *name = @"Exit Without Auth";
        }break;
            
        case LogEventTypeAuthDropboxSuccess: {
			NSString *name = @"Authenticating Dropbox Success";
        }break;
            
        case LogEventTypeAuthDropboxError: {
			NSString *name = @"Authenticating Dropbox Error";
        }break;
            
        case LogEventTypeAuthDropboxCanceled: {
			NSString *name = @"Authenticating Dropbox Canceled";
        }break;
            
        case LogEventTypeExternalLinkKeepSameLink:{
			NSString *name = @"External Links";
			NSDictionary *attributes = @{
				@"Title": @"Keep Same Link"
			};
        }break;
            
        case LogEventTypeDeleteBuild:{
			NSString *name = @"Delete Build";
        }break;
            
        case LogEventTypeOpenInFinder:{
			NSString *name = @"Open In Finder";
        }break;
            
        case LogEventTypeOpenInDropbox:{
			NSString *name = @"Open In Dropbox";
        }break;
            
        case LogEventTypeOpenDashboardFromShowLink:{
			NSString *name = @"Dashboard open from Show Link";
        }break;
        
            
        default:
            break;
    }
*/
}

+(void)logEventSettingWithType:(LogEventSettingTypes)eventType andSettings:(NSDictionary *)currentSetting{
/*
	switch (eventType) {
        case LogEventSettingTypeUploadIPA:{
			NSString *name = @"Upload IPA";
        }break;
            
        case LogEventSettingTypeArchiveAndUpload: {
			NSString *name = @"Archive and Upload IPA";
        }break;
            
        case LogEventSettingTypeUploadIPASuccess: {
			NSString *name = @"Upload IPA Success";
        }break;
        
        default:
            break;
    }
*/
}

+(void)logExceptionEvent:(NSException *)exception {
/*
	NSString *name = @"Exception";
	NSDictionary *attributes = @{
		@"debug description":exception.debugDescription,
		@"stack":exception.callStackSymbols
	};
 */
}

+(void)logAppBoxVersion {
/*
    DBManager *dbManager = [Common currentDBManager];
	NSString *name = @"AppBox Version";
	NSDictionary *attributes = @{
		@"Version": dbManager.version,
		@"Name": dbManager.appName,
		@"Identifier": dbManager.bundleId
	};
*/
}
@end
