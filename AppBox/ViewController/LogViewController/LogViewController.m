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
    //log view
    [EventTracker logScreen:@"AppBox Log"];
    
    //enable auto scroll
    isAutoScrollEnabled = YES;
    
    //refresh log
    [self refreshLog];
    
    //add observer for log and scroll
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLog) name:abSessionLogUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScroll:) name:NSScrollViewDidLiveScrollNotification object:nil];
}

-(void)refreshLog{
    //if auto scroll enabled replace content and scroll to bottom
    if (isAutoScrollEnabled){
        textView.string = [[AppDelegate appDelegate] sessionLog];
		weakify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
			strongify(self);
			[self->textView scrollToEndOfDocument:self];
        });
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
			weakify(self);
            dispatch_async(dispatch_get_main_queue(), ^{
				strongify(self);
                [self refreshLog];
            });
        }
    }
}


@end
