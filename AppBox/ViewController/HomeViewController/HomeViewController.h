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
#import "Tiny.h"
#import "GooglURLShortenerService.h"

typedef enum : NSUInteger {
    FileTypeIPA,
    FileTypeManifest
} FileType;

@interface HomeViewController : NSViewController <DBRestClientDelegate, DBSessionDelegate>{
    DBRestClient *restClient;
}

@property (weak) IBOutlet NSButton *buttonLinkWithDropbox;
@property (weak) IBOutlet NSButton *buttonSelectIPAFile;
@property (weak) IBOutlet NSTextField *labelIPAName;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSTextField *labelStatus;
@property (weak) IBOutlet NSView *viewProgressStatus;
@property (weak) IBOutlet NSTextField *textFieldEmail;
@property (weak) IBOutlet NSTextField *textFieldEmailSubject;
@property (unsafe_unretained) IBOutlet NSTextView *textViewEmailContent;


- (DBRestClient *)restClient;
- (IBAction)buttonLinkWithDropboxTapped:(NSButton *)sender;
- (IBAction)buttonSelectIPAFileTapped:(NSButton *)sender;

@end
