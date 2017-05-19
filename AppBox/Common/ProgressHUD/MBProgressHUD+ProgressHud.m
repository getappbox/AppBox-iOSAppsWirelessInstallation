//
//  MBProgressHUD+ProgressHud.m
//  AppBox
//
//  Created by Vineet Choudhary on 18/05/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "MBProgressHUD+ProgressHud.h"

@implementation MBProgressHUD (ProgressHud)


+(void)showStatus:(NSString *)status onView:(NSView *)view {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    [hud setLabelText: status];
}

+(void)showStatus:(NSString *)status witProgress:(double)progress onView:(NSView *)view {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    [hud setProgress:progress];
    [hud setLabelText: status];
}

+(void)showStatus:(NSString *)status forSuccess:(BOOL)success onView:(NSView *)view {
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:view];
    [view addSubview:hud];
    [hud setLabelText: status];
    
    hud.customView = [[NSImageView alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, 37.0f, 37.0f)];
    NSImage *img = success ? [NSImage imageNamed:@"Check"] : [NSImage imageNamed:@"Multiply"];
    [(NSImageView *)hud.customView setImage:img];

    [hud setMode: MBProgressHUDModeCustomView];
    [hud show:YES];
}

+(void)showOnlyStatus:(NSString *)status onView:(NSView *)view{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = status;
    hud.margin = 10.f;
    hud.yOffset = 150.f;
    hud.removeFromSuperViewOnHide = YES;
    [MBProgressHUD hideAllHudFromView:view after:3];
}

+(void)hideAllHudFromView:(NSView *)view after:(NSTimeInterval)sec{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sec * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:view animated:YES];
    });
}

@end
