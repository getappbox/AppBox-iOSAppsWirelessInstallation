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
    [MSAnalytics trackEvent:[NSString stringWithFormat:@"Screen-%@", name]];
}

+(void)logEventWithName:(NSString *)eventName customAttributes:(NSDictionary *)attributes flags:(MSFlags)flags {
    [MSAnalytics trackEvent:eventName withProperties:attributes flags:flags];
}

+(void)logEventWithType:(LogEventTypes)eventType{
    switch (eventType) {
        case LogEventTypeCopyToClipboard:{
            NSString *name = @"Copy to Clipboard";
            [EventTracker logEventWithName:name customAttributes:nil flags:MSFlagsDefault];
        }break;
            
        case LogEventTypeCopyToClipboardFromDashboard:{
            NSString *name = @"Copy to Clipboard from Dashboard";
            [EventTracker logEventWithName:name customAttributes:nil flags:MSFlagsDefault];
        }break;
            
        case LogEventTypeUpdateExternalLink:{
            [EventTracker logEventWithName:@"External Links" customAttributes:@{@"Title":@"Update"} flags:MSFlagsDefault];
        }break;
            
        case LogEventTypeUploadWithCustomBDFolderName:{
            [EventTracker logEventWithName:@"DB Folder Name" customAttributes:@{@"Custom Name":@"YES"} flags:MSFlagsDefault];
        }break;
            
        case LogEventTypeUploadWithDefaultDBFolderName:{
            [EventTracker logEventWithName:@"DB Folder Name" customAttributes:@{@"Custom Name":@"NO"} flags:MSFlagsDefault];
        }break;
            
        case LogEventTypeShortURLFailedInFirstRequest:{
            [EventTracker logEventWithName:@"Short URL Failed" customAttributes:@{@"Request No":@"1"} flags:MSFlagsNormal];
        }break;
            
        case LogEventTypeShortURLFailedInSecondRequest:{
            [EventTracker logEventWithName:@"Short URL Failed" customAttributes:@{@"Request No":@"2"} flags:MSFlagsCritical];
        }break;
            
        case LogEventTypeShortURLSuccessInFirstRequest:{
            [EventTracker logEventWithName:@"Short URL Success" customAttributes:@{@"Request No":@"1"} flags:MSFlagsDefault];
        }break;
            
        case LogEventTypeShortURLSuccessInSecondRequest:{
            [EventTracker logEventWithName:@"Short URL Success" customAttributes:@{@"Request No":@"2"} flags:MSFlagsCritical];
        }break;
            
        case LogEventTypeShortURLElseBlockExecuted: {
            [EventTracker logEventWithName:@"Short URL Else Block Executed" customAttributes:@{@"Request No":@"1"} flags:MSFlagsCritical];
        }break;
            
        case LogEventTypeExternalLinkHelp:{
            [EventTracker logEventWithName:@"External Links" customAttributes:@{@"Title":@"Help"} flags:MSFlagsDefault];
        }break;
            
        case LogEventTypeExternalLinkTwitter:{
            [EventTracker logEventWithName:@"External Links" customAttributes:@{@"Title":@"Twitter"} flags:MSFlagsDefault];
        }break;
            
        case LogEventTypeExternalLinkReleaseNote:{
            [EventTracker logEventWithName:@"External Links" customAttributes:@{@"Title":@"Release Notes"} flags:MSFlagsDefault];
        }break;
            
        case LogEventTypeExternalLinkLicense:{
            [EventTracker logEventWithName:@"External Links" customAttributes:@{@"Title":@"License"} flags:MSFlagsDefault];
        }break;
            
        case LogEventTypeAuthDropbox:{
            [EventTracker logEventWithName:@"Authenticating Dropbox Start" customAttributes:nil  flags:MSFlagsDefault];
        }break;
            
        case LogEventTypeExitWithoutAuth:{
            [EventTracker logEventWithName:@"AppBox terminated before Dropbox LoggedIN :(" customAttributes:nil flags:MSFlagsDefault];
        }break;
            
        case LogEventTypeAuthDropboxSuccess: {
            [EventTracker logEventWithName:@"Authenticating Dropbox Success" customAttributes:nil flags:MSFlagsDefault];
        }break;
            
        case LogEventTypeAuthDropboxError: {
            [EventTracker logEventWithName:@"Authenticating Dropbox Error" customAttributes:nil flags:MSFlagsCritical];
        }break;
            
        case LogEventTypeAuthDropboxCanceled: {
            [EventTracker logEventWithName:@"Authenticating Dropbox Canceled" customAttributes:nil flags:MSFlagsNormal];
        }break;
            
        case LogEventTypeExternalLinkKeepSameLink:{
            [EventTracker logEventWithName:@"External Links" customAttributes:@{@"Title":@"Keep Same Link"} flags:MSFlagsDefault];
        }break;
            
        case LogEventTypeDeleteBuild:{
            [EventTracker logEventWithName:@"Build Deleted" customAttributes:nil flags:MSFlagsDefault];
        }break;
            
        case LogEventTypeOpenInFinder:{
            [EventTracker logEventWithName:@"Open In Finder" customAttributes:nil flags:MSFlagsDefault];
        }break;
            
        case LogEventTypeOpenInDropbox:{
            [EventTracker logEventWithName:@"Open In Dropbox" customAttributes:nil flags:MSFlagsDefault];
        }break;
            
        case LogEventTypeOpenDashboardFromShowLink:{
            [EventTracker logEventWithName:@"Dashboard open from Show Link" customAttributes:nil flags:MSFlagsDefault];
        }break;
        
            
        default:
            break;
    }
}

+(void)logEventSettingWithType:(LogEventSettingTypes)eventType andSettings:(NSDictionary *)currentSetting{
    switch (eventType) {
        case LogEventSettingTypeUploadIPA:{
            [EventTracker logEventWithName:@"Upload IPA" customAttributes:currentSetting flags:MSFlagsDefault];
        }break;
            
        case LogEventSettingTypeArchiveAndUpload: {
            [EventTracker logEventWithName:@"Archive and Upload IPA" customAttributes:currentSetting flags:MSFlagsDefault];
        }break;
            
        case LogEventSettingTypeUploadIPASuccess: {
            [EventTracker logEventWithName:@"IPA Uploaded Success" customAttributes:currentSetting flags:MSFlagsDefault];
        }break;
        
        default:
            break;
    }
}

+(void)logExceptionEvent:(NSException *)exception {
    [EventTracker logEventWithName:@"Exception"
                  customAttributes:@{ @"debug description": exception.debugDescription,
                                      @"stack": exception.callStackSymbols }
                             flags:MSFlagsCritical];
}

+(void)logAppBoxVersion {
    DBManager *dbManager = [Common currentDBManager];
    [EventTracker logEventWithName:@"AppBox Details"
                  customAttributes:@{ @"Version": dbManager.version,
                                      @"Name": dbManager.appName,
                                      @"Identifier": dbManager.bundleId }
                             flags:MSFlagsDefault];
}
@end
