//
//  HomeViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 29/08/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MobileProvision.h"
#import "DropboxViewController.h"
#import "ShowLinkViewController.h"
#import "ProjectAdvancedViewController.h"

@interface HomeViewController : NSViewController <NSTabViewDelegate, ProjectAdvancedViewDelegate>{

    //Build & Upload IPA
    IBOutlet NSPathControl *selectedFilePath;
    IBOutlet NSButton *buttonAction;
    IBOutlet NSButton *buttonAdcanced;
    IBOutlet NSButton *buttonUniqueLink;
    __weak IBOutlet NSLayoutConstraint *buildOptionBoxHeightConstraint;
    
    //Mail and Shutdown
    IBOutlet NSTextField *textFieldEmail;
    IBOutlet NSTextField *textFieldMessage;
}

- (IBAction)actionButtonTapped:(NSButton *)sender;
- (IBAction)selectedFilePathHandler:(NSPathControl *)sender;
- (IBAction)buttonUniqueLinkTapped:(NSButton *)sender;
- (IBAction)buttonConfigCITapped:(NSButton *)sender;

- (IBAction)textFieldMailValueChanged:(NSTextField *)sender;
- (IBAction)textFieldDevMessageValueChanged:(NSTextField *)sender;


@end
