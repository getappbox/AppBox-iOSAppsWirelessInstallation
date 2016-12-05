//
//  LogViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 05/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "LogViewController.h"

@interface LogViewController ()

@end

@implementation LogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self startLog];
}

- (void)startLog{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        textView.string = [[AppDelegate appDelegate] sessionLog];
        [self startLog];
    });
}

@end
