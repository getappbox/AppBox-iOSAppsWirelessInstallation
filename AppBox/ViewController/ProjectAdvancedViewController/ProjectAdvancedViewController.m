//
//  ProjectAdvancedViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "ProjectAdvancedViewController.h"

@implementation ProjectAdvancedViewController{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [Common logScreen:@"Project Advanced Settings"];
    NSString *xcodePath = [UserData xCodeLocation];
    if ([[NSFileManager defaultManager] fileExistsAtPath:xcodePath]){
        [pathXCode setURL: [NSURL URLWithString:xcodePath]];
    }
    [pathXCode setEnabled:NO];
    [pathBuild setURL:self.project.buildDirectory];
}

//MARK: - Action Button Tapped
- (IBAction)buttonCancelTapped:(NSButton *)sender {
    [self dismissController:self];
    [self.delegate projectAdvancedCancelButtonTapped:sender];
}

- (IBAction)buttonSaveTapped:(NSButton *)sender {
    [UserData setBuildLocation:self.project.buildDirectory];
    
    //set xcode and application loader path
    if (pathXCode.URL.isFileURL){
        [self.project setXcodePath:[pathXCode.URL.filePathURL resourceSpecifier]];
    }else{
        [self.project setXcodePath: pathXCode.URL.absoluteString];
    }
    [self.project setAlPath: [[self.project.xcodePath stringByAppendingPathComponent:abApplicationLoaderLocation] stringByRemovingPercentEncoding]];
    
    //set xcode location
    [UserData setXCodeLocation:self.project.xcodePath];
    
    if (self.delegate != nil){
        [self.delegate projectAdvancedSaveButtonTapped:sender];
    }
    
    [self dismissController:self];
}


//Build Path Handler
- (IBAction)buildPathHandler:(NSPathControl *)sender {
    if (![self.project.buildDirectory isEqualTo:sender.URL]){
        if ([[sender.URL.resourceSpecifier stringByRemovingPercentEncoding] containsString:@" "]){
            [Common showAlertWithTitle:@"Error" andMessage:[NSString stringWithFormat:@"Please select directory without any spaces.\n\n%@",[sender.URL.resourceSpecifier stringByRemovingPercentEncoding]]];
            [sender setURL:self.project.buildDirectory];
        }else{
            [self.project setBuildDirectory: sender.URL];
        }
    }
}

//Xcode Path Handler
- (IBAction)xcodePathHandler:(NSPathControl *)sender {

}
@end
