//
//  ABUploadRecord+CoreDataClass.h
//  
//
//  Created by Vineet Choudhary on 17/10/17.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ABProject;
@class ABProvisioningProfile;
@class AppBoxService;

NS_ASSUME_NONNULL_BEGIN

@interface ABUploadRecord : NSManagedObject

@property(nonatomic, retain) XCProject *xcProject;

@end

NS_ASSUME_NONNULL_END

#import "UploadRecord+CoreDataProperties.h"
