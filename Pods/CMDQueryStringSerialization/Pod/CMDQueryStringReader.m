//
//  CMDQueryStringReader.m
//  CMDQueryStringSerialization
//
//  Created by Caleb Davenport on 2/18/14.
//  Copyright (c) 2014 Caleb Davenport. All rights reserved.
//

#import "CMDQueryStringReader.h"
#import "NSString+CMDQueryStringSerialization.h"

@implementation CMDQueryStringReader {
    NSDictionary *_dictionary;
}

#pragma mark - Public

- (instancetype)initWithString:(NSString *)string {
    if ((self = [super init])) {
        _dictionary = [[self class] dictionaryOfKeyValuePairsInString:string];
    }
    return self;
}


- (NSDictionary *)dictionaryValue {
    return [_dictionary copy];
}


#pragma mark - Private

+ (NSDictionary *)dictionaryOfKeyValuePairsInString:(NSString *)string {
    if (!string) {
        return nil;
    }
    
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [self enumerateKeyValuePairsInString:string block:^(NSString *key, NSString *value) {
        [self appendValue:value forKey:key toDictionary:dictionary];        
    }];
    return [dictionary copy];
}


+ (void)enumerateKeyValuePairsInString:(NSString *)string block:(void (^) (NSString *key, NSString *value))block {
    if ([string length] == 0) {
        return;
    }
    NSArray *pairs = [string componentsSeparatedByString:@"&"];
    for (NSString *pair in pairs) {
        NSRange range = [pair rangeOfString:@"="];
        NSString *key = nil;
        NSString *value = nil;
        
        if (range.location == NSNotFound) {
            key = pair;
            value = @"";
        }
        else {
            key = [pair substringToIndex:range.location];
            value = [pair substringFromIndex:(range.location + range.length)];
        }
        
        key = [key stringByReplacingOccurrencesOfString:@"[]" withString:@""];
        key = [key cmd_stringByRemovingEscapes];
        key = key ?: @"";
        
        NSArray *values = [value componentsSeparatedByString:@","];
        for (__strong NSString *value in values) {
            value = [value cmd_stringByRemovingEscapes];
            value = value ?: @"";
            
            block(key, value);
        }
    }
}


+ (void)appendValue:(NSString *)value forKey:(NSString *)key toDictionary:(NSMutableDictionary *)dictionary {
    id existingObject = dictionary[key];
    if (existingObject) {
        if ([existingObject isKindOfClass:[NSArray class]]) {
            dictionary[key] = [existingObject arrayByAddingObject:value];
        }
        else {
            dictionary[key] = @[ existingObject, value ];
        }
    }
    else {
        dictionary[key] = value;
    }
}

@end
