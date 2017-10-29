//
//  MobileProvision.m
//  AppBox
//
//  Created by Vineet Choudhary on 16/02/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "MobileProvision.h"


@implementation MobileProvision {
    
}

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        NSString *binaryString = [NSString stringWithContentsOfFile:path encoding:NSISOLatin1StringEncoding error:NULL];
        if (!binaryString) {
        }
        
        NSScanner *scanner = [NSScanner scannerWithString:binaryString];
        BOOL ok = [scanner scanUpToString:@"<plist" intoString:nil];
        if (!ok) {
            NSLog(@"unable to find beginning of plist");
        }
        NSString *plistString;
        ok = [scanner scanUpToString:@"</plist>" intoString:&plistString];
        if (!ok) {
            NSLog(@"unable to find end of plist");
        }
        plistString = [NSString stringWithFormat:@"%@</plist>",plistString];
        
        NSData *plistdata_latin1 = [plistString dataUsingEncoding:NSISOLatin1StringEncoding];
        NSError *error = nil;
        mobileProvision = [NSPropertyListSerialization propertyListWithData:plistdata_latin1 options:NSPropertyListImmutable format:NULL error:&error];
        self.isValid = (mobileProvision != nil);
        if (error) {
            NSLog(@"error parsing extracted plist — %@",error);
            return self;
        }
        
        if(mobileProvision){
            //Get Build Type
            if (![mobileProvision count]) {
                self.buildType = BuildTypeDeveloperId;
            } else if ([[mobileProvision objectForKey:@"ProvisionsAllDevices"] boolValue]) {
                // enterprise distribution contains ProvisionsAllDevices - true
                self.buildType =  BuildTypeEnterprise;
            } else if ([mobileProvision objectForKey:@"ProvisionedDevices"] && [((NSArray *)[mobileProvision objectForKey:@"ProvisionedDevices"]) count] > 0) {
                NSDictionary *entitlements = [mobileProvision objectForKey:@"Entitlements"];
                // development contains UDIDs and get-task-allow is true
                // ad hoc contains UDIDs and get-task-allow is false
                if ([[entitlements objectForKey:@"get-task-allow"] boolValue]) {
                    self.buildType =  BuildTypeDevelopment;
                } else {
                    self.buildType =  BuildTypeAdHoc;
                }
            } else {
                // app store contains no UDIDs (if the file exists at all?)
                self.buildType =  BuildTypeAppStore;
            }
            
            //Get TeamId
            if ([mobileProvision objectForKey:@"TeamIdentifier"]) {
                NSArray *teamIds = [mobileProvision objectForKey:@"TeamIdentifier"];
                if (teamIds.count > 0) {
                    self.teamId = teamIds.firstObject;
                }
            }
            
            //Get TeamName
            if ([mobileProvision objectForKey:@"TeamName"]) {
                self.teamName = [mobileProvision objectForKey:@"TeamName"];
            }
            
            //Get UUID
            if ([mobileProvision objectForKey:@"UUID"]){
                self.uuid = [mobileProvision objectForKey:@"UUID"];
            }
            
            //Get ProvisionedDevices
            if ([mobileProvision objectForKey:@"ProvisionedDevices"]){
                self.provisionedDevices = [mobileProvision objectForKey:@"ProvisionedDevices"];
            }
            
            
            //Get CreationDate
            if ([mobileProvision objectForKey:@"CreationDate"]){
                self.createDate = [mobileProvision objectForKey:@"CreationDate"];
            }
            
            //Get ExpirationDate
            if ([mobileProvision objectForKey:@"ExpirationDate"]){
                self.expirationDate = [mobileProvision objectForKey:@"ExpirationDate"];
            }
        }
        
    }
    return self;
}







@end
