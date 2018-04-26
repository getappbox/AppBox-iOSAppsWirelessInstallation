//
//  MailHandler.h
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MailHandler : NSObject

+ (void)showInvalidEmailAddressAlert;
+ (BOOL)isValidEmail:(NSString *)checkString;
+ (BOOL)isAllValidEmail:(NSString *)checkString;
+ (NSString *)parseMessage:(NSString *)message forProject:(XCProject *)project;

@end
