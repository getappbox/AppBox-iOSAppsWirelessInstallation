//
//  DropboxViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 28/11/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <DropboxOSX/DropboxOSX.h>

#import "Common.h"
#import "Constants.h"

@interface DropboxViewController : NSViewController <DBRestClientDelegate, DBSessionDelegate>{
    __weak IBOutlet NSButton *buttonConnectDropbox;
}

- (IBAction)buttonConnectDropboxTapped:(NSButton *)sender;

@end
