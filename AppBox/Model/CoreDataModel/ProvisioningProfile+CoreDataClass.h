//
//  ProvisioningProfile+CoreDataClass.h
//  
//
//  Created by Vineet Choudhary on 29/10/17.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ProvisionedDevice, UploadRecord;

NS_ASSUME_NONNULL_BEGIN

@interface ProvisioningProfile : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "ProvisioningProfile+CoreDataProperties.h"
