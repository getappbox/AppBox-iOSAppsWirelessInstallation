//
//  EventTracker.h
//  AppBox
//
//  Created by Vineet Choudhary on 14/09/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleAnalyticsTracker/GoogleAnalyticsTracker.h>

@interface EventTracker : NSObject {
    
}

+(void)logScreen:(NSString *)name;
+(void)logEventWithName:(NSString *)eventName customAttributes:(NSDictionary *)attributes action:(NSString *)action label:(NSString *)label value:(NSNumber *)value;

@end
