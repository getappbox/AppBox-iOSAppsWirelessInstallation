//
//  Tiny.m
//  Tiny
//
//  Created by Scott Petit on 5/10/14.
//  Copyright (c) 2014 Scott Petit. All rights reserved.
//

#import "Tiny.h"

@implementation Tiny

+ (void)shortenURL:(NSURL *)longURL
       withService:(id<NTAURLShortenerService>)service
        completion:(TinyURLShortenerCompletionBlock)completionBlock
{
    if (!longURL || !service)
    {
        return;
    }
    
    NSURLRequest *URLRequest = [service URLRequestToShortenURL:longURL];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:URLRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error)
        {
            if (completionBlock)
            {
                completionBlock(nil, error);
            }
            return;
        }
        
        if (data)
        {
            id JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            
            NSString *keyPath = [service keyPathForShortenedURL];
            NSString *shortenedURLString = [JSON valueForKeyPath:keyPath];
            
            NSURL *URL = [NSURL URLWithString:shortenedURLString];
            
            if (completionBlock)
            {
                completionBlock(URL, nil);
            }
        }
    }];
    [dataTask resume];
}

@end
