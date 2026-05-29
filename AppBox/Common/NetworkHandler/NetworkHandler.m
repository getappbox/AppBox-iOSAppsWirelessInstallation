//
//  NetworkHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 16/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "NetworkHandler.h"

@implementation NetworkHandler

//MARK: - JSON request, JSON response

+(void)requestWithURL:(NSString *)url withParameters:(id)parmeters andRequestType:(RequestType)requestType andCompletetion:(void (^)(id responseObj, NSInteger httpStatus, NSError *error))completion{
    NSMutableURLRequest *request = [self jsonRequestWithURL:url parameters:parmeters requestType:requestType];
    if (request == nil) {
        [self deliverResponse:nil status:0 error:[self errorWithCode:NSURLErrorBadURL message:@"Invalid request."] toCompletion:completion];
        return;
    }

    DDLogDebug(@"Request In Progress -  %@", url);
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSInteger statusCode = [response isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)response).statusCode : 0;

        // Parse the body as JSON (mirrors AFJSONResponseSerializer).
        id responseObject = nil;
        if (data.length > 0) {
            NSError *jsonError = nil;
            responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (jsonError) {
                DDLogDebug(@"JSON parsing failed for URL: %@", jsonError.localizedDescription);
            }
        }

        BOOL httpSuccess = (statusCode >= 200 && statusCode < 300);
        if (httpSuccess && responseObject != nil) {
            // 2xx with a valid JSON body.
            [self deliverResponse:responseObject status:statusCode error:nil toCompletion:completion];
        } else if (statusCode == HTTP_OK) {
            // 200 with a non-JSON body (e.g. Slack "ok" / Teams "1").
            [self deliverResponse:@"ok" status:statusCode error:nil toCompletion:completion];
        } else {
            [self deliverResponse:nil status:statusCode error:(error ?: [self errorWithCode:statusCode message:@"Request failed."]) toCompletion:completion];
        }
    }];
    [task resume];
}

//MARK: - JSON request, raw (HTTP) response

+(void)getContentOfURL:(NSString *)url withParameters:(id)parmeters withRequestType:(RequestType)requestType andCompletetion:(void (^)(id responseObj, NSInteger statusCode, NSError *error))completion{
    NSMutableURLRequest *request = [self jsonRequestWithURL:url parameters:parmeters requestType:requestType];
    if (request == nil) {
        [self deliverResponse:nil status:0 error:[self errorWithCode:NSURLErrorBadURL message:@"Invalid request."] toCompletion:completion];
        return;
    }

    DDLogDebug(@"Request In Progress -  %@", url);
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSInteger statusCode = [response isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)response).statusCode : 0;
        BOOL httpSuccess = (statusCode >= 200 && statusCode < 300);
        if (httpSuccess && error == nil) {
            [self deliverResponse:data status:statusCode error:nil toCompletion:completion];
        } else {
            [self deliverResponse:nil status:statusCode error:(error ?: [self errorWithCode:statusCode message:@"Request failed."]) toCompletion:completion];
        }
    }];
    [task resume];
}

//MARK: - Helpers

+ (NSMutableURLRequest *)jsonRequestWithURL:(NSString *)urlString parameters:(id)parameters requestType:(RequestType)requestType {
    NSString *finalURLString = urlString;
    NSData *bodyData = nil;

    // Enforce HTTPS for security
    if (finalURLString && [finalURLString hasPrefix:@"http://"]) {
        finalURLString = [@"https://" stringByAppendingString:[finalURLString substringFromIndex:7]];
    }

    if (requestType == RequestPOST) {
        if (parameters != nil) {
            NSError *jsonError = nil;
            bodyData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&jsonError];
            if (jsonError != nil) {
                return nil;
            }
        }
    } else if ([parameters isKindOfClass:[NSDictionary class]] && [(NSDictionary *)parameters count] > 0) {
        NSString *query = [self queryStringFromDictionary:parameters];
        NSString *separator = ([urlString rangeOfString:@"?"].location == NSNotFound) ? @"?" : @"&";
        finalURLString = [NSString stringWithFormat:@"%@%@%@", urlString, separator, query];
    }

    NSURL *url = [NSURL URLWithString:finalURLString];
    if (url == nil) {
        return nil;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = (requestType == RequestPOST) ? @"POST" : @"GET";
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    if (bodyData != nil) {
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        request.HTTPBody = bodyData;
    }
    return request;
}

+ (NSString *)queryStringFromDictionary:(NSDictionary *)dictionary {
    NSMutableCharacterSet *allowed = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowed removeCharactersInString:@"&=?+"];
    NSMutableArray<NSString *> *pairs = [NSMutableArray array];
    for (id key in dictionary) {
        NSString *encodedKey = [[key description] stringByAddingPercentEncodingWithAllowedCharacters:allowed];
        NSString *encodedValue = [[dictionary[key] description] stringByAddingPercentEncodingWithAllowedCharacters:allowed];
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", encodedKey, encodedValue]];
    }
    return [pairs componentsJoinedByString:@"&"];
}

+ (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message {
    return [NSError errorWithDomain:@"AppBoxNetworkHandler" code:code userInfo:@{NSLocalizedDescriptionKey: message}];
}

+ (void)deliverResponse:(id)responseObj status:(NSInteger)status error:(NSError *)error toCompletion:(void (^)(id, NSInteger, NSError *))completion {
    if (completion == nil) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(responseObj, status, error);
    });
}

@end
