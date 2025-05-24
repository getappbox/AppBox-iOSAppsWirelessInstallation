//
//  UploadRecord+CoreDataProperties.h
//  
//
//  Created by Vineet Choudhary on 25/09/21.
//
//

#import "UploadRecord+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface ABUploadRecord (CoreDataProperties)

+ (NSFetchRequest<ABUploadRecord *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *build;
@property (nullable, nonatomic, copy) NSString *buildType;
@property (nullable, nonatomic, copy) NSDate *datetime;
@property (nullable, nonatomic, copy) NSString *dbAppInfoFullPath;
@property (nullable, nonatomic, copy) NSString *dbDirectroy;
@property (nullable, nonatomic, copy) NSString *dbFolderName;
@property (nullable, nonatomic, copy) NSString *dbIPAFullPath;
@property (nullable, nonatomic, copy) NSString *dbManifestFullPath;
@property (nullable, nonatomic, copy) NSString *dbSharedAppInfoURL;
@property (nullable, nonatomic, copy) NSString *dbSharedIPAURL;
@property (nullable, nonatomic, copy) NSString *dbSharedManifestURL;
@property (nullable, nonatomic, copy) NSNumber *keepSameLink;
@property (nullable, nonatomic, copy) NSString *localBuildPath;
@property (nullable, nonatomic, copy) NSString *mailURL;
@property (nullable, nonatomic, copy) NSString *projectPath;
@property (nullable, nonatomic, copy) NSString *shortURL;
@property (nullable, nonatomic, copy) NSString *teamId;
@property (nullable, nonatomic, copy) NSString *version;
@property (nullable, nonatomic, retain) ABProject *project;
@property (nullable, nonatomic, retain) ABProvisioningProfile *provisioningProfile;
@property (nullable, nonatomic, retain) AppBoxService *service;

@end

NS_ASSUME_NONNULL_END
