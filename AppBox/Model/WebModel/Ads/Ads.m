//
//  Ads.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "Ads.h"

NSString *const adTitleKey = @"title";
NSString *const adSubTitleKey = @"subtitle";
NSString *const adURLKey = @"url";
NSString *const adActiveKey = @"active";
NSString *const adFeaturedKey = @"featured";

@implementation Ads

- (instancetype)initWithRawAd:(NSDictionary *)rawAd{
    self = [super init];
    if (self) {
        if ([rawAd.allKeys containsObject:adTitleKey] && [rawAd.allKeys containsObject:adSubTitleKey] && [rawAd.allKeys containsObject:adURLKey] && [rawAd.allKeys containsObject:adActiveKey] && [rawAd.allKeys containsObject:adFeaturedKey]) {
            self.title = [rawAd objectForKey:adTitleKey];
            self.subtitle = [rawAd objectForKey:adSubTitleKey];
            self.url = [rawAd objectForKey:adURLKey];
            self.active = [rawAd objectForKey:adActiveKey];
            self.featured = [rawAd objectForKey:adFeaturedKey];
        }
    }
    return self;
}

@end
