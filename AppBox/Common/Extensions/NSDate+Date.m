//
//  NSDate+Date.m
//  AppBox
//
//  Created by Vineet Choudhary on 17/10/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "NSDate+Date.h"

@implementation NSDate (Date)

-(NSString *)string{
    NSDateFormatter *dateFormater = [[NSDateFormatter alloc] init];
    [dateFormater setDateFormat:@"YYYY-MM-dd, hh:mm a"];
    return [dateFormater stringFromDate:self];
}

@end
