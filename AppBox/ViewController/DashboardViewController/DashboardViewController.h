//
//  DashboardViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 19/09/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Project+CoreDataClass.h"
#import "UploadRecord+CoreDataClass.h"

@interface DashboardViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>

@property (weak) IBOutlet NSTableView *dashboardTableView;
@end
