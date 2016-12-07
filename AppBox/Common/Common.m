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
    
+ (NSURL *)getFileDirectoryForFilePath:(NSURL *)filePath{
    NSArray *pathComponents = [filePath.relativePath pathComponents];
    NSString *fileDirectory = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange(0, pathComponents.count - 1)]];
    fileDirectory = [fileDirectory stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSURL URLWithString:fileDirectory];
}

#pragma mark - Notifications
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


#pragma mark - Send Email
+ (void)sendEmailToAddress:(NSString *)address withSubject:(NSString *)subject andBody:(NSString *)body{
    NSString *emailString = [NSString stringWithFormat:@"\
                             tell application \"Mail\"\n\
                             set newMessage to make new outgoing message with properties {subject:\"%@\", content:\"%@\" & return} \n\
                             tell newMessage\n\
                             set visible to false\n\
                             set sender to \"%@\"\n\
                             make new to recipient at end of to recipients with properties {name:\"%@\", address:\"%@\"}\n\
                             tell content\n\
                             ",subject, body, @"AppBox User", address, address ];
    emailString = [emailString stringByAppendingFormat:@"\
                   end tell\n\
                   send\n\
                   end tell\n\
                   end tell"];
    NSAppleScript *emailScript = [[NSAppleScript alloc] initWithSource:emailString];
    [emailScript executeAndReturnError:nil];
    NSLog(@"Message passed to Mail");
}

#pragma mark - Handle System
+ (void)shutdownSystem{
    NSString *scriptAction = @"shut down"; // @"restart"/@"shut down"/@"sleep"/@"log out"
    NSString *scriptSource = [NSString stringWithFormat:@"tell application \"Finder\" to %@", scriptAction];
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:scriptSource];
    NSDictionary *errDict = nil;
    if (![appleScript executeAndReturnError:&errDict]) {
        NSLog(@"%@", errDict);
    }
}

#pragma mark - Get Team Id
+ (NSArray *)getAllTeamId{
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  (__bridge id)kCFBooleanTrue, (__bridge id)kSecReturnAttributes,
                                  (__bridge id)kSecMatchLimitAll, (__bridge id)kSecMatchLimit,
                                  nil];
    
    [query setObject:(__bridge id)kSecClassCertificate forKey:(__bridge id)kSecClass];
    CFTypeRef result = NULL;
    SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    NSArray *certficates = CFBridgingRelease(result);
    NSMutableArray *plainCertifcates = [[NSMutableArray alloc] init];
    NSMutableArray *tempTeamIds = [[NSMutableArray alloc] init];
    [certficates enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableDictionary *certProperties = [[NSMutableDictionary alloc] init];
        NSString *certLabel = [obj valueForKey:(NSString *)kSecAttrLabel];
        NSArray *certComponent = [certLabel componentsSeparatedByString:@": "];
        if (certComponent.count == 2 && [[certComponent firstObject] containsString:@"Distribution"]){
            NSArray *certDetailsComponent = [[certComponent lastObject] componentsSeparatedByString:@" ("];
            if (certDetailsComponent.count == 2){
                NSString *teamId = [[certDetailsComponent lastObject] stringByReplacingOccurrencesOfString:@")" withString:@""];
                [certProperties setValue:certLabel forKey:@"fullName"];
                [certProperties setValue:[certComponent lastObject] forKey:@"teamName"];
                [certProperties setObject:teamId forKey:@"teamId"];
                if ([teamId containsString:@" "]){
                    
                }
                if (![tempTeamIds containsObject:teamId] && ![teamId containsString:@" "]){
                    [tempTeamIds addObject:teamId];
                    [plainCertifcates addObject:certProperties];
                }
            }
        }
    }];
    return plainCertifcates;
}

@end
