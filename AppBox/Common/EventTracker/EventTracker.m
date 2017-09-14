//
//  EventTracker.m
//  AppBox
//
//  Created by Vineet Choudhary on 14/09/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "EventTracker.h"

@implementation EventTracker

+(void)ga{
    static MPAnalyticsConfiguration *configuration = nil;
    if (configuration == nil) {
        configuration = [[MPAnalyticsConfiguration alloc] initWithAnalyticsIdentifier: abGoogleAnalyticsKey];
        [MPGoogleAnalyticsTracker activateConfiguration:configuration];
    }
}

+(void)logScreen:(NSString *)name{
    [[self class] ga];
    [MPGoogleAnalyticsTracker trackScreen:name];
    [Answers logContentViewWithName:name contentType:@"screen" contentId:nil customAttributes:nil];
}

+(void)logEventWithName:(NSString *)eventName customAttributes:(NSDictionary *)attributes action:(NSString *)action label:(NSString *)label value:(NSNumber *)value {
    [[self class] ga];
    [Answers logCustomEventWithName:eventName customAttributes:attributes];
    if (action && label && value) {
        [MPGoogleAnalyticsTracker trackEventOfCategory:eventName action:action label:label value:value];
    }
}



@end
