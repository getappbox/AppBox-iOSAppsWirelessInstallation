//
//  CIViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 04/01/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GitHandler.h"

@interface CIViewController : NSViewController{
    IBOutlet NSButton *buttonCancel;
    IBOutlet NSButton *buttonEnableCI;
    IBOutlet NSComboBox *comboBranch;
    
    IBOutlet NSTextField *labelRepoPath;
    IBOutlet NSTextField *labelBranch;
    IBOutlet NSTextField *labelBuildOn;
}

@property (nonatomic, strong) XCProject *project;

- (IBAction)buttonCancelTapped:(NSButton *)sender;
- (IBAction)buttonEnableCITapped:(NSButton *)sender;
- (IBAction)comboBranchValueChanged:(NSComboBox *)sender;
@end
