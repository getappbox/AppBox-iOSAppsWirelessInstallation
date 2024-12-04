//
//  ABProvisioningProfile+CoreDataProperties.h
//  
//
//  Created by Vineet Choudhary on 11/10/18.
//
//

#import "ProvisioningProfile+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface ABProvisioningProfile (CoreDataProperties)

+ (NSFetchRequest<ABProvisioningProfile *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *buildType;
@property (nullable, nonatomic, copy) NSDate *createDate;
@property (nullable, nonatomic, copy) NSDate *expirationDate;
@property (nullable, nonatomic, copy) NSString *teamId;
@property (nullable, nonatomic, copy) NSString *teamName;
@property (nullable, nonatomic, copy) NSString *uuid;
@property (nullable, nonatomic, retain) NSOrderedSet<ABProvisionedDevice *> *provisionedDevices;
@property (nullable, nonatomic, retain) NSOrderedSet<ABUploadRecord *> *uploadRecord;

@end

@interface ABProvisioningProfile (CoreDataGeneratedAccessors)

- (void)insertObject:(ABProvisionedDevice *)value inProvisionedDevicesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromProvisionedDevicesAtIndex:(NSUInteger)idx;
- (void)insertProvisionedDevices:(NSArray<ABProvisionedDevice *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeProvisionedDevicesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInProvisionedDevicesAtIndex:(NSUInteger)idx withObject:(ABProvisionedDevice *)value;
- (void)replaceProvisionedDevicesAtIndexes:(NSIndexSet *)indexes withProvisionedDevices:(NSArray<ABProvisionedDevice *> *)values;
- (void)addProvisionedDevicesObject:(ABProvisionedDevice *)value;
- (void)removeProvisionedDevicesObject:(ABProvisionedDevice *)value;
- (void)addProvisionedDevices:(NSOrderedSet<ABProvisionedDevice *> *)values;
- (void)removeProvisionedDevices:(NSOrderedSet<ABProvisionedDevice *> *)values;

- (void)insertObject:(ABUploadRecord *)value inUploadRecordAtIndex:(NSUInteger)idx;
- (void)removeObjectFromUploadRecordAtIndex:(NSUInteger)idx;
- (void)insertUploadRecord:(NSArray<ABUploadRecord *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeUploadRecordAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInUploadRecordAtIndex:(NSUInteger)idx withObject:(ABUploadRecord *)value;
- (void)replaceUploadRecordAtIndexes:(NSIndexSet *)indexes withUploadRecord:(NSArray<ABUploadRecord *> *)values;
- (void)addUploadRecordObject:(ABUploadRecord *)value;
- (void)removeUploadRecordObject:(ABUploadRecord *)value;
- (void)addUploadRecord:(NSOrderedSet<ABUploadRecord *> *)values;
- (void)removeUploadRecord:(NSOrderedSet<ABUploadRecord *> *)values;

@end

NS_ASSUME_NONNULL_END
