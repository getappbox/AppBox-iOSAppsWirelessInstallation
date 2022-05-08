//
//  ABLog.m
//  AppBox
//
//  Created by Vineet Choudhary on 16/01/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import "ABLog.h"

@implementation ABLog

+(void)log:(NSString *)format, ...{
    if ([UserData debugLog]) {
        va_list args;
        va_start(args, format);
        NSLogv(format, args);
        va_end(args);
    }
}

+(void)logImp:(NSString *)format, ...{
	va_list args;
	va_start(args, format);
	NSLogv(format, args);
	va_end(args);
}

@end
