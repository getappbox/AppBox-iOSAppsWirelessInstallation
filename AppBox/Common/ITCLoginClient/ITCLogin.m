//
//  ITCLogin.m
//  AppBox
//
//  Created by Vineet Choudhary on 23/03/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "ITCLogin.h"

#define ITCStatsURL @"https://olympus.itunes.apple.com/itc/ui/stats"
#define ITCLoginURL @"https://idmsa.apple.com/appleauth/auth/signin?widgetKey="
#define ITCLoginControlURL @"https://appstoreconnect.apple.com/itc/static-resources/controllers/login_cntrl.js"

#define ITCServiceKeyStartIdentifier @"var itcServiceKey = '"
#define ITCServiceKeyEndIdentifier @"'"

#define ITCLoginSuccess @"Login Success"
#define ITCLoginInvalidStatsIdMsg @"Your Apple ID isn't enabled for iTunes Connect"
#define ITCLoginFailedInvalidEntryMsg @"Invalid username and password combination."
#define ITCLoginFailedOtherErrorMsg(StatusCode) [NSString stringWithFormat:@"Something wrong. Status code = %@",StatusCode]
#define ITCStatsFailedMsg(StatusCode) [NSString stringWithFormat:@"Login was success. But something is wrong. Status code = %@",StatusCode]
#define ITCResponseMsg(request, response) [NSString stringWithFormat:@"%@ response object = %@", request, [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]]


@implementation ITCLogin

+(void)loginWithUserName:(NSString *)username andPassword:(NSString *)password completion:(void (^) (bool success, NSString *message))completion{
    [NetworkHandler getContentOfURL:ITCLoginControlURL withParameters:nil withRequestType:RequestGET andCompletetion:^(id responseObj, NSInteger statusCode, NSError *error) {
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
                    
                    [manager POST:[NSString stringWithFormat:@"%@%@",ITCLoginURL, responseString] parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                        [[AppDelegate appDelegate] addSessionLog:ITCResponseMsg(@"ITCLogin", responseObject)];
                        if (((NSHTTPURLResponse *)task.response).statusCode == HTTP_OK){
                            [manager POST:ITCStatsURL parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                [[AppDelegate appDelegate] addSessionLog:ITCResponseMsg(@"ITCStats", responseObject)];
                                NSInteger statusCode = (((NSHTTPURLResponse *)task.response).statusCode);
                                if (statusCode == HTTP_OK){
                                    completion(YES, ITCLoginSuccess);
                                }else{
                                    completion(NO, ITCStatsFailedMsg([NSNumber numberWithInteger:statusCode]));
                                }
                            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                NSInteger statusCode = (((NSHTTPURLResponse *)task.response).statusCode);
                                if (statusCode == HTTP_UNAUTHORIZED){
                                    completion(NO, ITCLoginInvalidStatsIdMsg);
                                }else{
                                    completion(NO, ITCStatsFailedMsg([NSNumber numberWithInteger:statusCode]));
                                }
                            }];
                        }else{
                            completion(NO, ITCLoginFailedOtherErrorMsg([NSNumber numberWithInteger:statusCode]));
                        }
                    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                        NSInteger statusCode = (((NSHTTPURLResponse *)task.response).statusCode);
                        if (statusCode == HTTP_UNAUTHORIZED) {
                            completion(NO, ITCLoginFailedInvalidEntryMsg);
                        }else{
                            completion(NO, ITCLoginFailedOtherErrorMsg([NSNumber numberWithInteger:statusCode]));
                        }                                                
                    }];
                }
            }
        }
    }];
}

@end
