//
//  BitlyURLShortenerService.h
//  Tiny
//
//  Created by Scott Petit on 5/10/14.
//  Copyright (c) 2014 Scott Petit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTAURLShortenerService.h"

@interface BitlyURLShortenerService : NSObject <NTAURLShortenerService>

+ (instancetype)serviceWithAccessToken:(NSString *)accessToken;
- (instancetype)initWithAccessToken:(NSString *)accessToken;

@property (nonatomic, copy, readonly) NSString *accessToken;

@end
