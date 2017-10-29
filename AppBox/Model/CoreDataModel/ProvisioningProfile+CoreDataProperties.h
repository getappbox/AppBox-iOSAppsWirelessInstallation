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
@property (nullable, nonatomic, copy) NSString *expirationDate;
@property (nullable, nonatomic, copy) NSString *buildType;
@property (nullable, nonatomic, copy) NSString *createDate;
@property (nullable, nonatomic, retain) NSSet<UploadRecord *> *uploadRecord;
@property (nullable, nonatomic, retain) NSSet<ProvisionedDevice *> *provisionedDevices;

@end

@interface ProvisioningProfile (CoreDataGeneratedAccessors)

- (void)addUploadRecordObject:(UploadRecord *)value;
- (void)removeUploadRecordObject:(UploadRecord *)value;
- (void)addUploadRecord:(NSSet<UploadRecord *> *)values;
- (void)removeUploadRecord:(NSSet<UploadRecord *> *)values;

- (void)addProvisionedDevicesObject:(ProvisionedDevice *)value;
- (void)removeProvisionedDevicesObject:(ProvisionedDevice *)value;
- (void)addProvisionedDevices:(NSSet<ProvisionedDevice *> *)values;
- (void)removeProvisionedDevices:(NSSet<ProvisionedDevice *> *)values;

@end

NS_ASSUME_NONNULL_END
