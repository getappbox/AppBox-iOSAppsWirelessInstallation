//
//  HomeViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 29/08/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ShowLinkViewController.h"
#import "DropboxViewController.h"

typedef enum : NSUInteger {
    FileTypeIPA,
    FileTypeManifest
} FileType;

typedef enum : NSUInteger {
    ScriptTypeGetScheme,
    ScriptTypeTeamId,
    ScriptTypeBuild,
} ScriptType;

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

@end
