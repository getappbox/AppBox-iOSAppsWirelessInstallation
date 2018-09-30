//
//  AddTeamViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/09/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import "AddTeamViewController.h"

@interface AddTeamViewController ()

@end

@implementation AddTeamViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)cancelButtonAction:(NSButton *)sender {
    [self dismissController:self];
}

- (IBAction)addTeamButtonAction:(NSButton *)sender {
    if (self.teamNameTextField.stringValue.isEmpty)
    {
        [Common showAlertWithTitle:@"Error" andMessage:@"Please enter a valid team name."];
        return;
    }
    
}
@end
