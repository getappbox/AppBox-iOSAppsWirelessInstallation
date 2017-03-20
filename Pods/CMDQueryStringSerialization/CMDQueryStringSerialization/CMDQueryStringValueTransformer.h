//
//  CMDQueryStringValueTransformer.h
//  CMDQueryStringSerialization
//
//  Created by Caleb Davenport on 7/11/14.
//  Copyright (c) 2014 Caleb Davenport. All rights reserved.
//

#if defined(__has_feature) && __has_feature(modules)
    @import Foundation;
#else
    #import <Foundation/Foundation.h>
#endif
#import "CMDQueryStringWritingOptions.h"

@interface NSObject (CMDQueryStringValueTransformer)

- (NSString *)CMDQueryStringValueTransformer_queryStringWithKey:(NSString *)key options:(CMDQueryStringWritingOptions)options;

@end
