//
//  Project+CoreDataClass.m
//  
//
//  Created by Vineet Choudhary on 17/10/17.
//
//

#import "Project+CoreDataClass.h"

@implementation Project

+(Project *)addProjectWithXCProject:(XCProject *)xcProject{
    
    @try {
        //fetch existing project with same identifer (if any)
        NSError *error;
        NSFetchRequest *fetchRequest = [Project fetchRequest];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"SELF.bundleIdentifier = %@", xcProject.identifer]];
        NSArray *projects = [[[AppDelegate appDelegate] managedObjectContext] executeFetchRequest:fetchRequest error:&error];
        if (error){
            //error in fetch request
            [Common showAlertWithTitle:@"Error" andMessage:error.localizedDescription];
        }else{
            Project *project;
            if (projects.count > 0){
                //use existing project
                project = [projects lastObject];
            }else{
                //create new project
                project = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Project class]) inManagedObjectContext:[[AppDelegate appDelegate] managedObjectContext]];
                [project setBundleIdentifier:xcProject.identifer];
            }
            
            //set other project properties
            [project setName:xcProject.name];
            
            //create new upload record
            UploadRecord *uploadRecord = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([UploadRecord class]) inManagedObjectContext:[[AppDelegate appDelegate] managedObjectContext]];
            
            //set upload details
            if (xcProject.buildType){
                [uploadRecord setBuildType:xcProject.buildType];
            }
            if (xcProject.dbAppInfoJSONFullPath){
                [uploadRecord setDbAppInfoFullPath:xcProject.dbAppInfoJSONFullPath.absoluteString];
            }
            if (xcProject.dbDirectory){
                [uploadRecord setDbDirectroy:xcProject.dbDirectory.absoluteString];
                NSArray *pathComponents = [xcProject.dbDirectory pathComponents];
                if (pathComponents.count > 1) {
                    [uploadRecord setDbFolderName:[NSString stringWithFormat:@"%@%@", pathComponents[0], pathComponents[1]]];
                }
            }
            if (xcProject.dbIPAFullPath){
                [uploadRecord setDbIPAFullPath:xcProject.dbIPAFullPath.absoluteString];
            }
            if (xcProject.dbManifestFullPath){
                [uploadRecord setDbManifestFullPath:xcProject.dbManifestFullPath.absoluteString];
            }
            //[uploadRecord setDbSharedAppInfoURL:xcProject.ipaFileDBShareableURL.absoluteString];
            if (xcProject.ipaFileDBShareableURL){
                [uploadRecord setDbSharedIPAURL:xcProject.ipaFileDBShareableURL.absoluteString];
            }
            if (xcProject.manifestFileSharableURL){
                [uploadRecord setDbSharedManifestURL:xcProject.manifestFileSharableURL.absoluteString];
            }
            
            if (xcProject.ipaFullPath){
                [uploadRecord setLocalBuildPath:[xcProject.ipaFullPath.resourceSpecifier stringByRemovingPercentEncoding]];
            }
            if (xcProject.appShortShareableURL){
                [uploadRecord setShortURL:xcProject.appShortShareableURL.stringValue];
            }
            if (xcProject.build){
                [uploadRecord setBuild:xcProject.build];
            }
            if (xcProject.version){
                [uploadRecord setVersion:xcProject.version];
            }
            
            [uploadRecord setKeepSameLink:[NSNumber numberWithBool:xcProject.isKeepSameLinkEnabled]];
            [uploadRecord setDatetime:[NSDate date]];
            
            if (xcProject.mobileProvision){
                @try {
                    //check either existing provisioning profile already exist or not
                    NSFetchRequest *provisioningProfileFetchRequest = [ProvisioningProfile fetchRequest];
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uuid = %@", xcProject.mobileProvision.uuid];
                    [provisioningProfileFetchRequest setPredicate:predicate];
                    NSArray *fetchedResult = [[[AppDelegate appDelegate] managedObjectContext] executeFetchRequest:provisioningProfileFetchRequest error:nil];
                    
                    if (fetchedResult.count > 0 && [fetchedResult.firstObject isKindOfClass:[ProvisioningProfile class]]) {
                        //if provisioning profile exist update records
                        ProvisioningProfile *provisioningProfile = (ProvisioningProfile *)fetchedResult.firstObject;
                        [provisioningProfile addUploadRecordObject:uploadRecord];
                        [uploadRecord setProvisioningProfile:provisioningProfile];
                    } else {
                        //Create new provisioning profile record
                        NSMutableOrderedSet<ProvisionedDevice *> *provisionDeviceSet = [[NSMutableOrderedSet<ProvisionedDevice *> alloc] init];
                        [xcProject.mobileProvision.provisionedDevices enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            //Create ProvisionedDevice Object and Add into Set
                            ProvisionedDevice *device = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([ProvisionedDevice class]) inManagedObjectContext:[[AppDelegate appDelegate] managedObjectContext]];
                            [device setDeviceId:obj];
                            [provisionDeviceSet addObject:device];
                        }];
                        
                        ProvisioningProfile *provisioningProfile = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([ProvisioningProfile class]) inManagedObjectContext:[[AppDelegate appDelegate] managedObjectContext]];
                        [provisioningProfile setUuid:xcProject.mobileProvision.uuid];
                        [provisioningProfile setTeamId:xcProject.mobileProvision.teamId];
                        [provisioningProfile setTeamName:xcProject.mobileProvision.teamName];
                        [provisioningProfile setBuildType:xcProject.mobileProvision.buildType];
                        [provisioningProfile setCreateDate:xcProject.mobileProvision.createDate];
                        [provisioningProfile setExpirationDate:xcProject.mobileProvision.expirationDate];
                        [provisioningProfile addProvisionedDevices:provisionDeviceSet];
                        
                        NSMutableOrderedSet *uploadRecordsSet;
                        if (provisioningProfile.uploadRecord && provisioningProfile.uploadRecord.count > 0){
                            uploadRecordsSet = [[NSMutableOrderedSet alloc] initWithOrderedSet:provisioningProfile.uploadRecord];
                        } else {
                            uploadRecordsSet = [[NSMutableOrderedSet alloc] init];
                        }
                        [uploadRecordsSet addObject:uploadRecord];
                        [provisioningProfile addUploadRecord:uploadRecordsSet];
                        [uploadRecord setProvisioningProfile:provisioningProfile];
                    }
                } @catch (NSException *exception) {
                    [EventTracker logExceptionEvent:exception];
                    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Exception %@",exception.userInfo]];
                }
            }
            
            
            
            NSMutableOrderedSet *uploadRecordsSet;
            if (project.uploadRecords.count > 0){
                uploadRecordsSet = [[NSMutableOrderedSet alloc] initWithOrderedSet:project.uploadRecords];
            }else{
                uploadRecordsSet = [[NSMutableOrderedSet alloc] init];
            }
            [uploadRecordsSet addObject:uploadRecord];
            [project addUploadRecords:uploadRecordsSet];
            
            [[AppDelegate appDelegate] saveCoreDataChanges];
            
            return project;
        }
    } @catch (NSException *exception) {
        [EventTracker logExceptionEvent:exception];
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Exception %@",exception.userInfo]];
    }
    return nil;
}

@end
