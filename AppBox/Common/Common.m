//
//  Common.m
//  AppBox
//
//  Created by Vineet Choudhary on 06/09/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "Common.h"
#import <UserNotifications/UserNotifications.h>

@implementation Common

+ (NSString*)generateUUID {
    NSMutableData *data = [NSMutableData dataWithLength:32];
    int result = SecRandomCopyBytes(NULL, 32, data.mutableBytes);
    NSAssert(result == 0, @"Error generating random bytes: %d", errno);
    NSString *base64EncodedData = [data base64EncodedStringWithOptions:0];
    base64EncodedData = [base64EncodedData stringByReplacingOccurrencesOfString:@"/" withString:abEmptyString];
    return base64EncodedData;
}
    
+ (NSURL *)getFileDirectoryForFilePath:(NSURL *)filePath{
    NSArray *pathComponents = [filePath.relativePath pathComponents];
    NSString *fileDirectory = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange(0, pathComponents.count - 1)]];
    fileDirectory = [fileDirectory stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    return [NSURL URLWithString:fileDirectory];
}

+(NSError *)errorWithDesc:(NSString *)error andCode:(NSInteger)code{
    NSMutableDictionary *errorInfo = [[NSMutableDictionary alloc] init];
    [errorInfo setValue:error forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:NSCocoaErrorDomain code:code userInfo:errorInfo];
}

+ (BOOL)isValidWebhookURL:(NSString *)urlString {
    if (urlString.length == 0) return NO;
    NSURL *url = [NSURL URLWithString:urlString];
    return (url != nil && url.scheme != nil && url.host != nil &&
            ([url.scheme isEqualToString:@"https"] || [url.scheme isEqualToString:@"http"]));
}

//MARK: - Notifications
+ (NSModalResponse)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message{
	DDLogInfo(@"ALERT -\nTitle - %@ Message - %@", title, message);
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText: title == nil ? @"Error" : title];
    [alert setInformativeText:message == nil ? @"" : message];
	[alert setAlertStyle:NSAlertStyleWarning];
    return [alert runModal];
}

+ (void)showNoInternetConnectionAvailabeAlert{
    [Common showAlertWithTitle:@"Error" andMessage:@"There is no Internet connection."];
}

+ (void)showUploadNotificationWithName:(NSString *)name andURL:(NSURL *)url {
    NSString *title = [NSString stringWithFormat:@"%@ Uploaded.", name];
    NSString *message = [NSString stringWithFormat:@"Share URL - %@", url.absoluteString];
    
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = title;
    content.body = message;
    content.sound = [UNNotificationSound defaultSound];
    
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
    NSString *identifier = [[NSUUID UUID] UUIDString];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
    
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            DDLogError(@"Failed to schedule notification: %@", error.localizedDescription);
        }
    }];
}

+ (DBManager *)currentDBManager {
    static DBManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[DBManager alloc] init];
        manager.appName = [NSBundle.mainBundle.infoDictionary objectForKey:(NSString *)kCFBundleNameKey];
        manager.version = [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleShortVersionString"];
        manager.bundleId = [NSBundle.mainBundle.infoDictionary objectForKey:(NSString *)kCFBundleIdentifierKey];
    });
    return manager;
}


@end
