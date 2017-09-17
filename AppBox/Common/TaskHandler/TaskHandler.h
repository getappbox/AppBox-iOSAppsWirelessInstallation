//
//  TaskHandler.h
//  AppBox
//
//  Created by Vineet Choudhary on 27/03/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TaskHandler : NSObject

+ (void)runPrivilegeTaskWithName:(NSString *)name andArgument:(NSArray *)arguments outputStream:(void (^) (STPrivilegedTask *task, BOOL success ,NSString *output))outputStream;
+ (void)runTaskWithName:(NSString *)name andArgument:(NSArray *)arguments taskLaunch:(void (^) (NSTask *task))taskLaunch outputStream:(void (^) (NSTask *task, NSString *output))outputStream;

@end
