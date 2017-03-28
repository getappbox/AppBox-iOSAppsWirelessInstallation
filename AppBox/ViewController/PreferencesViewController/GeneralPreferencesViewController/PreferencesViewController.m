//
//  PreferencesViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 27/03/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "PreferencesViewController.h"

@interface PreferencesViewController ()

@end

@implementation PreferencesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //set build url
    [pathBuild setURL:[UserData buildLocation]];
}

//Build Path Handler
- (IBAction)buildPathHandler:(NSPathControl *)sender {
    if ([[sender.URL.resourceSpecifier stringByRemovingPercentEncoding] containsString:@" "]){
        [Common showAlertWithTitle:@"Error" andMessage:[NSString stringWithFormat:@"Please select directory without any spaces.\n\n%@",[sender.URL.resourceSpecifier stringByRemovingPercentEncoding]]];
        [sender setURL:[UserData buildLocation]];
    }else{
        [UserData setBuildLocation:sender.URL];
    }
}

//Xcode Path Handler
- (IBAction)xcodePathHandler:(NSPathControl *)sender {
    
}

@end
