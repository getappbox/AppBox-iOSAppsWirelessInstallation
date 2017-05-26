//
//  MBProgressHUD+ProgressHud.m
//  AppBox
//
//  Created by Vineet Choudhary on 18/05/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "MBProgressHUD+ProgressHud.h"

@implementation MBProgressHUD (ProgressHud)

+(MBProgressHUD *)hudForView:(NSView *)view {
    static NSMutableDictionary *hudDictionary = nil;
    if (hudDictionary == nil) {
        hudDictionary = [[NSMutableDictionary alloc] init];
    }
    MBProgressHUD *hud;
    if ([hudDictionary.allKeys containsObject:view.description]) {
        hud = [hudDictionary objectForKey:view.description];
    } else {
        hud = [[MBProgressHUD alloc] initWithView:view];
        [hudDictionary setObject:hud forKey:view.description];
    }
    if (![view.subviews containsObject:hud]) {
        [view addSubview:hud];
    }
    [hud setMargin: 10.f];
    [hud setYOffset: 0];
    [hud show:YES];
    return hud;
}

+(void)showStatus:(NSString *)status onView:(NSView *)view {
    MBProgressHUD *hud = [MBProgressHUD hudForView:view];
    [hud setMode:MBProgressHUDModeIndeterminate];
    [hud setLabelText: status];
}

+(void)showStatus:(NSString *)status witProgress:(double)progress onView:(NSView *)view {
    MBProgressHUD *hud = [MBProgressHUD hudForView:view];
    [hud setMode:MBProgressHUDModeDeterminate];
    [hud setProgress:progress];
    [hud setLabelText: status];
}

+(void)showStatus:(NSString *)status forSuccess:(BOOL)success onView:(NSView *)view {
    MBProgressHUD *hud = [MBProgressHUD hudForView:view];
    [hud setLabelText: status];
    [hud setMode: MBProgressHUDModeCustomView];
    
    NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, 37.0f, 37.0f)];
    NSImage *resultImage = success ? [NSImage imageNamed:@"Check"] : [NSImage imageNamed:@"Multiply"];
    [imageView setImage:resultImage];
    [hud setCustomView: imageView];

    [MBProgressHUD hideAllHudFromView:view after:2];
}

+(void)showOnlyStatus:(NSString *)status onView:(NSView *)view{
    MBProgressHUD *hud = [MBProgressHUD hudForView:view];
    [hud setMode: MBProgressHUDModeText];
    [hud setLabelText: status];
    [hud setMargin: 10.f];
    [hud setYOffset: 150.f];
    [MBProgressHUD hideAllHudFromView:view after:3];
}

+(void)hideAllHudFromView:(NSView *)view after:(NSTimeInterval)sec{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sec * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:view animated:YES];
    });
}

@end
