//
//  ALOutput.m
//  AppBox
//
//  Created by Vineet Choudhary on 24/01/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "ALOutput.h"

@implementation ALOutput

- (instancetype)init{
    self = [super init];
    if (self) {
        self.messages = [[NSMutableArray alloc] init];
    }
    return self;
}

@end
