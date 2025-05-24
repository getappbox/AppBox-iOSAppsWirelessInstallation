//
//  ABProject+CoreDataProperties.h
//  
//
//  Created by Vineet Choudhary on 11/10/18.
//
//

#import "Project+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface ABProject (CoreDataProperties)

+ (NSFetchRequest<ABProject *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *bundleIdentifier;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, retain) NSOrderedSet<CISetting *> *ciSettings;
@property (nullable, nonatomic, retain) NSOrderedSet<ABUploadRecord *> *uploadRecords;

@end

@interface ABProject (CoreDataGeneratedAccessors)

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

- (void)insertObject:(ABUploadRecord *)value inUploadRecordsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromUploadRecordsAtIndex:(NSUInteger)idx;
- (void)insertUploadRecords:(NSArray<ABUploadRecord *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeUploadRecordsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInUploadRecordsAtIndex:(NSUInteger)idx withObject:(ABUploadRecord *)value;
- (void)replaceUploadRecordsAtIndexes:(NSIndexSet *)indexes withUploadRecords:(NSArray<ABUploadRecord *> *)values;
- (void)addUploadRecordsObject:(ABUploadRecord *)value;
- (void)removeUploadRecordsObject:(ABUploadRecord *)value;
- (void)addUploadRecords:(NSOrderedSet<ABUploadRecord *> *)values;
- (void)removeUploadRecords:(NSOrderedSet<ABUploadRecord *> *)values;

@end

NS_ASSUME_NONNULL_END
