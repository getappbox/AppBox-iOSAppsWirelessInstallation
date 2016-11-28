//
//  HomeViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 29/08/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <DropboxOSX/DropboxOSX.h>
#import <ZipArchive/ZipArchive.h>

#import "Common.h"
#import "Constants.h"
#import "Tiny.h"
#import "GooglURLShortenerService.h"
#import "ShowLinkViewController.h"
#import "DropboxViewController.h"

typedef enum : NSUInteger {
    FileTypeIPA,
    FileTypeManifest
} FileType;

@interface HomeViewController : NSViewController <DBRestClientDelegate, DBSessionDelegate>{
    DBRestClient *restClient;
    IBOutlet NSTextField *labelIPAName;
    IBOutlet NSButton *buttonSelectIPAFile;
    
    IBOutlet NSButton *buttonShutdownMac;
    IBOutlet NSTextField *textFieldEmail;
    
    
    IBOutlet NSTextField *labelStatus;
    IBOutlet NSView *viewProgressStatus;
    IBOutlet NSProgressIndicator *progressIndicator;    
}

- (DBRestClient *)restClient;
- (IBAction)buttonSelectIPAFileTapped:(NSButton *)sender;

@end
