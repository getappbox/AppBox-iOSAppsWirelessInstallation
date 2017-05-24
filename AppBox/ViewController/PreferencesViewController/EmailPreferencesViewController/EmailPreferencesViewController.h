//
//  EmailPreferencesViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 28/03/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EmailPreferencesViewController : NSViewController {
    IBOutlet NSButton *saveButton;
    IBOutlet NSButton *testMailButton;
    
    IBOutlet NSTextField *emailTextField;
    IBOutlet NSTextField *personalMessageTextField;
}

- (IBAction)saveButtonTapped:(NSButton *)sender;
- (IBAction)sendTestMailButtonTapped:(NSButton *)sender;


@end
