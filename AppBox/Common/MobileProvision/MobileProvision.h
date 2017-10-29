//
//  MobileProvision.h
//  AppBox
//
//  Created by Vineet Choudhary on 16/02/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

#define BuildTypeUnknown @"unknown"
#define BuildTypeAdHoc @"ad-hoc"
#define BuildTypePackage @"package"
#define BuildTypeAppStore @"app-store"
#define BuildTypeEnterprise @"enterprise"
#define BuildTypeDevelopment @"development"
#define BuildTypeDeveloperId @"developer-id"

@interface MobileProvision : NSObject{
    NSDictionary *mobileProvision;
}

@property(nonatomic, assign) BOOL isValid;
@property(nonatomic, strong) NSString *uuid;
@property(nonatomic, strong) NSString *teamId;
@property(nonatomic, strong) NSString *teamName;
@property(nonatomic, strong) NSString *buildType;
@property(nonatomic, strong) NSDate *createDate;
@property(nonatomic, strong) NSDate *expirationDate;
@property(nonatomic, strong) NSArray<NSString *> *provisionedDevices;

- (instancetype)initWithPath:(NSString *)path;

@end
