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
            [EventTracker logEventWithType:LogEventTypeShortURLFailedInFirstRequest];
            //Give it another try
            NSURLRequest *URLRequest = [service URLRequestToShortenURL:longURL];
            NSURLSession *session = [NSURLSession sharedSession];
            NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:URLRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (error){
                    
                    //Log failed rate
                    [EventTracker logEventWithType:LogEventTypeShortURLFailedInSecondRequest];
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
                    [EventTracker logEventWithType:LogEventTypeShortURLSuccessInSecondRequest];
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
            [EventTracker logEventWithType:LogEventTypeShortURLSuccessInFirstRequest];
            if (completionBlock){
                completionBlock(URL, nil);
            }
        }
    }];
    [dataTask resume];
}

@end
