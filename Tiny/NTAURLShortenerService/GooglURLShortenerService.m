//
//  GooglURLShortenerService.m
//  Tiny
//
//  Created by Scott Petit on 5/10/14.
//  Copyright (c) 2014 Scott Petit. All rights reserved.
//

#import "GooglURLShortenerService.h"
#import <CMDQueryStringSerialization/CMDQueryStringSerialization.h>

@interface GooglURLShortenerService ()

@property (nonatomic, strong) NSURL *requestURL;

@end

static NSString * GooglBaseURL = @"https://www.googleapis.com/urlshortener/v1/url";

@implementation GooglURLShortenerService

#pragma mark - Init

+ (instancetype)service
{
    return [[self alloc] initWithAPIKey:nil];
}

+ (instancetype)serviceWithAPIKey:(NSString *)key
{
    return [[self alloc] initWithAPIKey:key];
}

- (instancetype)initWithAPIKey:(NSString *)key
{
    self = [super init];
    if (self)
    {
        _apiKey = [key copy];
    }
    return self;
}

#pragma mark - Accessors

- (NSURL *)requestURL
{
    if (!_requestURL) {
        NSString *URLString = GooglBaseURL;
        if (self.apiKey) {
            NSDictionary *dictionary = @{@"key" : self.apiKey};
            NSString *queryString = [CMDQueryStringSerialization queryStringWithDictionary:dictionary];
            URLString = [GooglBaseURL stringByAppendingFormat:@"?%@", queryString];
        }
        _requestURL = [NSURL URLWithString:URLString];
    }
    return _requestURL;
}

#pragma mark - NTAURLShortenerService

- (NSURLRequest *)URLRequestToShortenURL:(NSURL *)URL
{
    NSString *URLString = [URL absoluteString];
    if (![URLString length])
    {
        NSLog(@"URL %@ is required to create a Googl URL", URL);
        return nil;
    }
        
    NSMutableURLRequest *URLRequest = [NSMutableURLRequest requestWithURL:self.requestURL];
    [URLRequest setHTTPMethod:@"POST"];
    [URLRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSString *bodyString = [NSString stringWithFormat:@"{\"longUrl\": \"%@\"}", URLString];
    [URLRequest setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
    
    return URLRequest;
}

- (NSString *)keyPathForShortenedURL
{
    return @"id";
}

@end
