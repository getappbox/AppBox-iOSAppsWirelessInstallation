//
//  MailHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "MailHandler.h"

@implementation MailHandler

#pragma mark - Check Valid Email
+ (BOOL)isValidEmail:(NSString *)checkString{
    NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", stricterFilterString];
    return [emailTest evaluateWithObject:checkString];
}

+ (BOOL)isAllValidEmail:(NSString *)checkString{
    NSString *stricterFilterString = @"(([a-zA-Z0-9_\\-\\.]+)@((\\[[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\\]?)(\\s*,\\s*|\\s*$))*";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", stricterFilterString];
    return [emailTest evaluateWithObject:checkString];
}

+ (void)showInvalidEmailAddressAlert{
    [Common showAlertWithTitle:@"Invalid email address" andMessage:@"The email address entered was invalid. Please reenter it (Example: username@example.com).\n\nFor multiple email please enter like (username@example.com,username2@example.com,username@example2.com)."];
}

#pragma mark - Parse customised message with project details
+ (NSString *)parseMessage:(NSString *)message forProject:(XCProject *)project {
    NSString *messageCopy = message.copy;
    messageCopy = [messageCopy stringByReplacingOccurrencesOfString:@"{PROJECT_NAME}" withString:project.name];
    messageCopy = [messageCopy stringByReplacingOccurrencesOfString:@"{BUILD_NUMBER}" withString:project.build];
    messageCopy = [messageCopy stringByReplacingOccurrencesOfString:@"{BUILD_VERSION}" withString:project.version];
    if (project.selectedSchemes) {
        messageCopy = [messageCopy stringByReplacingOccurrencesOfString:@"{PROJECT_SCHEME}" withString:project.selectedSchemes];
    } else {
        messageCopy = [messageCopy stringByReplacingOccurrencesOfString:@"{PROJECT_SCHEME}" withString:@"Default"];
    }
    return messageCopy;
}

@end
