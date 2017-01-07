//
//  ProjectAdvancedViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ProjectAdvancedViewController : NSViewController{
    IBOutlet NSPathControl *pathBuild;
    IBOutlet NSComboBox *comboAppStoreTool;
    IBOutlet NSTextField *textFieldUserName;
    IBOutlet NSSecureTextField *textFieldPassword;
}

@property(nonatomic, strong) XCProject *project;

- (IBAction)buttonSaveTapped:(NSButton *)sender;
- (IBAction)buttonCancelTapped:(NSButton *)sender;
- (IBAction)buildPathHandler:(NSPathControl *)sender;


@end
