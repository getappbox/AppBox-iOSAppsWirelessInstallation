//
//  MBProgressHUD+ProgressHud.m
//  AppBox
//
//  Created by Vineet Choudhary on 18/05/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "MBProgressHUD+ProgressHud.h"

@implementation ABHudViewController (ProgressHud)

+(void)showStatus:(NSString *)status onView:(NSView *)view {
    ABHudViewController *hud = [ABHudViewController hudForView:view hide:NO];
    hud.status = status;
    hud.showAds = [view isKindOfClass:[DragDropView class]] ? YES: NO;
    hud.hudType = HudTypeProgress;
    hud.progress = [NSNumber numberWithInteger:-1];
}

+(void)showStatus:(NSString *)status witProgress:(double)progress onView:(NSView *)view {
    ABHudViewController *hud = [ABHudViewController hudForView:view hide:NO];
    hud.progress = [NSNumber numberWithDouble:progress];
    hud.showAds = YES;
    hud.hudType = HudTypeProgress;
    hud.status = status;
}

+(void)showStatus:(NSString *)status forSuccess:(BOOL)success onView:(NSView *)view {
    ABHudViewController *hud = [ABHudViewController hudForView:view hide:NO];
    hud.status = status;
    hud.result = success;
    hud.showAds = [view isKindOfClass:[DragDropView class]] ? YES: NO;
    hud.hudType = HudTypeResult;
    [ABHudViewController hideAllHudFromView:view after:2];
}

+(void)showOnlyStatus:(NSString *)status onView:(NSView *)view{
    ABHudViewController *hud = [ABHudViewController hudForView:view hide:NO];
    hud.status = status;
    hud.showAds = [view isKindOfClass:[DragDropView class]] ? YES: NO;
    hud.hudType = HudTypeStatus;
    [ABHudViewController hideAllHudFromView:view after:3];
}

+(void)hideAllHudFromView:(NSView *)view after:(NSTimeInterval)sec{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sec * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [ABHudViewController hudForView:view hide:YES];
    });
}

@end
