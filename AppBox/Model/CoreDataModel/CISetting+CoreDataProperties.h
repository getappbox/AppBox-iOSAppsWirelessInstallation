//
//  CISetting+CoreDataProperties.h
//  
//
//  Created by Vineet Choudhary on 30/09/18.
//
//

#import "CISetting+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface CISetting (CoreDataProperties)

+ (NSFetchRequest<CISetting *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *branchName;
@property (nullable, nonatomic, copy) NSString *buildScheme;
@property (nullable, nonatomic, copy) NSString *buildType;
@property (nullable, nonatomic, copy) NSString *dbFolderName;
@property (nullable, nonatomic, copy) NSString *emailAddress;
@property (nullable, nonatomic, copy) NSNumber *keepSameLink;
@property (nullable, nonatomic, copy) NSString *personalMessage;
@property (nullable, nonatomic, copy) NSString *projectPath;
@property (nullable, nonatomic, copy) NSNumber *shutdownMac;
@property (nullable, nonatomic, copy) NSString *teamId;
@property (nullable, nonatomic, retain) Project *project;

@end

NS_ASSUME_NONNULL_END
