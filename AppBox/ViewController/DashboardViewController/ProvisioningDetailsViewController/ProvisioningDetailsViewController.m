//
//  ProvisioningDetailsViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 29/10/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "ProvisioningDetailsViewController.h"

@interface ProvisioningDetailsViewController ()

@end

@implementation ProvisioningDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //title label
    [labelTitle setStringValue:[NSString stringWithFormat:@"%@ - Provisioning Profile Details", self.uploadRecord.project.name]];
    
    //uuid, type, create & expiration date label
    [labelUUID setStringValue:self.uploadRecord.provisioningProfile.uuid];
    [labelCreationDate setStringValue:self.uploadRecord.provisioningProfile.createDate.string];
    [labelType setStringValue:self.uploadRecord.provisioningProfile.buildType.capitalizedString];
    [labelExpirationDate setStringValue:self.uploadRecord.provisioningProfile.expirationDate.string];
    
    //team label
    [labelTeam setStringValue:[NSString stringWithFormat:@"%@ - %@", self.uploadRecord.provisioningProfile.teamId, self.uploadRecord.provisioningProfile.teamName]];
    
    //device label
    if ([self.uploadRecord.provisioningProfile.buildType isEqualToString: BuildTypeEnterprise]){
        [labelProvisionedDevices setStringValue:[NSString stringWithFormat:@"∞ Devices"]];
    } else {
        NSNumber *totalDevices = [NSNumber numberWithInteger:self.uploadRecord.provisioningProfile.provisionedDevices.count];
        NSString *postFix = totalDevices.integerValue > 1 ? @"s" : @"";
        [labelProvisionedDevices setStringValue:[NSString stringWithFormat:@"%@ Device%@", totalDevices, postFix]];
    }
}


- (IBAction)copyAllDeviceUUIDTapped:(NSButton *)sender {
    NSMutableString *devices = [[NSMutableString alloc] init];
    [self.uploadRecord.provisioningProfile.provisionedDevices enumerateObjectsUsingBlock:^(ProvisionedDevice * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [devices appendFormat:@"%@,\n",obj.deviceId];
    }];
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:devices forType:NSStringPboardType];
    [MBProgressHUD showOnlyStatus:@"Copied!!" onView:self.view];
}

- (IBAction)closeButtonTapped:(NSButton *)sender {
    [self dismissController:self];
}


@end
