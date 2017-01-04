//
//  NetworkHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 16/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "NetworkHandler.h"


@implementation NetworkHandler

+(void)requestWithURL:(NSString *)url withParameters:(id)parmeters andRequestType:(RequestType)requestType andCompletetion:(void (^)(id responseObj, NSError *error))completion{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    if (requestType == RequestGET){
        [manager GET:url parameters:parmeters progress:^(NSProgress * _Nonnull downloadProgress) {
            [[AppDelegate appDelegate] addSessionLog:downloadProgress.localizedDescription];
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            completion(responseObject, nil);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            completion(nil, error);
        }];
    }else if (requestType == RequestPOST){
        
    }
}

@end
