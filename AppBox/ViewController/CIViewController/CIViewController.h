//
//  CIViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 04/01/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CIViewController : NSViewController{
    IBOutlet NSButton *buttonCancel;
    IBOutlet NSButton *buttonEnableCI;
    IBOutlet NSComboBox *comboBranch;
}

@property (nonatomic, strong) XCProject *project;

- (IBAction)buttonCancelTapped:(NSButton *)sender;
- (IBAction)buttonEnableCITapped:(NSButton *)sender;
@end
