//
//  ProjectAdvancedViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ProjectAdvancedViewController;
@protocol ProjectAdvancedViewDelegate <NSObject>

- (void)projectAdvancedSaveButtonTapped:(NSButton *)sender;
- (void)projectAdvancedCancelButtonTapped:(NSButton *)sender;

@end

@interface ProjectAdvancedViewController : NSViewController{
    IBOutlet NSPathControl *pathBuild;
    IBOutlet NSPathControl *pathXCode;
    IBOutlet NSTextField *textFieldUserName;
    IBOutlet NSSecureTextField *textFieldPassword;
}

@property(nonatomic, strong) XCProject *project;
@property(weak) id <ProjectAdvancedViewDelegate> delegate;

- (IBAction)buttonSaveTapped:(NSButton *)sender;
- (IBAction)buttonCancelTapped:(NSButton *)sender;
- (IBAction)buildPathHandler:(NSPathControl *)sender;
- (IBAction)xcodePathHandler:(NSPathControl *)sender;


@end
