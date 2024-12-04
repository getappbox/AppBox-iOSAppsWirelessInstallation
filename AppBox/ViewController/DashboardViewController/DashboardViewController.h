//
//  DashboardViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 19/09/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#import "QRCodeViewController.h"
#import "Project+CoreDataClass.h"
#import "UploadRecord+CoreDataClass.h"
#import "ProvisioningDetailsViewController.h"

@interface DashboardViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>{
    __weak IBOutlet NSLayoutConstraint *actionViewHeightConstraint;
}
@property (weak) IBOutlet NSView *openURLView;
@property (weak) IBOutlet NSView *cloneURLView;
@property (weak) IBOutlet NSView *showQRCodeView;
@property (weak) IBOutlet NSView *deleteBuildView;
@property (weak) IBOutlet NSView *provisioningProfileView;
@property (weak) IBOutlet NSView *showInFinderView;
@property (weak) IBOutlet NSView *showInDropboxView;

@property (weak) IBOutlet NSTableView *dashboardTableView;
@end
