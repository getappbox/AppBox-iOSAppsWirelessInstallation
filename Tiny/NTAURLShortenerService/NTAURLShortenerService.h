//
//  NTAURLShortenerService.h
//  Tiny
//
//  Created by Scott Petit on 5/10/14.
//  Copyright (c) 2014 Scott Petit. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NTAURLShortenerService <NSObject>

- (NSURLRequest *)URLRequestToShortenURL:(NSURL *)URL;
- (NSString *)keyPathForShortenedURL;

@end
