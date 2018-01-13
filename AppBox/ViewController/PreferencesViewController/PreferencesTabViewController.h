//
//  PreferencesTabViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 28/03/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CISettingViewController.h"
#import "PreferencesViewController.h"
#import "HelpPreferencesViewController.h"
#import "EmailPreferencesViewController.h"
#import "SlackPreferencesViewController.h"
#import "AccountPreferencesViewController.h"

@interface PreferencesTabViewController : NSTabViewController{
    
}

+ (void)presentPreferences;

@end
