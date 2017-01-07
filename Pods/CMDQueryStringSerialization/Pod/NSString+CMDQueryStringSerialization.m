//
//  NSString+CMDQueryStringSerialization.m
//  CMDQueryStringSerialization
//
//  Created by Bryan Irace on 1/26/14.
//  Copyright (c) 2014 Caleb Davenport. All rights reserved.
//

#import "NSString+CMDQueryStringSerialization.h"

@implementation NSString (CMDQueryStringSerialization)

- (NSString *)cmd_stringByAddingEscapes {
    CFStringRef string = CFURLCreateStringByAddingPercentEscapes(
        NULL,
        (CFStringRef)self,
        NULL,
        CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8
    );
    return (NSString *)CFBridgingRelease(string);
}


- (NSString *)cmd_stringByRemovingEscapes {
    return [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end
