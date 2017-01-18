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

@implementation LogViewController{
    BOOL isAutoScrollEnabled;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self refreshLog];
    isAutoScrollEnabled = YES;
    [Common logScreen:@"AppBox Log"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLog) name:abSessionLogUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScroll:) name:NSScrollViewDidLiveScrollNotification object:nil];
}

-(void)refreshLog{
    if (isAutoScrollEnabled){
        textView.string = [[AppDelegate appDelegate] sessionLog];
        [textView scrollRangeToVisible:NSMakeRange(textView.string.length-1, 1)];
    }
}

-(void)handleScroll:(NSNotification *)notification{
    if ([notification.object isKindOfClass:[NSScrollView class]] && ([notification.object isEqualTo:textView.enclosingScrollView])){
        //get visiable and bound rect
        NSRect  boundsRect = [textView bounds];
        NSRect  visRect = [textView visibleRect];
        
        //Disable auto scroll
        isAutoScrollEnabled = NO;
        
        //enable auto scroll if user scrolled to bottom
        if (NSMaxY(visRect) - NSMaxY(boundsRect) == 0.0){
            isAutoScrollEnabled = YES;
        }
    }
}


@end
