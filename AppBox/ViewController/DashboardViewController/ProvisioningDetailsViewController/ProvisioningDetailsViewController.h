//
//  ProvisioningDetailsViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 29/10/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Project+CoreDataProperties.h"
#import "ProvisionedDevice+CoreDataProperties.h"

@interface ProvisioningDetailsViewController : NSViewController{
    
    __weak IBOutlet NSTextField *labelTitle;
    __weak IBOutlet NSTextField *labelUUID;
    __weak IBOutlet NSTextField *labelTeam;
    __weak IBOutlet NSTextField *labelType;
    __weak IBOutlet NSTextField *labelCreationDate;
    __weak IBOutlet NSTextField *labelExpirationDate;
    __weak IBOutlet NSTextField *labelProvisionedDevices;
}

@property(nonatomic, strong) ABUploadRecord *uploadRecord;

@end
