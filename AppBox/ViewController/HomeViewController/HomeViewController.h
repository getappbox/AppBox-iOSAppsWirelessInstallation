//
//  HomeViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 29/08/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ALOutputParser.h"
#import "XCArchiveParser.h"
#import "MobileProvision.h"
#import "CIViewController.h"
#import "DropboxViewController.h"
#import "ShowLinkViewController.h"
#import "ITCLoginViewController.h"
#import "ProjectAdvancedViewController.h"

@interface HomeViewController : NSViewController <NSTabViewDelegate, ProjectAdvancedViewDelegate, ITCLoginDelegate>{

    //Build & Upload IPA
    IBOutlet NSPathControl *selectedFilePath;
    IBOutlet NSComboBox *comboBuildScheme;
    IBOutlet NSComboBox *comboTeamId;
    IBOutlet NSComboBox *comboBuildType;
    IBOutlet NSButton *buttonAction;
    IBOutlet NSButton *buttonAdcanced;
    IBOutlet NSButton *buttonConfigCI;
    IBOutlet NSButton *buttonUniqueLink;
    __weak IBOutlet NSLayoutConstraint *buildOptionBoxHeightConstraint;
    
    //Mail and Shutdown
    IBOutlet NSButton *buttonSendMail;
    IBOutlet NSButton *buttonShutdownMac;
    IBOutlet NSTextField *textFieldEmail;
    IBOutlet NSTextField *textFieldMessage;
}

- (IBAction)actionButtonTapped:(NSButton *)sender;
- (IBAction)selectedFilePathHandler:(NSPathControl *)sender;
- (IBAction)buttonUniqueLinkTapped:(NSButton *)sender;
- (IBAction)buttonConfigCITapped:(NSButton *)sender;

- (IBAction)comboBuildSchemeValueChanged:(NSComboBox *)sender;
- (IBAction)comboTeamIdValueChanged:(NSComboBox *)sender;
- (IBAction)comboBuildTypeValueChanged:(NSComboBox *)sender;
- (IBAction)sendMailMacOptionValueChanged:(NSButton *)sender;
- (IBAction)sendMailOptionValueChanged:(NSButton *)sender;
- (IBAction)textFieldMailValueChanged:(NSTextField *)sender;
- (IBAction)textFieldDevMessageValueChanged:(NSTextField *)sender;


@end
