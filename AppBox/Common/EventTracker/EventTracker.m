//
//  EventTracker.m
//  AppBox
//
//  Created by Vineet Choudhary on 14/09/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "EventTracker.h"

@implementation EventTracker

+(void)ga{
    static MPAnalyticsConfiguration *configuration = nil;
    if (configuration == nil) {
        configuration = [[MPAnalyticsConfiguration alloc] initWithAnalyticsIdentifier: [DBManager gaKey]];
        [MPGoogleAnalyticsTracker activateConfiguration:configuration];
    }
}

+(void)logScreen:(NSString *)name{
    [[self class] ga];
    [MPGoogleAnalyticsTracker trackScreen:name];
    [Answers logContentViewWithName:name contentType:@"screen" contentId:nil customAttributes:nil];
}

+(void)logEventWithName:(NSString *)eventName customAttributes:(NSDictionary *)attributes action:(NSString *)action label:(NSString *)label value:(NSNumber *)value {
    [[self class] ga];
    [Answers logCustomEventWithName:eventName customAttributes:attributes];
    if (action && label && value) {
        [MPGoogleAnalyticsTracker trackEventOfCategory:eventName action:action label:label value:value];
    }
}

+(void)logEventWithType:(LogEventTypes)eventType{
    switch (eventType) {
        case LogEventTypeCopyToClipboard:{
            NSString *name = @"Copy to Clipboard";
            [EventTracker logEventWithName:name customAttributes:@{name:@1} action:name label:name value:@1];
        }break;
            
        case LogEventTypeCopyToClipboardFromDashboard:{
            NSString *name = @"Copy to Clipboard from Dashboard";
            [EventTracker logEventWithName:name customAttributes:@{name:@1} action:name label:name value:@1];
        }break;
            
        case LogEventTypeUpdateExternalLink:{
            [EventTracker logEventWithName:@"External Links" customAttributes:@{@"title":@"Update"} action:@"title" label:@"Update" value:@1];
        }break;
            
        case LogEventTypeUploadWithCustomBDFolderName:{
            [EventTracker logEventWithName:@"DB Folder Name" customAttributes:@{@"Custom Name":@1} action:@"DB Folder Name" label:@"Custom" value:@1];
        }break;
            
        case LogEventTypeUploadWithDefaultDBFolderName:{
            [EventTracker logEventWithName:@"DB Folder Name" customAttributes:@{@"Custom Name":@0} action:@"DB Folder Name" label:@"Default" value:@1];
        }break;
            
        case LogEventTypeShortURLFailedInFirstRequest:{
            [EventTracker logEventWithName:@"Short URL Failed" customAttributes:@{@"Request No":@1} action:@"Request No" label:@"1" value:@1];
        }break;
            
        case LogEventTypeShortURLFailedInSecondRequest:{
            [EventTracker logEventWithName:@"Short URL Failed" customAttributes:@{@"Request No":@2} action:@"Request No" label:@"2" value:@1];
        }break;
            
        case LogEventTypeShortURLSuccessInFirstRequest:{
            [EventTracker logEventWithName:@"Short URL Success" customAttributes:@{@"Request No":@1}
                                    action:@"Request No" label:@"1" value:@1];
        }break;
            
        case LogEventTypeShortURLSuccessInSecondRequest:{
            [EventTracker logEventWithName:@"Short URL Success" customAttributes:@{@"Request No":@2}
                                    action:@"Request No" label:@"2" value:@1];
        }break;
            
        case LogEventTypeShortURLElseBlockExecuted: {
            [EventTracker logEventWithName:@"Short URL Else Block Executed" customAttributes:@{@"Request No":@1}
                                    action:@"Request No" label:@"1" value:@1];
        }break;
            
        case LogEventTypeExternalLinkHelp:{
            [EventTracker logEventWithName:@"External Links" customAttributes:@{@"title":@"Help"} action:@"title" label:@"Help" value:@1];
        }break;
            
        case LogEventTypeExternalLinkTwitter:{
            [EventTracker logEventWithName:@"External Links" customAttributes:@{@"title":@"Twitter"} action:@"title" label:@"Twitter" value:@1];
        }break;
            
        case LogEventTypeExternalLinkReleaseNote:{
            [EventTracker logEventWithName:@"External Links" customAttributes:@{@"title":@"Release Notes"} action:@"title" label:@"Release Notes" value:@1];
        }break;
            
        case LogEventTypeExternalLinkLicense:{
            [EventTracker logEventWithName:@"External Links" customAttributes:@{@"title":@"License"} action:@"title" label:@"License" value:@1];
        }break;
            
        case LogEventTypeAuthDropbox:{
            [EventTracker logEventWithName:@"Authenticating Dropbox" customAttributes:nil action:nil label:nil value:nil];
        }break;
            
        case LogEventTypeExitWithoutAuth:{
            [EventTracker logEventWithName:@"AppBox terminated before Dropbox LoggedIN :(" customAttributes:nil action:nil label:nil value:nil];
        }break;
            
        case LogEventTypeExternalLinkKeepSameLink:{
            [EventTracker logEventWithName:@"External Links" customAttributes:@{@"title":@"Keep Same Link"}
                                    action:@"Keep Same Link" label:@"Keep Same Link" value:@1];
        }break;
            
        case LogEventTypeDeleteBuild:{
            NSString *name = @"Build Deleted";
            [EventTracker logEventWithName:name customAttributes:@{name:@1} action:name label:name value:@1];
        }break;
            
        case LogEventTypeOpenInFinder:{
            NSString *name = @"Open In Finder";
            [EventTracker logEventWithName:name customAttributes:@{name:@1} action:name label:name value:@1];
        }break;
            
        case LogEventTypeOpenInDropbox:{
            NSString *name = @"Open In Dropbox";
            [EventTracker logEventWithName:name customAttributes:@{name:@1} action:name label:name value:@1];
        }break;
            
        case LogEventTypeOpenDashboardFromShowLink:{
            NSString *name = @"Dashboard open from Show Link";
            [EventTracker logEventWithName:name customAttributes:@{name:@1} action:name label:name value:@1];
        }break;
        
            
        default:
            break;
    }
}

+(void)logEventSettingWithType:(LogEventSettingTypes)eventType andSettings:(NSDictionary *)currentSetting{
    switch (eventType) {
        case LogEventSettingTypeUploadIPA:{
            [EventTracker logEventWithName:@"Upload IPA" customAttributes:currentSetting action:@"Upload IPA" label:@"Upload IPA" value:@1];
        }break;
            
        case LogEventSettingTypeArchiveAndUpload: {
            [EventTracker logEventWithName:@"Archive and Upload IPA" customAttributes:currentSetting action:@"Archive and Upload IPA" label:@"Archive and Upload IPA" value:@1];
        }break;
            
        case LogEventSettingTypeUploadIPASuccess: {
            [EventTracker logEventWithName:@"IPA Uploaded Success" customAttributes:currentSetting action:@"Uploaded to" label:@"AppStore" value:@1];
        }break;
            
        case LogEventAdsClicked:{
            NSString *name = @"Ad Clicked";
            [EventTracker logEventWithName:name customAttributes:currentSetting action:@"Ad Clicked" label:@"AppBox-Native" value:@1];
        }break;
        
        default:
            break;
    }
}

@end
