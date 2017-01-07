//
//  CMDQueryStringSerialization.h
//  CMDQueryStringSerialization
//
//  Created by Caleb Davenport on 1/21/14.
//  Copyright (c) 2014 Caleb Davenport. All rights reserved.
//

@import Foundation;
#import "CMDQueryStringWritingOptions.h"

/**
 Easily convert between query strings and dictionaries.
 */
@interface CMDQueryStringSerialization : NSObject

/**
 Read a query string into a dictionary.
 
 @param string Query string to be deserialized.
 @param options Serialization options.
 
 @return A dictionary.
 */
+ (NSDictionary *)dictionaryWithQueryString:(NSString *)string;

/**
 Serialize a dictionary into a query string. This is equivalent to calling
 `queryStringWithDictionary:options:` with
 `CMDQueryStringWritingOptionArrayRepeatKeys`
 and `CMDQueryStringWritingOptionDateAsUnixTimestamp`.
 
 @param dictionary Dictionary to be serialized.
 
 @return A query string.
 */
+ (NSString *)queryStringWithDictionary:(NSDictionary *)dictionary;

/**
 Serialize a dictionary into a query string.
 
 @param dictionary Dictionary to be serialized.
 @param options Serialization options.
 
 @return A query string.
 
 @see queryStringWithDictionary:
 */
+ (NSString *)queryStringWithDictionary:(NSDictionary *)dictionary options:(CMDQueryStringWritingOptions)options;

@end

