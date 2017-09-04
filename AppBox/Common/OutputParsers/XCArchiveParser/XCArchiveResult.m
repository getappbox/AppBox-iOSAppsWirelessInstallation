//
//  XCArchiveResult.m
//  AppBox
//
//  Created by Vineet Choudhary on 25/07/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "XCArchiveResult.h"

@implementation XCArchiveResult

- (instancetype)init {
    self = [super init];
    if (self) {
        self.message = [[NSMutableString alloc] init];
    }
    return self;
}

@end
