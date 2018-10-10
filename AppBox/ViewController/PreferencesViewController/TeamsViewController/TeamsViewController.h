//
//  TeamsViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 30/09/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AddTeamViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TeamsViewController : NSViewController <AddTeamViewControllerDelegate>

@property (weak) IBOutlet NSTextField *teamNameLabel;
@property (weak) IBOutlet NSTableView *teamTableView;

- (IBAction)AddTeamAction:(NSButton *)sender;
- (IBAction)RemoveTeamAction:(NSButton *)sender;

@end

NS_ASSUME_NONNULL_END
