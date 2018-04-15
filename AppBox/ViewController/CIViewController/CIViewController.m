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
    GitRepoDetails *repoDetails = [GitHandler getGitBranchesForProjectURL:[self.project.projectFullPath filePathURL]];
    if (repoDetails == nil){
        [Common showAlertWithTitle:@"Error" andMessage:@"Can't able to find vaild git repository."];
    }else if (repoDetails.branchs.count > 0){
        [comboBranch addItemsWithObjectValues:repoDetails.branchs];
    }else if (repoDetails.branchs.count == 0){
        [Common showAlertWithTitle:@"Error" andMessage:@"Can't able to find any branch in this git repository."];
    }
    
    [labelRepoPath setStringValue:repoDetails.path];
}

- (IBAction)buttonEnableCITapped:(NSButton *)sender {
    
}

- (IBAction)comboBranchValueChanged:(NSComboBox *)sender {
    [labelBranch setStringValue:sender.stringValue];
    [buttonEnableCI setEnabled:(sender.stringValue > 0)];
}

- (IBAction)buttonCancelTapped:(NSButton *)sender {
    [self dismissController:self];
}
@end
