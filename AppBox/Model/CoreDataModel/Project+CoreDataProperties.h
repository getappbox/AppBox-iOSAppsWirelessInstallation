//
//  Project+CoreDataProperties.h
//  
//
//  Created by Vineet Choudhary on 30/09/18.
//
//

#import "Project+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Project (CoreDataProperties)

+ (NSFetchRequest<Project *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *bundleIdentifier;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, retain) NSOrderedSet<CISetting *> *ciSettings;
@property (nullable, nonatomic, retain) NSOrderedSet<UploadRecord *> *uploadRecords;
@property (nullable, nonatomic, retain) Teams *teams;

@end

@interface Project (CoreDataGeneratedAccessors)

- (void)insertObject:(CISetting *)value inCiSettingsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCiSettingsAtIndex:(NSUInteger)idx;
- (void)insertCiSettings:(NSArray<CISetting *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCiSettingsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCiSettingsAtIndex:(NSUInteger)idx withObject:(CISetting *)value;
- (void)replaceCiSettingsAtIndexes:(NSIndexSet *)indexes withCiSettings:(NSArray<CISetting *> *)values;
- (void)addCiSettingsObject:(CISetting *)value;
- (void)removeCiSettingsObject:(CISetting *)value;
- (void)addCiSettings:(NSOrderedSet<CISetting *> *)values;
- (void)removeCiSettings:(NSOrderedSet<CISetting *> *)values;

- (void)insertObject:(UploadRecord *)value inUploadRecordsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromUploadRecordsAtIndex:(NSUInteger)idx;
- (void)insertUploadRecords:(NSArray<UploadRecord *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeUploadRecordsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInUploadRecordsAtIndex:(NSUInteger)idx withObject:(UploadRecord *)value;
- (void)replaceUploadRecordsAtIndexes:(NSIndexSet *)indexes withUploadRecords:(NSArray<UploadRecord *> *)values;
- (void)addUploadRecordsObject:(UploadRecord *)value;
- (void)removeUploadRecordsObject:(UploadRecord *)value;
- (void)addUploadRecords:(NSOrderedSet<UploadRecord *> *)values;
- (void)removeUploadRecords:(NSOrderedSet<UploadRecord *> *)values;

@end

NS_ASSUME_NONNULL_END
