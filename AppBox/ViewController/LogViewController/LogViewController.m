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
    [self refreshLog];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLog) name:abSessionLogUpdated object:nil];
}

-(void)refreshLog{
    textView.string = [[AppDelegate appDelegate] sessionLog];
    [textView scrollRangeToVisible:NSMakeRange(textView.string.length-1, 1)];
}


@end
