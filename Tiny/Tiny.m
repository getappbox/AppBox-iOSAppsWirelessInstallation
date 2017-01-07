//
//  Tiny.m
//  Tiny
//
//  Created by Scott Petit on 5/10/14.
//  Copyright (c) 2014 Scott Petit. All rights reserved.
//

#import "Tiny.h"

@implementation Tiny

+ (void)shortenURL:(NSURL *)longURL withService:(id<NTAURLShortenerService>)service completion:(TinyURLShortenerCompletionBlock)completionBlock{
    if (!longURL || !service){
        return;
    }
    
    NSURLRequest *URLRequest = [service URLRequestToShortenURL:longURL];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:URLRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error){
            
            //Log failed rate
            [Answers logCustomEventWithName:@"Short URL Failed" customAttributes:@{@"Request No. - ":@1}];
            //Give it another try
            NSURLRequest *URLRequest = [service URLRequestToShortenURL:longURL];
            NSURLSession *session = [NSURLSession sharedSession];
            NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:URLRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (error){
                    
                    //Log failed rate
                    [Answers logCustomEventWithName:@"Short URL Failed" customAttributes:@{@"Request No. - ":@2}];
                    if (completionBlock){
                        completionBlock(longURL, error);
                    }
                    return;
                }
                
                if (data){
                    id JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
                    NSString *keyPath = [service keyPathForShortenedURL];
                    NSString *shortenedURLString = [JSON valueForKeyPath:keyPath];
                    NSURL *URL = [NSURL URLWithString:shortenedURLString];
                    
                    //Log success rate
                    [Answers logCustomEventWithName:@"Short URL Success" customAttributes:@{@"Request No. - ":@2}];
                    if (completionBlock){
                        completionBlock(URL, nil);
                    }
                }
            }];
            [dataTask resume];
        }
        
        if (data){
            id JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            NSString *keyPath = [service keyPathForShortenedURL];
            NSString *shortenedURLString = [JSON valueForKeyPath:keyPath];
            NSURL *URL = [NSURL URLWithString:shortenedURLString];
            //Log success rate
            [Answers logCustomEventWithName:@"Short URL Success" customAttributes:@{@"Request No. - ":@1}];
            if (completionBlock){
                completionBlock(URL, nil);
            }
        }
    }];
    [dataTask resume];
}

@end
