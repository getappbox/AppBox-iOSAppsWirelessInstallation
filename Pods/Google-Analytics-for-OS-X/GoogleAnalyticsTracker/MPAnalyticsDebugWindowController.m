//
//  MPAnalyticsDebugWindowController.h
//  GoogleAnalyticsTracker
//
//  Created by Denis Stas on 4/4/15.
//  Copyright (c) 2015 MacPaw. All rights reserved.
//

#import "MPAnalyticsDebugWindowController.h"


@interface MPAnalyticsDebugWindowController ()

@property (nonatomic, strong) NSMutableArray *eventsArray;
@property (strong) IBOutlet NSArrayController *eventsArrayController;

@end


@implementation MPAnalyticsDebugWindowController

static id _sharedInstance = nil;
+ (instancetype)sharedController
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

+ (void)load
{
    [self sharedController];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
#ifndef DEBUG
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowDebugMenu"])
        {
            return nil;
        }
#endif
        _eventsArray = [NSMutableArray array];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(analyticsReceived:)
                                                     name:@"AnalyticsEvent" object:nil];
    }
    return self;
}

- (NSString *)windowNibName
{
    return @"AnalyticsWindow";
}

- (void)loadWindow
{
    [super loadWindow];
    
    [self.window setLevel:NSStatusWindowLevel];
}

- (void)analyticsReceived:(NSNotification *)aNotification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.eventsArrayController)
        {
            [self.eventsArray insertObject:aNotification.userInfo atIndex:0];
        }
        else
        {
            [self.eventsArrayController insertObject:aNotification.userInfo atArrangedObjectIndex:0];
        }
    });
}

+ (void)showWindow:(nullable id)sender
{
    [[self sharedController] showWindow:sender];
}

@end
