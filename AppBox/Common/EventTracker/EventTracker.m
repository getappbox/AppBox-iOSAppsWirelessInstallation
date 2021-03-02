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
    [MSACAnalytics trackEvent:[NSString stringWithFormat:@"Screen-%@", name]];
}

+(void)logEventWithName:(NSString *)eventName customAttributes:(NSDictionary *)attributes flags:(MSACFlags)flags {
    [MSACAnalytics trackEvent:eventName withProperties:attributes flags:flags];
}

+(void)logEventWithType:(LogEventTypes)eventType{
    switch (eventType) {
        case LogEventTypeCopyToClipboard:{
            NSString *name = @"Copy to Clipboard";
            [EventTracker logEventWithName:name customAttributes:nil flags:MSACFlagsDefault];
        }break;
            
        case LogEventTypeCopyToClipboardFromDashboard:{
            NSString *name = @"Copy to Clipboard from Dashboard";
            [EventTracker logEventWithName:name customAttributes:nil flags:MSACFlagsDefault];
        }break;
            
        case LogEventTypeUpdateExternalLink:{
            [EventTracker logEventWithName:@"External Links" customAttributes:@{@"Title":@"Update"} flags:MSACFlagsDefault];
        }break;
            
        case LogEventTypeUploadWithCustomBDFolderName:{
            [EventTracker logEventWithName:@"DB Folder Name" customAttributes:@{@"Custom Name":@"YES"} flags:MSACFlagsDefault];
        }break;
            
        case LogEventTypeUploadWithDefaultDBFolderName:{
            [EventTracker logEventWithName:@"DB Folder Name" customAttributes:@{@"Custom Name":@"NO"} flags:MSACFlagsDefault];
        }break;
            
        case LogEventTypeShortURLFailedInFirstRequest:{
            [EventTracker logEventWithName:@"Short URL Failed" customAttributes:@{@"Request No":@"1"} flags:MSACFlagsNormal];
        }break;
            
        case LogEventTypeShortURLFailedInSecondRequest:{
            [EventTracker logEventWithName:@"Short URL Failed" customAttributes:@{@"Request No":@"2"} flags:MSACFlagsCritical];
        }break;
            
        case LogEventTypeShortURLSuccessInFirstRequest:{
            [EventTracker logEventWithName:@"Short URL Success" customAttributes:@{@"Request No":@"1"} flags:MSACFlagsDefault];
        }break;
            
        case LogEventTypeShortURLSuccessInSecondRequest:{
            [EventTracker logEventWithName:@"Short URL Success" customAttributes:@{@"Request No":@"2"} flags:MSACFlagsCritical];
        }break;
            
        case LogEventTypeShortURLElseBlockExecuted: {
            [EventTracker logEventWithName:@"Short URL Else Block Executed" customAttributes:@{@"Request No":@"1"} flags:MSACFlagsCritical];
        }break;
            
        case LogEventTypeExternalLinkHelp:{
            [EventTracker logEventWithName:@"External Links" customAttributes:@{@"Title":@"Help"} flags:MSACFlagsDefault];
        }break;
            
        case LogEventTypeExternalLinkTwitter:{
            [EventTracker logEventWithName:@"External Links" customAttributes:@{@"Title":@"Twitter"} flags:MSACFlagsDefault];
        }break;
            
        case LogEventTypeExternalLinkReleaseNote:{
            [EventTracker logEventWithName:@"External Links" customAttributes:@{@"Title":@"Release Notes"} flags:MSACFlagsDefault];
        }break;
            
        case LogEventTypeExternalLinkLicense:{
            [EventTracker logEventWithName:@"External Links" customAttributes:@{@"Title":@"License"} flags:MSACFlagsDefault];
        }break;
            
        case LogEventTypeAuthDropbox:{
            [EventTracker logEventWithName:@"Authenticating Dropbox Start" customAttributes:nil  flags:MSACFlagsDefault];
        }break;
            
        case LogEventTypeExitWithoutAuth:{
            [EventTracker logEventWithName:@"AppBox terminated before Dropbox LoggedIN :(" customAttributes:nil flags:MSACFlagsDefault];
        }break;
            
        case LogEventTypeAuthDropboxSuccess: {
            [EventTracker logEventWithName:@"Authenticating Dropbox Success" customAttributes:nil flags:MSACFlagsDefault];
        }break;
            
        case LogEventTypeAuthDropboxError: {
            [EventTracker logEventWithName:@"Authenticating Dropbox Error" customAttributes:nil flags:MSACFlagsCritical];
        }break;
            
        case LogEventTypeAuthDropboxCanceled: {
            [EventTracker logEventWithName:@"Authenticating Dropbox Canceled" customAttributes:nil flags:MSACFlagsNormal];
        }break;
            
        case LogEventTypeExternalLinkKeepSameLink:{
            [EventTracker logEventWithName:@"External Links" customAttributes:@{@"Title":@"Keep Same Link"} flags:MSACFlagsDefault];
        }break;
            
        case LogEventTypeDeleteBuild:{
            [EventTracker logEventWithName:@"Build Deleted" customAttributes:nil flags:MSACFlagsDefault];
        }break;
            
        case LogEventTypeOpenInFinder:{
            [EventTracker logEventWithName:@"Open In Finder" customAttributes:nil flags:MSACFlagsDefault];
        }break;
            
        case LogEventTypeOpenInDropbox:{
            [EventTracker logEventWithName:@"Open In Dropbox" customAttributes:nil flags:MSACFlagsDefault];
        }break;
            
        case LogEventTypeOpenDashboardFromShowLink:{
            [EventTracker logEventWithName:@"Dashboard open from Show Link" customAttributes:nil flags:MSACFlagsDefault];
        }break;
        
            
        default:
            break;
    }
}

+(void)logEventSettingWithType:(LogEventSettingTypes)eventType andSettings:(NSDictionary *)currentSetting{
    switch (eventType) {
        case LogEventSettingTypeUploadIPA:{
            [EventTracker logEventWithName:@"Upload IPA" customAttributes:currentSetting flags:MSACFlagsDefault];
        }break;
            
        case LogEventSettingTypeArchiveAndUpload: {
            [EventTracker logEventWithName:@"Archive and Upload IPA" customAttributes:currentSetting flags:MSACFlagsDefault];
        }break;
            
        case LogEventSettingTypeUploadIPASuccess: {
            [EventTracker logEventWithName:@"IPA Uploaded Success" customAttributes:currentSetting flags:MSACFlagsDefault];
        }break;
        
        default:
            break;
    }
}

+(void)logExceptionEvent:(NSException *)exception {
    [EventTracker logEventWithName:@"Exception"
                  customAttributes:@{ @"debug description": exception.debugDescription,
                                      @"stack": exception.callStackSymbols }
                             flags:MSACFlagsCritical];
}

+(void)logAppBoxVersion {
    DBManager *dbManager = [Common currentDBManager];
    [EventTracker logEventWithName:@"AppBox Details"
                  customAttributes:@{ @"Version": dbManager.version,
                                      @"Name": dbManager.appName,
                                      @"Identifier": dbManager.bundleId }
                             flags:MSACFlagsDefault];
}
@end
