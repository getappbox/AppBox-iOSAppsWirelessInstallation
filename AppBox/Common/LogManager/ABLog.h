//
//  ABLog.h
//  AppBox
//
//  Created by Vineet Choudhary on 16/01/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ABLog : NSObject

+(void)log:(NSString *)format, ...;
+(void)logImp:(NSString *)format, ...;

@end
