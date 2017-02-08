//
//  CIViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 04/01/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "CIViewController.h"

@implementation CIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewWillAppear{
    [super viewWillAppear];
    GitRepoDetails *repoDetails = [GitHandler getGitBranchesForProjectURL:[self.project.fullPath filePathURL]];
    if (repoDetails == nil){
        [Common showAlertWithTitle:@"Error" andMessage:@"Can't able to find vaild git repository."];
    }else if (repoDetails.branchs.count > 0){
        [comboBranch addItemsWithObjectValues:repoDetails.branchs];
    }else if (repoDetails.branchs.count == 0){
        [Common showAlertWithTitle:@"Error" andMessage:@"Can't able to find any branch in this git repository."];
    }
}

- (IBAction)buttonEnableCITapped:(NSButton *)sender {
    
}

- (IBAction)buttonCancelTapped:(NSButton *)sender {
    [self dismissController:self];
}
@end
