//
//  ProvisioningProfile+CoreDataProperties.h
//  
//
//  Created by Vineet Choudhary on 30/09/18.
//
//

#import "ProvisioningProfile+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface ProvisioningProfile (CoreDataProperties)

+ (NSFetchRequest<ProvisioningProfile *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *buildType;
@property (nullable, nonatomic, copy) NSDate *createDate;
@property (nullable, nonatomic, copy) NSDate *expirationDate;
@property (nullable, nonatomic, copy) NSString *teamId;
@property (nullable, nonatomic, copy) NSString *teamName;
@property (nullable, nonatomic, copy) NSString *uuid;
@property (nullable, nonatomic, retain) NSOrderedSet<ProvisionedDevice *> *provisionedDevices;
@property (nullable, nonatomic, retain) NSOrderedSet<UploadRecord *> *uploadRecord;

@end

@interface ProvisioningProfile (CoreDataGeneratedAccessors)

- (void)insertObject:(ProvisionedDevice *)value inProvisionedDevicesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromProvisionedDevicesAtIndex:(NSUInteger)idx;
- (void)insertProvisionedDevices:(NSArray<ProvisionedDevice *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeProvisionedDevicesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInProvisionedDevicesAtIndex:(NSUInteger)idx withObject:(ProvisionedDevice *)value;
- (void)replaceProvisionedDevicesAtIndexes:(NSIndexSet *)indexes withProvisionedDevices:(NSArray<ProvisionedDevice *> *)values;
- (void)addProvisionedDevicesObject:(ProvisionedDevice *)value;
- (void)removeProvisionedDevicesObject:(ProvisionedDevice *)value;
- (void)addProvisionedDevices:(NSOrderedSet<ProvisionedDevice *> *)values;
- (void)removeProvisionedDevices:(NSOrderedSet<ProvisionedDevice *> *)values;

- (void)insertObject:(UploadRecord *)value inUploadRecordAtIndex:(NSUInteger)idx;
- (void)removeObjectFromUploadRecordAtIndex:(NSUInteger)idx;
- (void)insertUploadRecord:(NSArray<UploadRecord *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeUploadRecordAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInUploadRecordAtIndex:(NSUInteger)idx withObject:(UploadRecord *)value;
- (void)replaceUploadRecordAtIndexes:(NSIndexSet *)indexes withUploadRecord:(NSArray<UploadRecord *> *)values;
- (void)addUploadRecordObject:(UploadRecord *)value;
- (void)removeUploadRecordObject:(UploadRecord *)value;
- (void)addUploadRecord:(NSOrderedSet<UploadRecord *> *)values;
- (void)removeUploadRecord:(NSOrderedSet<UploadRecord *> *)values;

@end

NS_ASSUME_NONNULL_END
