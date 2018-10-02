//
//  AddTeamViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 30/09/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface AddTeamViewController : NSViewController
@property (weak) IBOutlet NSTextField *teamNameTextField;
@property (weak) IBOutlet NSTextField *teamDescriptionTextField;
@property (weak) IBOutlet NSButton *cancelButton;
@property (weak) IBOutlet NSButton *addTeamButton;


- (IBAction)cancelButtonAction:(NSButton *)sender;
- (IBAction)addTeamButtonAction:(NSButton *)sender;

@end

NS_ASSUME_NONNULL_END
