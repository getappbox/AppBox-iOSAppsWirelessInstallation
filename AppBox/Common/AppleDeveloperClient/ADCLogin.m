//
//  ADCLogin.m
//  AppBox
//
//  Created by Vineet Choudhary on 23/03/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "ADCLogin.h"

#define AppleLoginURL @"https://idmsa.apple.com/appleauth/auth/signin?widgetKey="
#define AppleLoginControl @"https://itunesconnect.apple.com/itc/static-resources/controllers/login_cntrl.js"

#define ITCServiceKeyStartIdentifier @"var itcServiceKey = '"
#define ITCServiceKeyEndIdentifier @"'"


@implementation ADCLogin

+(void)loginWithUserName:(NSString *)username andPassword:(NSString *)password completion:(void (^) (bool success, NSString *message))completion{
    [NetworkHandler getContentOfURL:AppleLoginControl withParameters:nil withRequestType:RequestGET andCompletetion:^(id responseObj, NSInteger statusCode, NSError *error) {
        NSString *responseString = [[NSString alloc] initWithData:responseObj encoding:NSUTF8StringEncoding];
        if (responseString && [responseString containsString:ITCServiceKeyStartIdentifier]){
            responseString = [responseString componentsSeparatedByString:ITCServiceKeyStartIdentifier][1];
            if (responseString && [responseString containsString:ITCServiceKeyEndIdentifier]){
                responseString = [responseString componentsSeparatedByString:ITCServiceKeyEndIdentifier][0];
                if (responseString.length > 0){
                    NSDictionary *parameters = @{@"accountName": username, @"password": password, @"rememberMe": @NO};
                    
                    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
                    [manager setRequestSerializer: [AFJSONRequestSerializer serializer]];
                    [manager setResponseSerializer: [AFHTTPResponseSerializer serializer]];
                    [[manager requestSerializer] setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                    [[manager requestSerializer] setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
                    [[manager requestSerializer] setValue:responseString forHTTPHeaderField:@"X-Apple-Widget-Key"];
                    [[manager requestSerializer] setValue:@"application/json, text/javascript" forHTTPHeaderField:@"Accept"];
                    [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"application/json", @"text/javascript", @"text/html", nil]];
                    
                    [manager POST:[NSString stringWithFormat:@"%@%@",AppleLoginURL, responseString] parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
                        [[AppDelegate appDelegate] addSessionLog:@"Request In Progress!!"];
                    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                        if (((NSHTTPURLResponse *)task.response).statusCode == HTTP_OK){
                            completion(YES, @"Login Success");
                        }else{
                            completion(NO, [NSString stringWithFormat:@"Something wrong. Status code %@",[NSNumber numberWithInteger:statusCode]]);
                        }
                    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                        NSInteger statusCode = (((NSHTTPURLResponse *)task.response).statusCode);
                        if (statusCode == HTTP_UNAUTHORIZED) {
                            completion(NO, @"Invalid username and password combination.");
                        }else{
                            completion(NO, [NSString stringWithFormat:@"Something wrong. Status code %@",[NSNumber numberWithInteger:statusCode]]);
                        }                                                
                    }];
                }
            }
        }
    }];
}

@end
