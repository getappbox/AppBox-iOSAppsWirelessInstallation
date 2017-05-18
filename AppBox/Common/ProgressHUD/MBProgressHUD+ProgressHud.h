//
//  MBProgressHUD+ProgressHud.h
//  AppBox
//
//  Created by Vineet Choudhary on 18/05/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "MBProgressHUD.h"

@interface MBProgressHUD (ProgressHud)

+(void)showStatus:(NSString *)status onView:(NSView *)view;
+(void)showStatus:(NSString *)status forSuccess:(BOOL)success onView:(NSView *)view;
+(void)showStatus:(NSString *)status witProgress:(double)progress onView:(NSView *)view;

@end
