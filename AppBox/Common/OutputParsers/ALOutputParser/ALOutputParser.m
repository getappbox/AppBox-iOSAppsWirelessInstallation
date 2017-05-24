//
//  ALOutputParser.m
//  AppBox
//
//  Created by Vineet Choudhary on 24/01/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "ALOutputParser.h"

#define MESSAGE @"message"
#define PRODUCT_ERRORS @"product-errors"
#define SUCCESS_MESSAGE @"success-message"

@implementation ALOutputParser

+(ALOutput *)messageFromXMLString:(NSString *)xmlString{
    ALOutput *alOutput = [[ALOutput alloc] init];
    if ([xmlString containsString:@"<plist version=\"1.0\">"] && [xmlString containsString:@"</plist>"]){
        NSData *data = [xmlString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        NSMutableDictionary *dict = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&error];
        if (error) {
            NSLog(@"err: %@", error);
        }
        NSLog(@"original dictionary: %@", dict);
        
        //product errors
        if ([dict.allKeys containsObject:PRODUCT_ERRORS]){
            [[dict valueForKey:PRODUCT_ERRORS] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [alOutput.messages addObject:[obj valueForKey:MESSAGE]];
            }];
            [alOutput setIsValid: NO];
            [alOutput setIsError: YES];
        }
        
        //success message
        if ([dict.allKeys containsObject:SUCCESS_MESSAGE]){
            [alOutput.messages addObject: [dict valueForKey:SUCCESS_MESSAGE]];
            [alOutput setIsError:NO];
            [alOutput setIsValid:YES];
        }
        
    }
    return alOutput;
}

@end
