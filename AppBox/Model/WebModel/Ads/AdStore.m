//
//  AdStore.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "AdStore.h"

@implementation AdStore{
    
}

+(AdStore *)shared{
    static AdStore *adStore = nil;
    if (adStore == nil) {
        adStore = [[AdStore alloc] init];
        adStore.ads = [[NSMutableArray alloc] init];
    }
    return adStore;
}

+ (void)loadAds{
    [NetworkHandler requestWithURL:abAppBoxAdsURL withParameters:nil andRequestType:RequestGET andCompletetion:^(id responseObj, NSError *error) {
        if ([responseObj isKindOfClass:[NSArray class]]){
            NSArray *rawAds = (NSArray *)responseObj;
            if (rawAds.count > 0) {
                //Clear adstore
                [[[AdStore shared] ads] removeAllObjects];
                
                //Prepare new ads
                [rawAds enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj isKindOfClass:[NSDictionary class]]){
                        NSDictionary *rawAd = (NSDictionary *)obj;
                        
                        //create new ads
                        Ads *ad = [[Ads alloc] initWithRawAd:rawAd];
                        
                        //add new ads
                        [[[AdStore shared] ads] addObject:ad];
                    }
                }];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:abAdsLoadCompleted object:nil];
            }
        }
    }];
}

@end
