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
    base64EncodedData = [base64EncodedData stringByReplacingOccurrencesOfString:@"/" withString:@""];
    return base64EncodedData;
}

+ (NSModalResponse)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message{
    NSError *error;
    NSAlert *alert = [NSAlert alertWithError:error];
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

@end
