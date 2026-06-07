//
//  DefaultAppHandler.h
//  AppBox
//
//  Created by Vineet Choudhary on 07/06/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSNotificationName const ABDefaultIPAHandlerDidChangeNotification;

@interface DefaultAppHandler : NSObject

+ (BOOL)isDefaultIPAHandler;
+ (void)setAsDefaultIPAHandler;
+ (void)removeAsDefaultIPAHandler;

@end
