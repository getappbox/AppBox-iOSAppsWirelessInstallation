//
//  TeamsViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/09/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import "TeamsViewController.h"

@interface TeamsViewController ()

@end

@implementation TeamsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

- (IBAction)AddTeamAction:(NSButton *)sender {
    AddTeamViewController *addTeamViewController = [[AddTeamViewController alloc] initWithNibName:NSStringFromClass([AddTeamViewController class]) bundle:nil];
    [self presentViewControllerAsSheet:addTeamViewController];
}

- (IBAction)RemoveTeamAction:(NSButton *)sender {

}

@end
