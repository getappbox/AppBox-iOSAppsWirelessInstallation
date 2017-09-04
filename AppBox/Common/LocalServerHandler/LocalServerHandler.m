//
//  LocalServerHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 12/08/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "LocalServerHandler.h"

@implementation LocalServerHandler

+(NSString *)getLocalIPAddress{
    NSArray *ipAddresses = [[NSHost hostWithName:[[NSHost currentHost] name]] addresses];
    for (NSString *ipAddress in ipAddresses) {
        if ([ipAddress componentsSeparatedByString:@"."].count == 4) {
            return ipAddress;
        }
    }
    return @"Not Connected.";
}

@end
