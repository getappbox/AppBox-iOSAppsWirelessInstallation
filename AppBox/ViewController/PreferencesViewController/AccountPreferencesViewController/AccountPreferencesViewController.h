//
//  AccountPreferencesViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 28/03/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DropboxViewController.h"
#import "ITCLoginViewController.h"
#import "SelectAccountViewController.h"

@interface AccountPreferencesViewController : NSViewController <SelectAccountViewControllerDelegate, ITCLoginDelegate>{
    __weak IBOutlet NSTableView *accountTableView;
    __weak IBOutlet NSTextField *accountNameLabel;
    __weak IBOutlet NSTextField *accountIdLabel;
    __weak IBOutlet NSTextField *accountDescLabel;
    __weak IBOutlet NSButton *addAccountButton;
    __weak IBOutlet NSButton *deleteAccount;
}

- (IBAction)addAccountButtonTapped:(NSButton *)sender;
- (IBAction)deleteAccountButtonTapped:(NSButton *)sender;

@end
