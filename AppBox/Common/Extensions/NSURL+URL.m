//
//  NSURL+URL.m
//  AppBox
//
//  Created by Vineet Choudhary on 15/04/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import "NSURL+URL.h"

@implementation NSURL (URL)

-(BOOL)isIPA{
    return (self && [self.pathExtension.lowercaseString isEqualToString:@"ipa" ]);
}

-(BOOL)isProject{
    return (self && ([self.pathExtension.lowercaseString isEqualToString:@"xcodeproj"] || [self.pathExtension.lowercaseString isEqualToString:@"xcworkspace"]));
}

@end
