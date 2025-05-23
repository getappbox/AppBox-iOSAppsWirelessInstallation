//
//  NSString+String.m
//  AppBox
//
//  Created by Vineet Choudhary on 08/04/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import "NSString+String.h"

@implementation NSString (String)

-(NSURL *)ipaURL{
    NSURL *url = [NSURL fileURLWithPath:self];
    if (url && [url.pathExtension.lowercaseString isEqualToString:@"ipa"]) {
        return url;
    }
    return nil;
}

-(bool)isEmpty {
    NSString *string = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return string.length == 0;
}

@end
