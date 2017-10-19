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

#pragma mark - Notifications
+ (NSModalResponse)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message{
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"ALERT -\nTitle - %@ Message - %@", title, message]];
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText: title == nil ? @"Error" : title];
    [alert setInformativeText:message == nil ? @"" : message];
    [alert setAlertStyle:NSWarningAlertStyle];
    return [alert runModal];
}

+ (void)showNoInternetConnectionAvailabeAlert{
    [Common showAlertWithTitle:@"Error" andMessage:@"There is no Internet connection."];
}

+ (void)showLocalNotificationWithTitle:(NSString *)title andMessage:(NSString *)message{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    [notification setTitle:title == nil ? @"Error" : title];
    [notification setInformativeText:message == nil ? @"" : message];
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
        [alert setInformativeText:@"Please input your dropbox app key and screat in \"AppBox>Common>DropboxKeys.h\" header file. Or you can download the executable file of appbox by clicking button Download Appbox. \n\nAlso, please comply with the license."];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert addButtonWithTitle:@"Download Appbox"];
        [alert addButtonWithTitle:@"Read License"];
        [alert addButtonWithTitle:@"OK"];
        NSModalResponse response = [alert runModal];
        if (response == NSAlertFirstButtonReturn){
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:abDefaultLatestDownloadURL]];
        }
        if (response == NSAlertSecondButtonReturn){
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:abLicenseURL]];
        }
    }
}

@end
