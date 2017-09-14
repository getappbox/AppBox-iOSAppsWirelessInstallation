//
//  MPAnalyticsConfiguration.h
//  GoogleAnalyticsTracker
//
//  Created by Denis Stas on 12/11/15.
//  Copyright © 2015 MacPaw Inc. All rights reserved.
//

@import Foundation;


@interface MPAnalyticsConfiguration : NSObject

@property (nonatomic, copy, readonly) NSString *analyticsIdentifier;
@property (nonatomic, copy, readonly) NSDictionary *additionalIdentifiers;

- (instancetype)initWithAnalyticsIdentifier:(NSString *)identifier NS_DESIGNATED_INITIALIZER;

- (void)duplicateEventsForCategory:(NSString *)category toGAID:(NSString *)identifier;
- (void)stopDuplicatingEventsForCategory:(NSString *)category;

@end
