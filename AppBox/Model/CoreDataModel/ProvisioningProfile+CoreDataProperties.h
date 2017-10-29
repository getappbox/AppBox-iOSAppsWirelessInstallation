//
//  ProvisioningProfile+CoreDataProperties.h
//  
//
//  Created by Vineet Choudhary on 29/10/17.
//
//

#import "ProvisioningProfile+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface ProvisioningProfile (CoreDataProperties)

+ (NSFetchRequest<ProvisioningProfile *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *uuid;
@property (nullable, nonatomic, copy) NSString *teamId;
@property (nullable, nonatomic, copy) NSString *teamName;
@property (nullable, nonatomic, copy) NSDate *expirationDate;
@property (nullable, nonatomic, copy) NSString *buildType;
@property (nullable, nonatomic, copy) NSDate *createDate;
@property (nullable, nonatomic, retain) NSOrderedSet<UploadRecord *> *uploadRecord;
@property (nullable, nonatomic, retain) NSOrderedSet<ProvisionedDevice *> *provisionedDevices;

@end

@interface ProvisioningProfile (CoreDataGeneratedAccessors)

- (void)addUploadRecordObject:(UploadRecord *)value;
- (void)removeUploadRecordObject:(UploadRecord *)value;
- (void)addUploadRecord:(NSOrderedSet<UploadRecord *> *)values;
- (void)removeUploadRecord:(NSOrderedSet<UploadRecord *> *)values;

- (void)addProvisionedDevicesObject:(ProvisionedDevice *)value;
- (void)removeProvisionedDevicesObject:(ProvisionedDevice *)value;
- (void)addProvisionedDevices:(NSOrderedSet<ProvisionedDevice *> *)values;
- (void)removeProvisionedDevices:(NSOrderedSet<ProvisionedDevice *> *)values;

@end

NS_ASSUME_NONNULL_END
