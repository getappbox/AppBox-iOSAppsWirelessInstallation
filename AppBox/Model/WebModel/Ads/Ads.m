//
//  Ads.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "Ads.h"

@implementation Ads

+ (NSArray<Ads *> *)getAllAdsWithAds:(NSArray<Ads *> *)newAds{
    static NSMutableArray *ads = nil;
    if (ads == nil) {
        
    }
}

+ (void)loadAds{
    [NetworkHandler requestWithURL:abAppBoxAdsURL withParameters:nil andRequestType:RequestGET andCompletetion:^(id responseObj, NSError *error) {
        
    }];
}

@end
