//
//  ShowLinkViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 07/09/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QRCodeViewController.h"
#import "Project+CoreDataClass.h"

@interface ShowLinkViewController : NSViewController{
    IBOutlet NSTextField *textFieldHint;
    IBOutlet NSTextField *textFieldAppLink;
    IBOutlet NSButton *buttonCopyToClipboard;
}

@property(nonatomic, strong) XCProject *project;

- (IBAction)buttonCloseTapped:(NSButton *)sender;
- (IBAction)buttonCopyToClipboardTapped:(NSButton *)sender;


@end
