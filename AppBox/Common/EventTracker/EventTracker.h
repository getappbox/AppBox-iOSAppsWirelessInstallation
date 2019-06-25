//
//  EventTracker.h
//  AppBox
//
//  Created by Vineet Choudhary on 14/09/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    LogEventTypeCopyToClipboard,
    LogEventTypeCopyToClipboardFromDashboard,
    LogEventTypeUpdateExternalLink,
    LogEventTypeUploadWithCustomBDFolderName,
    LogEventTypeUploadWithDefaultDBFolderName,
    LogEventTypeShortURLFailedInFirstRequest,
    LogEventTypeShortURLFailedInSecondRequest,
    LogEventTypeShortURLSuccessInFirstRequest,
    LogEventTypeShortURLSuccessInSecondRequest,
    LogEventTypeShortURLElseBlockExecuted,
    LogEventTypeExternalLinkTwitter,
    LogEventTypeExternalLinkHelp,
    LogEventTypeExternalLinkReleaseNote,
    LogEventTypeExternalLinkLicense,
    LogEventTypeExternalLinkKeepSameLink,
    LogEventTypeAuthDropbox,
    LogEventTypeExitWithoutAuth,
    LogEventTypeDeleteBuild,
    LogEventTypeOpenInFinder,
    LogEventTypeOpenInDropbox,
    LogEventTypeOpenDashboardFromShowLink
} LogEventTypes;

typedef enum : NSUInteger {
    LogEventSettingTypeUploadIPA,
    LogEventSettingTypeArchiveAndUpload,
    LogEventSettingTypeUploadIPASuccess,
    LogEventAdsClicked
} LogEventSettingTypes;

@interface EventTracker : NSObject {
    
}

+(void)logScreen:(NSString *)name;
+(void)logEventWithType:(LogEventTypes)eventType;
+(void)logEventSettingWithType:(LogEventSettingTypes)eventType andSettings:(NSDictionary *)currentSetting;
+(void)logEventWithName:(NSString *)eventName customAttributes:(NSDictionary *)attributes action:(NSString *)action label:(NSString *)label value:(NSNumber *)value;

@end
