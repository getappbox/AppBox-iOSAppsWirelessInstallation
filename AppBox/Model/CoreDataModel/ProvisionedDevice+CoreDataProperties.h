//
//  ProvisionedDevice+CoreDataProperties.h
//  
//
//  Created by Vineet Choudhary on 29/10/17.
//
//

#import "ProvisionedDevice+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface ProvisionedDevice (CoreDataProperties)

+ (NSFetchRequest<ProvisionedDevice *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *deviceId;

@end

NS_ASSUME_NONNULL_END
