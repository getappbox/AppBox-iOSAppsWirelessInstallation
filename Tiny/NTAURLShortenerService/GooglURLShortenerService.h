//
//  GooglURLShortenerService.h
//  Tiny
//
//  Created by Scott Petit on 5/10/14.
//  Copyright (c) 2014 Scott Petit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTAURLShortenerService.h"

@interface GooglURLShortenerService : NSObject <NTAURLShortenerService>

+ (instancetype)service;

/// According to Google An API key is highly recommended.
/// An auth token is optional for shorten requests. If you provide one, the short URL will be unique, and it will show up in the authenticated user's dashboard at goo.gl.
/// https://developers.google.com/url-shortener/v1/getting_started
+ (instancetype)serviceWithAPIKey:(NSString *)key;
- (instancetype)initWithAPIKey:(NSString *)key;

@property (nonatomic, copy, readonly) NSString *apiKey;

@end
