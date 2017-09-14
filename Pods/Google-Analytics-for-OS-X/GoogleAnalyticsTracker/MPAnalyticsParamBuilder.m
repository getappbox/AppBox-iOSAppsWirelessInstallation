//
//  MPAnalyticsParamBuilder.m
//  GoogleAnalyticsTracker
//
//  Created by Denis Stas on 12/11/15.
//  Copyright © 2015 MacPaw Inc. All rights reserved.
//

#import "MPAnalyticsParamBuilder.h"


NSString *const MPHitTypeKey = @"t";

NSString *const MPContentDescriptionKey = @"cd";

NSString *const MPEventCategoryKey = @"ec";
NSString *const MPEventActionKey = @"ea";
NSString *const MPEventLabelKey = @"el";
NSString *const MPEventValueKey = @"ev";

NSString *const MPCustomDimensionUserKey = @"cd1";

NSString *const MPUserTimingCategoryKey = @"utc";
NSString *const MPUserTimingVariableKey = @"utv";
NSString *const MPUserTimingTimeKey = @"utt";
NSString *const MPUserTimingLabelKey = @"utl";


@interface MPTrackingRequestParams ()

@property (nonatomic, copy) NSString *hitType;
@property (nonatomic, copy) NSString *contentDescription;
@property (nonatomic, copy) NSString *customDimension;

- (NSDictionary *)dictionaryRepresentationKeys;

@end

@interface MPEventParams ()

@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *action;
@property (nonatomic, copy) NSString *label;
@property (nonatomic, copy) NSNumber *value;

@end

@interface MPTimingParams ()

@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *variable;
@property (nonatomic, copy) NSNumber *time;
@property (nonatomic, copy) NSString *label;

@end


@implementation MPTrackingRequestParams

- (NSDictionary *)dictionaryRepresentationKeys
{
    return @{};
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSDictionary *dictionaryRepresentationKeys = [self dictionaryRepresentationKeys];
    for (NSString *key in dictionaryRepresentationKeys)
    {
        id value = [self valueForKey:dictionaryRepresentationKeys[key]];
        if (value && ![value isEqual:[NSNull null]])
        {
            result[key] = value;
        }
    }
    
    return [result copy];
}

@end

@implementation MPEventParams

- (NSDictionary *)dictionaryRepresentationKeys
{
    return @{ MPHitTypeKey : NSStringFromSelector(@selector(hitType)),
              MPContentDescriptionKey : NSStringFromSelector(@selector(contentDescription)),
              MPCustomDimensionUserKey : NSStringFromSelector(@selector(customDimension)),
              MPEventCategoryKey : NSStringFromSelector(@selector(category)),
              MPEventActionKey : NSStringFromSelector(@selector(action)),
              MPEventLabelKey : NSStringFromSelector(@selector(label)),
              MPEventValueKey : NSStringFromSelector(@selector(value)) };
}

@end

@implementation MPAppViewParams

- (NSDictionary *)dictionaryRepresentationKeys
{
    return @{ MPHitTypeKey : NSStringFromSelector(@selector(hitType)),
              MPContentDescriptionKey : NSStringFromSelector(@selector(contentDescription)) };
}

@end

@implementation MPTimingParams

- (NSDictionary *)dictionaryRepresentationKeys
{
    return @{ MPUserTimingCategoryKey : NSStringFromSelector(@selector(category)),
              MPUserTimingVariableKey : NSStringFromSelector(@selector(variable)),
              MPUserTimingTimeKey : NSStringFromSelector(@selector(time)),
              MPUserTimingLabelKey : NSStringFromSelector(@selector(label)) };
}

@end

@implementation MPParamBuilder

+ (MPEventParams *)eventParamsForCategory:(NSString *)eventCategory action:(NSString *)eventAction
                                    label:(NSString *)eventLabel value:(NSNumber *)eventValue
                       contentDescription:(NSString *)contentDescription customDimension:(NSString *)customDimension
{
    NSAssert(eventCategory && eventAction && eventLabel && eventValue, @"All event arguments should be != nil. Use [NSNull null] to remove one of the parameters from request");
    
    MPEventParams *eventParams = [MPEventParams new];
    eventParams.hitType = @"event";
    eventParams.category = eventCategory;
    eventParams.action = eventAction;
    eventParams.label = eventLabel;
    eventParams.value = eventValue;
    eventParams.contentDescription = contentDescription;
    eventParams.customDimension = customDimension;
    
    return eventParams;
}

+ (MPEventParams *)eventParamsForCategory:(NSString *)eventCategory action:(NSString *)eventAction
                                    label:(NSString *)eventLabel value:(NSNumber *)eventValue
{
    return [self eventParamsForCategory:eventCategory action:eventAction label:eventLabel
                                  value:eventValue contentDescription:nil customDimension:nil];
}

+ (MPAppViewParams *)appViewParamsForScreen:(NSString *)screen
{
    MPAppViewParams *appViewParams = [MPAppViewParams new];
    appViewParams.hitType = @"appview";
    appViewParams.contentDescription = screen;
    
    return appViewParams;
}

+ (MPTimingParams *)timingParamsForCategory:(NSString *)timingCategory variable:(NSString *)timingVariable
                                       time:(NSNumber *)timingTime label:(NSString *)timingLabel
{
    MPTimingParams *timingParams = [MPTimingParams new];
    timingParams.hitType = @"timing";
    timingParams.category = timingCategory;
    timingParams.variable = timingVariable;
    timingParams.time = timingTime;
    timingParams.label = timingLabel;
    
    return timingParams;
}

@end

