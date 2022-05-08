//
//  NetworkHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 16/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "NetworkHandler.h"


@implementation NetworkHandler

+(void)requestWithURL:(NSString *)url withParameters:(id)parmeters andRequestType:(RequestType)requestType andCompletetion:(void (^)(id responseObj, NSInteger httpStatus, NSError *error))completion{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager setRequestSerializer: [AFJSONRequestSerializer serializer]];
    [manager setResponseSerializer: [AFJSONResponseSerializer serializer]];
    if (requestType == RequestGET){
        [manager GET:url parameters:parmeters headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
            DDLogDebug(@"Request In Progress -  %@", url);
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSInteger statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
            completion(responseObject, statusCode, nil);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSInteger statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
            if (statusCode == HTTP_OK) {
                completion(@"ok", statusCode, nil);
            }else{
                completion(nil, statusCode, error);
            }
        }];
    }else if (requestType == RequestPOST){
        [manager POST:url parameters:parmeters headers:nil progress:^(NSProgress * _Nonnull uploadProgress) {
            DDLogDebug(@"Request In Progress -  %@", url);
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSInteger statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
            completion(responseObject, statusCode, nil);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSInteger statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
            if (statusCode == HTTP_OK) {
                completion(@"ok", statusCode, nil);
            }else{
                completion(nil, statusCode, error);
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
        [manager GET:url parameters:parmeters  headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
            DDLogDebug(@"Request In Progress -  %@", url);
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            completion(responseObject, ((NSHTTPURLResponse *)task.response).statusCode ,nil);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            completion(nil, ((NSHTTPURLResponse *)task.response).statusCode ,error);
        }];
    }else if (requestType == RequestPOST){
        [manager POST:url parameters:parmeters headers:nil progress:^(NSProgress * _Nonnull uploadProgress) {
            DDLogDebug(@"Request In Progress -  %@", url);
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            completion(responseObject, ((NSHTTPURLResponse *)task.response).statusCode ,nil);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            completion(nil, ((NSHTTPURLResponse *)task.response).statusCode ,error);
        }];
    }
}
@end
