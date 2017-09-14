//
//  MPAnalyticsConfiguration.m
//  GoogleAnalyticsTracker
//
//  Created by Denis Stas on 12/11/15.
//  Copyright © 2015 MacPaw Inc. All rights reserved.
//

#import "MPAnalyticsConfiguration.h"


@interface MPAnalyticsConfiguration ()

@property (nonatomic, copy) NSString *analyticsIdentifier;
@property (nonatomic, strong) NSMutableDictionary *duplicateIdentifiers;

@end


@implementation MPAnalyticsConfiguration

- (instancetype)init
{
    return [self initWithAnalyticsIdentifier:nil];
}

- (instancetype)initWithAnalyticsIdentifier:(NSString *)identifier
{
    self = [super init];
    if (self)
    {
        _analyticsIdentifier = identifier;
    }
    
    return self;
}

- (NSMutableDictionary *)duplicateIdentifiers
{
    if (!_duplicateIdentifiers)
    {
        _duplicateIdentifiers = [NSMutableDictionary dictionary];
    }
    
    return _duplicateIdentifiers;
}

- (void)duplicateEventsForCategory:(NSString *)category toGAID:(NSString *)identifier
{
    if (category && identifier)
    {
        self.duplicateIdentifiers[category] = identifier;
    }
}

- (void)stopDuplicatingEventsForCategory:(NSString *)category
{
    [self.duplicateIdentifiers removeObjectForKey:category];
}

- (NSDictionary *)additionalIdentifiers
{
    return [self.duplicateIdentifiers copy];
}

@end
