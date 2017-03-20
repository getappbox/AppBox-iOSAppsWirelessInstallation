//
//  NSString+CMDQueryStringSerialization.h
//  CMDQueryStringSerialization
//
//  Created by Bryan Irace on 1/26/14.
//  Copyright (c) 2014 Caleb Davenport. All rights reserved.
//

#if defined(__has_feature) && __has_feature(modules)
    @import Foundation;
#else
    #import <Foundation/Foundation.h>
#endif

@interface NSString (CMDQueryStringSerialization)

- (NSString *)CMDQueryStringSerialization_stringByAddingEscapes;

- (NSString *)CMDQueryStringSerialization_stringByRemovingEscapes;

@end
