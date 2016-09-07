//
//  ShowLinkViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 07/09/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

@interface ShowLinkViewController : NSViewController{
    IBOutlet NSTextField *textFieldAppLink;
    IBOutlet NSButton *buttonCopyToClipboard;
}

@property(nonatomic, strong) NSString *appLink;

- (IBAction)buttonCloseTapped:(NSButton *)sender;
- (IBAction)buttonCopyToClipboardTapped:(NSButton *)sender;


@end
