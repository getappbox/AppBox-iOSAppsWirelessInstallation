//
//  SelectAccountViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 05/02/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import "SelectAccountViewController.h"

@implementation SelectAccountViewController{
    NSArray *accounts;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    accounts = @[@"Add Dropbox Account"];
}

//MARK: - NSTableView Datasource and Delegate
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return accounts.count;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    SelectAccountCellView *cell = [tableView makeViewWithIdentifier:@"AccountName" owner:self];
    [cell.accountNameLabel setStringValue:[accounts objectAtIndex:row]];
    return cell;
}

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row{
    return YES;
}

//MARK: - Actions
- (IBAction)cancelButtonTapped:(NSButton *)sender {
    [self dismissController:self];
}

- (IBAction)continueButtonTapped:(NSButton *)sender {
    [self dismissController:self];
    [self.delegate selectedAccountType:[accountTypeTableView selectedRow]];
}


@end
