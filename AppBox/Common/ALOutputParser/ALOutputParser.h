//
//  ALOutputParser.h
//  AppBox
//
//  Created by Vineet Choudhary on 24/01/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALOutput.h"

@interface ALOutputParser : NSObject

+(ALOutput *)messageFromXMLString:(NSString *)xmlString;

@end
