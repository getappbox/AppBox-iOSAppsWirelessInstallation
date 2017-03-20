//
//  NSString+CMDQueryStringSerialization.m
//  CMDQueryStringSerialization
//
//  Created by Bryan Irace on 1/26/14.
//  Copyright (c) 2014 Caleb Davenport. All rights reserved.
//

#import "NSString+CMDQueryStringSerialization.h"

@implementation NSString (CMDQueryStringSerialization)

- (NSString *)CMDQueryStringSerialization_stringByAddingEscapes {
    CFStringRef string = CFURLCreateStringByAddingPercentEscapes(
        NULL,
        (CFStringRef)self,
        NULL,
        CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8
    );
    return (NSString *)CFBridgingRelease(string);
}


- (NSString *)CMDQueryStringSerialization_stringByRemovingEscapes {
    return [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end
