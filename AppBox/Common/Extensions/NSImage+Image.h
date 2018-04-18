//
//  NSImage+Image.h
//  AppBox
//
//  Created by Vineet Choudhary on 18/04/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (Image)

+(NSImage *)imageWithCGImage:(CGImageRef)cgImage;

@end
