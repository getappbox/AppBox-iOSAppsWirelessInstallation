//
//  Common.h
//  AppBox
//
//  Created by Vineet Choudhary on 06/09/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface Common : NSObject

+ (void)shutdownSystem;
+ (NSString*)generateUUID;
+ (NSURL *)getFileDirectoryForFilePath:(NSURL *)filePath;
+ (NSModalResponse)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message;
+ (void)showLocalNotificationWithTitle:(NSString *)title andMessage:(NSString *)message;
+ (void)sendEmailToAddress:(NSString *)address withSubject:(NSString *)subject andBody:(NSString *)body;

@end
