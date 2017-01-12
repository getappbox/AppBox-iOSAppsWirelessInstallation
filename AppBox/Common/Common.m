//
//  Common.m
//  AppBox
//
//  Created by Vineet Choudhary on 06/09/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "Common.h"

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
    fileDirectory = [fileDirectory stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSURL URLWithString:fileDirectory];
}

+ (void)logScreen:(NSString *)name{
    [Answers logContentViewWithName:name contentType:@"screen" contentId:nil customAttributes:nil];
}

#pragma mark - Notifications
+ (NSModalResponse)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText: title];
    [alert setInformativeText:message];
    [alert setAlertStyle:NSWarningAlertStyle];
    return [alert runModal];
}

+ (void)showLocalNotificationWithTitle:(NSString *)title andMessage:(NSString *)message{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    [notification setTitle:title];
    [notification setInformativeText:message];
    [notification setDeliveryDate:[NSDate dateWithTimeInterval:1 sinceDate:[NSDate date]]];
    [notification setSoundName:NSUserNotificationDefaultSoundName];
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    [center scheduleNotification:notification];
}

#pragma mark - Alert and Checks

+ (void)checkDropboxKeys{
    //Check Dropbox Keys
    if ([abDbAppkey isEqualToString: abEmptyString] && [abDbScreatkey isEqualToString: abEmptyString]){
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText: @"Dropbox app key and screat not found."];
        [alert setInformativeText:@"Please input your dropbox app key and screat in \"AppBox>Common>DropboxKeys.h\" header file.\n\nAlso, please comply with the license."];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert addButtonWithTitle:@"Read License"];
        [alert addButtonWithTitle:@"OK"];
        if ([alert runModal] == NSAlertFirstButtonReturn){
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:abLicenseURL]];
        }
    }
}

+ (void)showUpdateAlertWithUpdateURL:(NSURL *)url{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText: @"New Version Available"];
    [alert setInformativeText:@"A newer version of the \"AppBox\" is available. Do you want to update it? \n\n\n"];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert addButtonWithTitle:@"YES"];
    [alert addButtonWithTitle:@"NO"];
    if ([alert runModal] == NSAlertFirstButtonReturn){
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

@end
