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

+ (NSString*)generateUUID;
+ (NSURL *)getFileDirectoryForFilePath:(NSURL *)filePath;
+ (NSError *)errorWithDesc:(NSString *)error andCode:(NSInteger)code;
+ (BOOL)isValidWebhookURL:(NSString *)urlString;

+ (void)showNoInternetConnectionAvailabeAlert;
+ (void)showUploadNotificationWithName:(NSString *)name andURL:(NSURL *)url;
+ (NSModalResponse)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message;

+ (DBManager *)currentDBManager;
@end
