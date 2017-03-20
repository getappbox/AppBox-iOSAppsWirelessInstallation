//
//  MobileProvision.m
//  AppBox
//
//  Created by Vineet Choudhary on 16/02/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "MobileProvision.h"

@implementation MobileProvision


+(NSString *) buildTypeForProvisioning:(NSString *)provisioningPath {
    NSDictionary *mobileProvision;
    NSString *binaryString = [NSString stringWithContentsOfFile:provisioningPath encoding:NSISOLatin1StringEncoding error:NULL];
    if (!binaryString) {
        return BuildTypeUnknown;
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:binaryString];
    BOOL ok = [scanner scanUpToString:@"<plist" intoString:nil];
    if (!ok) {
        NSLog(@"unable to find beginning of plist");
        return BuildTypeUnknown;
    }
    NSString *plistString;
    ok = [scanner scanUpToString:@"</plist>" intoString:&plistString];
    if (!ok) {
        NSLog(@"unable to find end of plist");
        return BuildTypeUnknown;
    }
    plistString = [NSString stringWithFormat:@"%@</plist>",plistString];
    
    NSData *plistdata_latin1 = [plistString dataUsingEncoding:NSISOLatin1StringEncoding];
    NSError *error = nil;
    mobileProvision = [NSPropertyListSerialization propertyListWithData:plistdata_latin1 options:NSPropertyListImmutable format:NULL error:&error];
    if (error) {
        NSLog(@"error parsing extracted plist — %@",error);
        return BuildTypeUnknown;
    }
    
    if (!mobileProvision) {
        return BuildTypeUnknown;
    } else if (![mobileProvision count]) {
        return BuildTypeDeveloperId;
    } else if ([[mobileProvision objectForKey:@"ProvisionsAllDevices"] boolValue]) {
        // enterprise distribution contains ProvisionsAllDevices - true
        return BuildTypeEnterprise;
    } else if ([mobileProvision objectForKey:@"ProvisionedDevices"] && [[mobileProvision objectForKey:@"ProvisionedDevices"] count] > 0) {
        NSDictionary *entitlements = [mobileProvision objectForKey:@"Entitlements"];
        // development contains UDIDs and get-task-allow is true
        // ad hoc contains UDIDs and get-task-allow is false
        if ([[entitlements objectForKey:@"get-task-allow"] boolValue]) {
            return BuildTypeDevelopment;
        } else {
            return BuildTypeAdHoc;
        }
    } else {
        // app store contains no UDIDs (if the file exists at all?)
        return BuildTypeAppStore;
    }
}

@end
