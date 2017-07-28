//
//  XCArchiveParser.h
//  AppBox
//
//  Created by Vineet Choudhary on 25/07/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XCArchiveResult.h"

@interface XCArchiveParser : NSObject

+(XCArchiveResult *)archiveResultMessageFromString:(NSString *)unformatedMessage;

@end
