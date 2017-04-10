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
    [manager setRequestSerializer: [AFJSONRequestSerializer serializer]];
    [manager setResponseSerializer: [AFJSONResponseSerializer serializer]];
    if (requestType == RequestGET){
        [manager GET:url parameters:parmeters progress:^(NSProgress * _Nonnull downloadProgress) {
            [[AppDelegate appDelegate] addSessionLog:@"Request In Progress!!"];
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            completion(responseObject, nil);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (((NSHTTPURLResponse *)task.response).statusCode == HTTP_OK) {
                completion(@"ok", nil);
            }else{
                completion(nil, error);
            }
        }];
    }else if (requestType == RequestPOST){
        [manager POST:url parameters:parmeters progress:^(NSProgress * _Nonnull uploadProgress) {
            [[AppDelegate appDelegate] addSessionLog:@"Request In Progress!!"];
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            completion(responseObject, nil);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (((NSHTTPURLResponse *)task.response).statusCode == HTTP_OK) {
                completion(@"ok", nil);
            }else{
                completion(nil, error);
            }
        }];
    }
}

+(void)getContentOfURL:(NSString *)url withParameters:(id)parmeters withRequestType:(RequestType)requestType andCompletetion:(void (^)(id responseObj, NSInteger statusCode, NSError *error))completion{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager setRequestSerializer: [AFJSONRequestSerializer serializer]];
    [manager setResponseSerializer: [AFHTTPResponseSerializer serializer]];
    [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"application/javascript", @"text/html", @"text/javascript", nil]];
    if (requestType == RequestGET){
        [manager GET:url parameters:parmeters progress:^(NSProgress * _Nonnull downloadProgress) {
            [[AppDelegate appDelegate] addSessionLog:@"Request In Progress!!"];
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            completion(responseObject, ((NSHTTPURLResponse *)task.response).statusCode ,nil);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            completion(nil, ((NSHTTPURLResponse *)task.response).statusCode ,error);
        }];
    }else if (requestType == RequestPOST){
        [manager POST:url parameters:parmeters progress:^(NSProgress * _Nonnull uploadProgress) {
            [[AppDelegate appDelegate] addSessionLog:@"Request In Progress!!"];
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            completion(responseObject, ((NSHTTPURLResponse *)task.response).statusCode ,nil);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            completion(nil, ((NSHTTPURLResponse *)task.response).statusCode ,error);
        }];
    }
}
@end
