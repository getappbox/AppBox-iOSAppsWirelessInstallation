//
//  AccountPreferencesViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 28/03/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "AccountPreferencesViewController.h"

@interface AccountPreferencesViewController ()

@end

@implementation AccountPreferencesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)addAccountButtonTapped:(NSButton *)sender {
    SelectAccountViewController *selectAccountViewController = [[SelectAccountViewController alloc] initWithNibName:NSStringFromClass([SelectAccountViewController class]) bundle:nil];
    selectAccountViewController.delegate = self;
    [self presentViewControllerAsSheet:selectAccountViewController];
}

- (IBAction)deleteAccountButtonTapped:(NSButton *)sender {
    
}

#pragma mark - SelectAccountViewController Delegate
-(void)selectedAccountType:(AccountType)accountType{
    NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    switch (accountType) {
        case AccountTypeDropBox: {
            DropboxViewController *dropboxViewController = [storyBoard instantiateControllerWithIdentifier:NSStringFromClass([DropboxViewController class])];
            [self presentViewControllerAsSheet:dropboxViewController];
        }break;
            
        case AccountTypeITC: {
            ITCLoginViewController *itcLoginViewController = [storyBoard instantiateControllerWithIdentifier:NSStringFromClass([ITCLoginViewController class])];
            itcLoginViewController.delegate = self;
            [self presentViewControllerAsSheet:itcLoginViewController];
        }break;
    }
}

#pragma mark - ITCLoginViewController Delegate
-(void)itcLoginCanceled{
    
}

-(void)itcLoginResult:(BOOL)success{
    if (success) {
        
    }
}

@end
