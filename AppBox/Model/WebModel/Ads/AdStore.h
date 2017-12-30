//
//  AdStore.h
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Ads.h"

@interface AdStore : NSObject

@property(nonatomic, strong) NSMutableArray<Ads *> *ads;

+ (AdStore *)shared;
+ (void)loadAds;

@end
