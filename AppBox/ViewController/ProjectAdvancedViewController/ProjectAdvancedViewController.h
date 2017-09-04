//
//  ProjectAdvancedViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LocalServerHandler.h"

@class ProjectAdvancedViewController;
@protocol ProjectAdvancedViewDelegate <NSObject>

- (void)projectAdvancedSaveButtonTapped:(NSButton *)sender;
- (void)projectAdvancedCancelButtonTapped:(NSButton *)sender;

@end

@interface ProjectAdvancedViewController : NSViewController{
    
}

@property(nonatomic, strong) XCProject *project;
@property(weak) id <ProjectAdvancedViewDelegate> delegate;

@property (weak) IBOutlet NSButton *localNetworkCheckBox;
@property (weak) IBOutlet NSTextField *dbFolderNameTextField;

- (IBAction)buttonSaveTapped:(NSButton *)sender;
- (IBAction)buttonCancelTapped:(NSButton *)sender;



@end
