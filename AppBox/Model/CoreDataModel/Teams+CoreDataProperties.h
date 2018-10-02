//
//  Teams+CoreDataProperties.h
//  
//
//  Created by Vineet Choudhary on 30/09/18.
//
//

#import "Teams+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Teams (CoreDataProperties)

+ (NSFetchRequest<Teams *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *about;
@property (nullable, nonatomic, copy) NSString *emails;
@property (nullable, nonatomic, copy) NSString *slackWebHookURL;
@property (nullable, nonatomic, copy) NSString *msTeamsWebHookURL;
@property (nullable, nonatomic, copy) NSString *hangoutWebHookURL;
@property (nullable, nonatomic, retain) NSSet<Project *> *projects;

@end

@interface Teams (CoreDataGeneratedAccessors)

- (void)addProjectsObject:(Project *)value;
- (void)removeProjectsObject:(Project *)value;
- (void)addProjects:(NSSet<Project *> *)values;
- (void)removeProjects:(NSSet<Project *> *)values;

@end

NS_ASSUME_NONNULL_END
