//
//  NSImage+Image.m
//  AppBox
//
//  Created by Vineet Choudhary on 18/04/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import "NSImage+Image.h"

@implementation NSImage (Image)

+(NSImage *)imageWithCGImage:(CGImageRef)cgImage{
    static NSLock *imageLock = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageLock = [[NSLock alloc] init];
    });
    NSImage *image;
    [imageLock lock];
    image = [[NSImage alloc] initWithCGImage:cgImage size:NSMakeSize(250, 250)];
    [imageLock unlock];
    return image;
}

@end
