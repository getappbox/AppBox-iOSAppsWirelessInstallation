//
//  CMDQueryStringWritingOptions.h
//  CMDQueryStringSerialization
//
//  Created by Caleb Davenport on 7/11/14.
//  Copyright (c) 2014 Caleb Davenport. All rights reserved.
//

typedef NS_OPTIONS(NSUInteger, CMDQueryStringWritingOptions) {
    
    // Default: Arrays encoded with format: `key=value1&key=value2`
    CMDQueryStringWritingOptionArrayRepeatKeys = 1 << 0,
    
    // Arrays encoded with format: `key[]=value1&key[]=value2`
    CMDQueryStringWritingOptionArrayRepeatKeysWithBrackets = 1 << 1,
    
    // Arrays encoded with format: `key=value1,value2`
    CMDQueryStringWritingOptionArrayCommaSeparatedValues = 1 << 2,
    
    // Defualt: Dates encoded as Unix time stamps
    CMDQueryStringWritingOptionDateAsUnixTimestamp = 1 << 3,

    // Dates encoded as ISO8601 strings
    CMDQueryStringWritingOptionDateAsISO8601String = 1 << 4,

    // Control whether keys and values are percent encoded
    CMDQueryStringWritingOptionAddPercentEscapes = 1 << 5,
};
