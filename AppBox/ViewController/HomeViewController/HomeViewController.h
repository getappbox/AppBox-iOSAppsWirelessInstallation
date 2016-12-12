//
//  HomeViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 29/08/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MailViewController.h"
#import "DropboxViewController.h"
#import "ShowLinkViewController.h"

@interface HomeViewController : NSViewController <DBRestClientDelegate, DBSessionDelegate>{
    //Dropbox
    DBRestClient *restClient;
    
    //Build
    IBOutlet NSPathControl *pathProject;
    IBOutlet NSPathControl *pathBuild;
    IBOutlet NSComboBox *comboBuildScheme;
    IBOutlet NSComboBox *comboTeamId;
    IBOutlet NSComboBox *comboBuildType;
    IBOutlet NSButton *buttonBuild;
    IBOutlet NSButton *buttonBuildAndUpload;
    
    //Upload IPA
    IBOutlet NSPathControl *pathIPAFile;
    
    //Mail and Shutdown
    IBOutlet NSButton *buttonShutdownMac;
    IBOutlet NSTextField *textFieldEmail;
    
    //Status
    IBOutlet NSTextField *labelStatus;
    IBOutlet NSView *viewProgressStatus;
    IBOutlet NSProgressIndicator *progressIndicator;    
}

- (DBRestClient *)restClient;
    
- (IBAction)buttonBuildTapped:(NSButton *)sender;
- (IBAction)buildPathHandler:(NSPathControl *)sender;
- (IBAction)projectPathHandler:(NSPathControl *)sender;
- (IBAction)ipaFilePathHandle:(NSPathControl *)sender;
- (IBAction)buttonBuildAndUploadTapped:(NSButton *)sender;
- (IBAction)comboBuildSchemeValueChanged:(NSComboBox *)sender;
- (IBAction)comboTeamIdValueChanged:(NSComboBox *)sender;
- (IBAction)comboBuildTypeValueChanged:(NSComboBox *)sender;
- (IBAction)sendMailMacOptionValueChanged:(NSButton *)sender;


@end
