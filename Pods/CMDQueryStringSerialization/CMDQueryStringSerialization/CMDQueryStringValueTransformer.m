//
//  CMDQueryStringValueTransformer.m
//  CMDQueryStringSerialization
//
//  Created by Caleb Davenport on 7/11/14.
//  Copyright (c) 2014 Caleb Davenport. All rights reserved.
//

#import "CMDQueryStringValueTransformer.h"
#import "NSString+CMDQueryStringSerialization.h"

#import <ISO8601/ISO8601.h>

@implementation NSObject (CMDQueryStringValueTransformer)

- (NSString *)CMDQueryStringValueTransformer_queryStringWithKey:(NSString *)key options:(CMDQueryStringWritingOptions)options {
    NSString *escapedKey = nil;
    NSString *escapedValue = nil;

    if ((options & CMDQueryStringWritingOptionAddPercentEscapes) == CMDQueryStringWritingOptionAddPercentEscapes) {
        escapedKey = [key CMDQueryStringSerialization_stringByAddingEscapes];
        escapedValue = [self.description CMDQueryStringSerialization_stringByAddingEscapes];
    }
    else {
        escapedKey = key;
        escapedValue = self.description;
    }

    return [NSString stringWithFormat:@"%@=%@", escapedKey, escapedValue];
}

@end

@implementation NSArray (CMDQueryStringValueTransformer)

- (NSString *)CMDQueryStringValueTransformer_queryStringWithKey:(NSString *)key options:(CMDQueryStringWritingOptions)options {
    NSString *escapedKey = nil;
    NSArray *escapedValues = nil;

    if ((options & CMDQueryStringWritingOptionAddPercentEscapes) == CMDQueryStringWritingOptionAddPercentEscapes) {
        escapedKey = [key CMDQueryStringSerialization_stringByAddingEscapes];
        escapedValues = [self valueForKey:@"CMDQueryStringSerialization_stringByAddingEscapes"];
    }
    else {
        escapedKey = key;
        escapedValues = self;
    }

    if ((options & CMDQueryStringWritingOptionArrayCommaSeparatedValues) == CMDQueryStringWritingOptionArrayCommaSeparatedValues) {
        return [NSString stringWithFormat:@"%@=%@", escapedKey, [escapedValues componentsJoinedByString:@","]];
    }
    else if ((options & CMDQueryStringWritingOptionArrayRepeatKeysWithBrackets) == CMDQueryStringWritingOptionArrayRepeatKeysWithBrackets) {
        NSMutableArray *pairs = [[NSMutableArray alloc] init];
        [escapedValues enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
            NSString *pair = [NSString stringWithFormat:@"%@[]=%@", escapedKey, object];
            [pairs addObject:pair];
        }];
        return [pairs componentsJoinedByString:@"&"];
    }
    else {
        NSMutableArray *pairs = [[NSMutableArray alloc] init];
        [escapedValues enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
            NSString *pair = [NSString stringWithFormat:@"%@=%@", escapedKey, object];
            [pairs addObject:pair];
        }];
        return [pairs componentsJoinedByString:@"&"];
    }
}

@end

@implementation NSDictionary (CMDQueryStringValueTransformer)

- (NSString *)CMDQueryStringValueTransformer_queryStringWithKey:(NSString *)namespace options:(CMDQueryStringWritingOptions)options {
    NSMutableArray *pairs = [[NSMutableArray alloc] init];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
        
        // Ensure that key is a string
        if (![key isKindOfClass:[NSString class]]) {
            [NSException raise:NSInvalidArgumentException format:@"%@ is not a valid query string key.", key];
        }
        
        // Convert values
        NSString *pair = [object CMDQueryStringValueTransformer_queryStringWithKey:key options:options];
        [pairs addObject:pair];
    }];
    [pairs sortUsingSelector:@selector(compare:)];
    return [pairs componentsJoinedByString:@"&"];
}

@end

@implementation NSDate (CMDQueryStringValueTransformer)

- (NSString *)CMDQueryStringValueTransformer_queryStringWithKey:(NSString *)key options:(CMDQueryStringWritingOptions)options {
    if ((options & CMDQueryStringWritingOptionDateAsISO8601String) == CMDQueryStringWritingOptionDateAsISO8601String) {
        return [[self ISO8601String] CMDQueryStringValueTransformer_queryStringWithKey:key options:options];
    }
    else {
        NSNumber *number = @((NSInteger)[self timeIntervalSince1970]);
        return [number CMDQueryStringValueTransformer_queryStringWithKey:key options:options];
    }
}

@end
