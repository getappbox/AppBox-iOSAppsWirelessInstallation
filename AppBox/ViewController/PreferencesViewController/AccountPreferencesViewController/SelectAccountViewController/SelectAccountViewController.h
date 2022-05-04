//
//  SelectAccountViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 05/02/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SelectAccountCellView.h"

typedef enum : NSUInteger {
    AccountTypeDropBox
} AccountType;

@protocol SelectAccountViewControllerDelegate <NSObject>
-(void)selectedAccountType:(AccountType)accountType;
@end

@interface SelectAccountViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource> {
    __weak IBOutlet NSTableView *accountTypeTableView;
    __weak IBOutlet NSButton *continueButton;
}

@property(nonatomic, weak) id<SelectAccountViewControllerDelegate> delegate;

- (IBAction)cancelButtonTapped:(NSButton *)sender;
- (IBAction)continueButtonTapped:(NSButton *)sender;

@end
