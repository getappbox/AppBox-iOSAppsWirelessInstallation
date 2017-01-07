//
//  NSString+CMDQueryStringSerialization.h
//  CMDQueryStringSerialization
//
//  Created by Bryan Irace on 1/26/14.
//  Copyright (c) 2014 Caleb Davenport. All rights reserved.
//

@import Foundation;

@interface NSString (CMDQueryStringSerialization)

- (NSString *)cmd_stringByAddingEscapes;

- (NSString *)cmd_stringByRemovingEscapes;

@end
