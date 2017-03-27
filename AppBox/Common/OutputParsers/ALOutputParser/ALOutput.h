//
//  ALOutput.h
//  AppBox
//
//  Created by Vineet Choudhary on 24/01/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ALOutput : NSObject

@property(nonatomic) BOOL isError;
@property(nonatomic) BOOL isValid;
@property(nonatomic, strong) NSMutableArray *messages;

@end
