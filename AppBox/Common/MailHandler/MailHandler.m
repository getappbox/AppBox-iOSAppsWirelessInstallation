//
//  MailHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "MailHandler.h"

@implementation MailHandler

//MARK: - Check Valid Email
+ (BOOL)isValidEmail:(NSString *)checkString{
    NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,}$";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", stricterFilterString];
    return [emailTest evaluateWithObject:checkString];
}

+ (BOOL)isAllValidEmail:(NSString *)checkString{
    NSString *stricterFilterString = @"(([a-zA-Z0-9_\\-\\.]+)@((\\[[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,}|[0-9]{1,3})(\\]?)(\\s*,\\s*|\\s*$))*";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", stricterFilterString];
    return [emailTest evaluateWithObject:checkString];
}

+ (void)showInvalidEmailAddressAlert{
    [Common showAlertWithTitle:@"Invalid email address" andMessage:@"The email address entered was invalid. Please reenter it (Example: username@example.com).\n\nFor multiple email please enter like (username@example.com,username2@example.com,username@example2.com)."];
}

//MARK: - Parse customised message with IPA Upload Info
+ (NSString *)parseMessage:(NSString *)message forIPAUploadInfo:(IPAUploadInfo *)ipaUploadInfo {
    NSString *messageCopy = message.copy;
    messageCopy = [messageCopy stringByReplacingOccurrencesOfString:@"{BUILD_NAME}" withString:ipaUploadInfo.name];
    messageCopy = [messageCopy stringByReplacingOccurrencesOfString:@"{BUILD_NUMBER}" withString:ipaUploadInfo.build];
    messageCopy = [messageCopy stringByReplacingOccurrencesOfString:@"{BUILD_VERSION}" withString:ipaUploadInfo.version];
    messageCopy = [messageCopy stringByReplacingOccurrencesOfString:@"{SHARE_URL}" withString: ipaUploadInfo.appShortShareableURL.absoluteString];

    // If SHARE_URL keyword was not used, append it for compatibility
    if (![message containsString: @"{SHARE_URL}"]) {
        messageCopy = [messageCopy stringByAppendingFormat:@" - %@", ipaUploadInfo.appShortShareableURL];
    }
    
    return messageCopy;
}

@end
