//
//  MPAnalyticsParamBuilder.h
//  GoogleAnalyticsTracker
//
//  Created by Denis Stas on 12/11/15.
//  Copyright © 2015 MacPaw Inc. All rights reserved.
//

@import Foundation;


@class MPEventParams, MPTimingParams, MPAppViewParams;

@interface MPParamBuilder : NSObject

+ (MPEventParams *)eventParamsForCategory:(NSString *)eventCategory action:(NSString *)eventAction
                                    label:(NSString *)eventLabel value:(NSNumber *)eventValue;

+ (MPEventParams *)eventParamsForCategory:(NSString *)eventCategory action:(NSString *)eventAction
                                    label:(NSString *)eventLabel value:(NSNumber *)eventValue
                       contentDescription:(NSString *)contentDescription customDimension:(NSString *)customDimension;

+ (MPAppViewParams *)appViewParamsForScreen:(NSString *)screen;

+ (MPTimingParams *)timingParamsForCategory:(NSString *)timingCategory variable:(NSString *)timingVariable
                                       time:(NSNumber *)timingTime label:(NSString *)timingLabel;

@end


@interface MPTrackingRequestParams : NSObject

@property (nonatomic, copy, readonly) NSString *hitType;
@property (nonatomic, copy, readonly) NSString *contentDescription;
@property (nonatomic, copy, readonly) NSString *customDimension;

- (NSDictionary *)dictionaryRepresentation;

@end

@interface MPEventParams : MPTrackingRequestParams

@property (nonatomic, copy, readonly) NSString *category;
@property (nonatomic, copy, readonly) NSString *action;
@property (nonatomic, copy, readonly) NSString *label;
@property (nonatomic, copy, readonly) NSNumber *value;

@end

@interface MPAppViewParams : MPTrackingRequestParams

@end

@interface MPTimingParams : MPTrackingRequestParams

@property (nonatomic, copy, readonly) NSString *category;
@property (nonatomic, copy, readonly) NSString *variable;
@property (nonatomic, copy, readonly) NSNumber *time;
@property (nonatomic, copy, readonly) NSString *label;

@end
