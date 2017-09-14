//
//  MPGoogleAnalyticsTracker.h
//  GoogleAnalyticsTracker
//
//  Created by Denis Stas on 11/27/12.
//  Copyright (c) 2012 Denis Stas. All rights reserved.
//

@import Foundation;


@class MPAnalyticsConfiguration, MPEventParams, MPTimingParams;

@interface MPGoogleAnalyticsTracker : NSObject

+ (void)activateConfiguration:(MPAnalyticsConfiguration *)configuration;

+ (void)trackEventOfCategory:(NSString *)category action:(NSString *)action
                       label:(NSString *)label value:(NSNumber *)value;

+ (void)trackEventOfCategory:(NSString *)category action:(NSString *)action
                       label:(NSString *)label value:(NSNumber *)value
          contentDescription:(NSString *)contentDescription customDimension:(NSString *)dimension;

+ (void)trackTimingOfCategory:(NSString *)category variable:(NSString *)variable
                         time:(NSNumber *)time label:(NSString *)label;

+ (void)trackScreen:(NSString *)screen;
+ (void)trackModalScreen:(NSString *)modalScreen;
+ (void)switchToModalScreen:(NSString *)modalScreen;
+ (void)stopTrackingModalScreen;

@end

