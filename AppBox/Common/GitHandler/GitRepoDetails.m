//
//  GitRepoDetails.m
//  AppBox
//
//  Created by Vineet Choudhary on 08/02/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "GitRepoDetails.h"

@implementation GitRepoDetails

- (instancetype)init{
    self = [super init];
    if (self) {
        self.branchs = [[NSMutableArray alloc] init];
    }
    return self;
}

@end
