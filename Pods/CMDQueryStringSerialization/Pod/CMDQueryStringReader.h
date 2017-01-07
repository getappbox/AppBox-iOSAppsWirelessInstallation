//
//  CMDQueryStringReader.h
//  CMDQueryStringSerialization
//
//  Created by Caleb Davenport on 2/18/14.
//  Copyright (c) 2014 Caleb Davenport. All rights reserved.
//

@import Foundation;

@interface CMDQueryStringReader : NSObject

- (instancetype)initWithString:(NSString *)string;

- (NSDictionary *)dictionaryValue;

@end
