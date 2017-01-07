//
//  MacHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "MacHandler.h"

@implementation MacHandler

#pragma mark - Handle System
+ (void)shutdownSystem{
    NSString *scriptAction = @"shut down"; // @"restart"/@"shut down"/@"sleep"/@"log out"
    NSString *scriptSource = [NSString stringWithFormat:@"tell application \"Finder\" to %@", scriptAction];
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:scriptSource];
    NSDictionary *errDict = nil;
    if (![appleScript executeAndReturnError:&errDict]) {
        NSLog(@"%@", errDict);
    }
}

@end
