//
//  BitlyURLShortenerService.m
//  Tiny
//
//  Created by Scott Petit on 5/10/14.
//  Copyright (c) 2014 Scott Petit. All rights reserved.
//

#import "BitlyURLShortenerService.h"
#import <CMDQueryStringSerialization/CMDQueryStringSerialization.h>

@interface BitlyURLShortenerService ()

@end

static NSString * BitlyBaseURL = @"https://api-ssl.bitly.com/v3/shorten?";
static NSString * BitlyAccessTokenKey = @"access_token";
static NSString * BitlyLongURLKey = @"longURL";

@implementation BitlyURLShortenerService

+ (instancetype)serviceWithAccessToken:(NSString *)accessToken
{
    return [[self alloc] initWithAccessToken:accessToken];
}

- (instancetype)initWithAccessToken:(NSString *)accessToken
{
    self = [super init];
    if (self)
    {
        _accessToken = [accessToken copy];
    }
    return self;
}

#pragma mark - NTAURLShortenerService

- (NSURLRequest *)URLRequestToShortenURL:(NSURL *)URL
{
    if (![self.accessToken length])
    {
        NSLog(@"Access Token is required to create a Bitly URL");
        return nil;
    }
    
    NSString *URLString = [URL absoluteString];
    if (![URLString length])
    {
        NSLog(@"URL %@ is required to create a Bitly URL", URL);
        return nil;
    }
    
    NSDictionary *dictionary = @{BitlyAccessTokenKey : self.accessToken, BitlyLongURLKey : URLString};
    NSString *queryString = [CMDQueryStringSerialization queryStringWithDictionary:dictionary];
    NSString *requestString = [BitlyBaseURL stringByAppendingString:queryString];
    
    NSURL *requestURL = [NSURL URLWithString:requestString];
    
    NSMutableURLRequest *URLRequest = [NSMutableURLRequest requestWithURL:requestURL];
    [URLRequest setHTTPMethod:@"GET"];
    [URLRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    return URLRequest;
}

- (NSString *)keyPathForShortenedURL
{
    return @"data.url";
}

@end
