//
//  DropboxViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 28/11/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DropboxViewController : NSViewController{
    __weak IBOutlet NSButton *buttonConnectDropbox;
}

- (IBAction)buttonConnectDropboxTapped:(NSButton *)sender;

@end
