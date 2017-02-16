//
//  HomeViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 29/08/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ALOutputParser.h"
#import "MobileProvision.h"
#import "CIViewController.h"
#import "MailViewController.h"
#import "DropboxViewController.h"
#import "ShowLinkViewController.h"
#import "ProjectAdvancedViewController.h"

@interface HomeViewController : NSViewController <NSTabViewDelegate, MailDelegate, ProjectAdvancedViewDelegate>{
    //Tab
    IBOutlet NSTabView *tabView;
    
    //Build
    IBOutlet NSPathControl *pathProject;
    IBOutlet NSComboBox *comboBuildScheme;
    IBOutlet NSComboBox *comboTeamId;
    IBOutlet NSComboBox *comboBuildType;
    IBOutlet NSButton *buttonAction;
    IBOutlet NSButton *buttonAdcanced;
    IBOutlet NSButton *buttonConfigCI;
    
    //Upload IPA
    IBOutlet NSPathControl *pathIPAFile;
    IBOutlet NSTextField *textFieldBundleIdentifier;
    IBOutlet NSButton *buttonUniqueLink;
    
    //Mail and Shutdown
    IBOutlet NSButton *buttonSendMail;
    IBOutlet NSButton *buttonShutdownMac;
    IBOutlet NSTextField *textFieldEmail;
    IBOutlet NSTextField *textFieldMessage;
    
    //Status
    IBOutlet NSTextField *labelStatus;
    IBOutlet NSView *viewProgressStatus;
    IBOutlet NSProgressIndicator *progressIndicator;
}

- (IBAction)actionButtonTapped:(NSButton *)sender;
- (IBAction)projectPathHandler:(NSPathControl *)sender;
- (IBAction)ipaFilePathHandle:(NSPathControl *)sender;
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
