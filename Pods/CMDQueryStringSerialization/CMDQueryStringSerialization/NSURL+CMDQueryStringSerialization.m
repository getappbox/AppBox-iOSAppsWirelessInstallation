//
//  NSURL+CMDQueryStringSerialization.m
//  CMDQueryStringSerialization
//
//  Created by Caleb Davenport on 5/28/15.
//  Copyright (c) 2015 Caleb Davenport. All rights reserved.
//

#import "NSURL+CMDQueryStringSerialization.h"
#import "CMDQueryStringSerialization.h"

@implementation NSURL (CMDQueryStringSerialization)

- (NSURL *)cmd_URLWithQueryDictionary:(NSDictionary *)dictionary {
    if ([dictionary count] == 0) {
        return self;
    }

    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES];
    components.query = [CMDQueryStringSerialization queryStringWithDictionary:dictionary];
    return components.URL;
}

- (NSURL *)cmd_URLByAddingQueryDictionary:(NSDictionary *)dictionary {
    if ([dictionary count] == 0) {
        return self;
    }

    CMDQueryStringWritingOptions options = (
        CMDQueryStringWritingOptionArrayRepeatKeysWithBrackets |
        CMDQueryStringWritingOptionDateAsUnixTimestamp
    );

    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES];
    NSMutableDictionary *mutableParameters = [[NSMutableDictionary alloc] init];
    [mutableParameters addEntriesFromDictionary:[CMDQueryStringSerialization dictionaryWithQueryString:components.query]];
    [mutableParameters addEntriesFromDictionary:dictionary];
    components.query = [CMDQueryStringSerialization queryStringWithDictionary:mutableParameters options:options];
    return components.URL;
}

- (NSDictionary *)cmd_queryDictionary {
    return [CMDQueryStringSerialization dictionaryWithQueryString:self.query];
}

@end
