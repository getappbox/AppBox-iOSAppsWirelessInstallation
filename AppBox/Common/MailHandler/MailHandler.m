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

#pragma mark - Send Mail
+ (void)sendMailForProject:(XCProject *)project complition:(void (^) (BOOL success))complition{
    NSString *subject;
    NSMutableString *body;
    if (project != nil) {
        //subject
        subject = [NSString stringWithFormat:@"%@ %@ (%@) is ready to test - AppBox", project.name, project.version, project.build];
        
        //body
        body = [NSMutableString stringWithFormat:@"<html><body><h1 style=\"color: #333; font-size: 25px; font-weight:50; padding: 0px; text-align: center;\">"];
        [body appendFormat:@"%@ %@ (%@) for iOS is ready to test.</h1>", project.name, project.version, project.build];
        [body appendFormat:@"<center> <a href=\"%@\" style=\"color: green; text-align: center; font-size: 30px;\">%@</a></center><p style=\"color: #333; font-size: 20px; text-align: center;\">To test this app, open above url on your iOS device and install the app.</p>", project.appShortShareableURL, project.appShortShareableURL];
        
        //add developer personal message into body
        if (project.personalMessage != nil && project.personalMessage.length > 0) {
            NSString *developerMessage = [MailHandler parseMessage:project.personalMessage forProject:project];
            [body appendFormat:@"<hr/><blockquote style=\"background:#FFF8DC; color: #333; font-size: 15px; padding : 12px\">Message from Developer : <br>%@</blockquote><hr/>", developerMessage];
        }
        
        //add email footer in body
        [body appendString:@"<p style=\"color: #333; font-size: 10px;\">This is an auto-generated mail by <a href=\"https://github.com/vineetchoudhary/AppBox-iOSAppsWirelessInstallation\">AppBox - Build, Test and Distribute iOS Apps</a>.</p></body></html>"];
        
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
        [parameters setValue:abMailGunFromEmail forKey:@"from"];
        [parameters setValue:project.emails forKey:@"to"];
        [parameters setValue:subject forKey:@"subject"];
        [parameters setValue:body forKey:@"html"];
        
        [ABLog log:@"Mail Parameters - %@", parameters];
        
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        [manager setRequestSerializer: [AFHTTPRequestSerializer serializer]];
        [manager setResponseSerializer: [AFJSONResponseSerializer serializer]];
        [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:@"api" password:abMailGunKey];
        

        [manager POST:[NSString stringWithFormat:abMailGunBaseURL] parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Mail Response - %@", responseObject]];
            complition(YES);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (((NSHTTPURLResponse *)task.response).statusCode == HTTP_OK) {
                complition(YES);
            }else if (error){
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Mail Sent Error - %@", error.localizedDescription]];
                complition(NO);
            } else {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Mail Sent Error - Unknown Error"]];
                complition(NO);
            }
        }];
        
    }
    
    
}

@end
