//
//  PreferencesTabViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 28/03/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "PreferencesTabViewController.h"

@interface PreferencesTabViewController ()

@end

@implementation PreferencesTabViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)viewWillAppear {
    [super viewWillAppear];
    [self setTabStyle:NSTabViewControllerTabStyleToolbar];
    [self.tabView setControlSize:NSControlSizeRegular];
    [self setTitle:@"AppBox Preferences"];
    
    //General Preferences
    PreferencesViewController *preferencesViewController = [[PreferencesViewController alloc] initWithNibName:NSStringFromClass([PreferencesViewController class]) bundle:nil];
    
    NSTabViewItem *generalPreferencesTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:@"general"];
    [generalPreferencesTabViewItem setLabel:@"General"];
    [generalPreferencesTabViewItem setImage:[NSImage imageNamed:@"BlueSetting"]];
    [generalPreferencesTabViewItem setViewController:preferencesViewController];
    [self addTabViewItem:generalPreferencesTabViewItem];
    
    //Accounts Preferences
    AccountPreferencesViewController *accountPreferencesViewController = [[AccountPreferencesViewController alloc] initWithNibName:NSStringFromClass([AccountPreferencesViewController class]) bundle:nil];
    
    NSTabViewItem *accountPreferencesTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:@"accounts"];
    [accountPreferencesTabViewItem setLabel:@"Accounts"];
    [accountPreferencesTabViewItem setImage:[NSImage imageNamed:@"BlueAccount"]];
    [accountPreferencesTabViewItem setViewController:accountPreferencesViewController];
    
    //[self addTabViewItem:accountPreferencesTabViewItem];
    
    //Mail Preferences
    EmailPreferencesViewController *emailPreferencesViewController = [[EmailPreferencesViewController alloc] initWithNibName:NSStringFromClass([EmailPreferencesViewController class]) bundle:nil];
    
    NSTabViewItem *emailPreferencesTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:@"email"];
    [emailPreferencesTabViewItem setLabel:@"Email"];
    [emailPreferencesTabViewItem setImage:[NSImage imageNamed:@"BlueEmail"]];
    [emailPreferencesTabViewItem setViewController:emailPreferencesViewController];
    
    [self addTabViewItem:emailPreferencesTabViewItem];
    
    //Slack Preferences
    SlackPreferencesViewController *slackPreferencesViewController = [[SlackPreferencesViewController alloc] initWithNibName:NSStringFromClass([SlackPreferencesViewController class]) bundle:nil];
    
    NSTabViewItem *slackPreferencesTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:@"slack"];
    [slackPreferencesTabViewItem setLabel:@"Slack"];
    [slackPreferencesTabViewItem setImage:[NSImage imageNamed:@"SlackLogo"]];
    [slackPreferencesTabViewItem setViewController:slackPreferencesViewController];
    
    [self addTabViewItem:slackPreferencesTabViewItem];
    
    //CI Setting Preferences
    CISettingViewController *ciSettingViewController = [[CISettingViewController alloc] initWithNibName:NSStringFromClass([CISettingViewController class]) bundle:nil];
    
    NSTabViewItem *ciPreferencesTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:@"ci"];
    [ciPreferencesTabViewItem setLabel:@"CI Setting"];
    [ciPreferencesTabViewItem setImage:[NSImage imageNamed:@"BlueHelp"]];
    [ciPreferencesTabViewItem setViewController:ciSettingViewController];
    
    [self addTabViewItem:ciPreferencesTabViewItem];
    
    //Help Preferences
    HelpPreferencesViewController *helpPreferencesViewController = [[HelpPreferencesViewController alloc] initWithNibName:NSStringFromClass([HelpPreferencesViewController class]) bundle:nil];
    
    NSTabViewItem *helpPreferencesTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:@"help"];
    [helpPreferencesTabViewItem setLabel:@"Help"];
    [helpPreferencesTabViewItem setImage:[NSImage imageNamed:@"BlueHelp"]];
    [helpPreferencesTabViewItem setViewController:helpPreferencesViewController];
    
    //[self addTabViewItem:helpPreferencesTabViewItem];
    
}

+ (void)presentPreferences {
    PreferencesTabViewController *pref = [[PreferencesTabViewController alloc] initWithNibName:NSStringFromClass([PreferencesTabViewController class]) bundle:nil];
    [[NSApplication sharedApplication].keyWindow.contentViewController presentViewControllerAsModalWindow:pref];
}

@end
