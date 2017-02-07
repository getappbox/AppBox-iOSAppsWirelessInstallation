//
//  Project+CoreDataProperties.h
//  
//
//  Created by Vineet Choudhary on 07/02/17.
//
//

#import "Project+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Project (CoreDataProperties)

+ (NSFetchRequest<Project *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *bundleIdentifier;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *projectPath;
@property (nullable, nonatomic, retain) NSSet<CISetting *> *ciSettings;
@property (nullable, nonatomic, retain) NSSet<UploadRecord *> *uploadRecords;

@end

@interface Project (CoreDataGeneratedAccessors)

- (void)addCiSettingsObject:(CISetting *)value;
- (void)removeCiSettingsObject:(CISetting *)value;
- (void)addCiSettings:(NSSet<CISetting *> *)values;
- (void)removeCiSettings:(NSSet<CISetting *> *)values;

- (void)addUploadRecordsObject:(UploadRecord *)value;
- (void)removeUploadRecordsObject:(UploadRecord *)value;
- (void)addUploadRecords:(NSSet<UploadRecord *> *)values;
- (void)removeUploadRecords:(NSSet<UploadRecord *> *)values;

@end

NS_ASSUME_NONNULL_END
