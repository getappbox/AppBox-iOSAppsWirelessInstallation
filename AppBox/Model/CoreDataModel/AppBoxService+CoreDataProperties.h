//
//  AppBoxService+CoreDataProperties.h
//  
//
//  Created by Vineet Choudhary on 25/09/21.
//
//

#import "AppBoxService+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface AppBoxService (CoreDataProperties)

+ (NSFetchRequest<AppBoxService *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *accountEmail;
@property (nullable, nonatomic, copy) NSString *accountId;
@property (nullable, nonatomic, copy) NSString *accountAccessKey;
@property (nullable, nonatomic, copy) NSString *baseURL;
@property (nullable, nonatomic, retain) NSString *accountSecretKey;
@property (nullable, nonatomic, retain) NSSet<ABUploadRecord *> *uploadRecords;

@end

@interface AppBoxService (CoreDataGeneratedAccessors)

- (void)addUploadRecordsObject:(ABUploadRecord *)value;
- (void)removeUploadRecordsObject:(ABUploadRecord *)value;
- (void)addUploadRecords:(NSSet<ABUploadRecord *> *)values;
- (void)removeUploadRecords:(NSSet<ABUploadRecord *> *)values;

@end

NS_ASSUME_NONNULL_END
