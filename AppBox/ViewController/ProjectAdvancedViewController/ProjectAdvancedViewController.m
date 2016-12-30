//
//  ProjectAdvancedViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "ProjectAdvancedViewController.h"

@interface ProjectAdvancedViewController ()

@end

@implementation ProjectAdvancedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [pathBuild setURL:self.project.buildDirectory];
}

- (IBAction)buttonCancelTapped:(NSButton *)sender {
    [self dismissController:self];
}

- (IBAction)buttonSaveTapped:(NSButton *)sender {
    [UserData setBuildLocation:self.project.buildDirectory];
    [self dismissController:self];
}


//Build Path Handler
- (IBAction)buildPathHandler:(NSPathControl *)sender {
    if (![self.project.buildDirectory isEqualTo:sender.URL]){
        [self.project setBuildDirectory: sender.URL];
    }
}
@end
