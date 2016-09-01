//
//  Tiny.h
//  Tiny
//
//  Created by Scott Petit on 5/10/14.
//  Copyright (c) 2014 Scott Petit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTAURLShortenerService.h"
#import "GooglURLShortenerService.h"
#import "BitlyURLShortenerService.h"

typedef void(^TinyURLShortenerCompletionBlock)(NSURL *shortURL, NSError *error);

@interface Tiny : NSObject

+ (void)shortenURL:(NSURL *)longURL
       withService:(id<NTAURLShortenerService>)service
        completion:(TinyURLShortenerCompletionBlock)completionBlock;

@end
