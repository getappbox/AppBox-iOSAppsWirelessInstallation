//
//  ABProvisionedDevice+CoreDataProperties.h
//  
//
//  Created by Vineet Choudhary on 11/10/18.
//
//

#import "ProvisionedDevice+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface ABProvisionedDevice (CoreDataProperties)

+ (NSFetchRequest<ABProvisionedDevice *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *deviceId;

@end

NS_ASSUME_NONNULL_END
