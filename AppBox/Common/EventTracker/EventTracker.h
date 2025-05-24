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
    LogEventTypeAuthDropboxSuccess,
    LogEventTypeAuthDropboxCanceled,
    LogEventTypeAuthDropboxError,
    LogEventTypeDeleteBuild,
    LogEventTypeOpenInFinder,
    LogEventTypeOpenInDropbox,
    LogEventTypeOpenDashboardFromShowLink
} LogEventTypes;

typedef enum : NSUInteger {
    LogEventSettingTypeUploadIPA,
    LogEventSettingTypeArchiveAndUpload,
    LogEventSettingTypeUploadIPASuccess,
} LogEventSettingTypes;

@interface EventTracker : NSObject {
    
}

+(void)logAppBoxVersion;
+(void)logScreen:(NSString *)name;
+(void)logEventWithType:(LogEventTypes)eventType;
+(void)logExceptionEvent:(NSException *)exception;
+(void)logEventSettingWithType:(LogEventSettingTypes)eventType andSettings:(NSDictionary *)currentSetting;
+(void)logEventWithName:(NSString *)eventName customAttributes:(NSDictionary *)attributes;

@end
