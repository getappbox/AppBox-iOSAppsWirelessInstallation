//
//  ABProject+CoreDataClass.m
//  
//
//  Created by Vineet Choudhary on 17/10/17.
//
//

#import "Project+CoreDataClass.h"

@implementation ABProject

+(ABProject *)addProjectWithIPAUploadInfo:(IPAUploadInfo *)ipaUploadInfo{
    
    @try {
        //fetch existing project with same identifer (if any)
        NSError *error;
        NSFetchRequest *fetchRequest = [ABProject fetchRequest];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"SELF.bundleIdentifier = %@", ipaUploadInfo.identifer]];
        NSArray *projects = [[[AppDelegate appDelegate] managedObjectContext] executeFetchRequest:fetchRequest error:&error];
        if (error){
            //error in fetch request
            [Common showAlertWithTitle:@"Error" andMessage:error.localizedDescription];
        }else{
            ABProject *project;
            if (projects.count > 0){
                //use existing project
                project = [projects lastObject];
            }else{
                //create new project
                project = [NSEntityDescription insertNewObjectForEntityForName:@"Project" inManagedObjectContext:[[AppDelegate appDelegate] managedObjectContext]];
                [project setBundleIdentifier:ipaUploadInfo.identifer];
            }
            
            //set other project properties
            [project setName:ipaUploadInfo.name];
            
            //create new upload record
            ABUploadRecord *uploadRecord = [NSEntityDescription insertNewObjectForEntityForName:@"UploadRecord" inManagedObjectContext:[[AppDelegate appDelegate] managedObjectContext]];

            //set upload details
            if (ipaUploadInfo.buildType){
                [uploadRecord setBuildType:ipaUploadInfo.buildType];
            }
            if (ipaUploadInfo.dbAppInfoJSONFullPath){
                [uploadRecord setDbAppInfoFullPath:ipaUploadInfo.dbAppInfoJSONFullPath.absoluteString];
            }
            if (ipaUploadInfo.dbDirectory){
                [uploadRecord setDbDirectroy:ipaUploadInfo.dbDirectory.absoluteString];
                NSArray *pathComponents = [ipaUploadInfo.dbDirectory pathComponents];
                if (pathComponents.count > 1) {
                    [uploadRecord setDbFolderName:[NSString stringWithFormat:@"%@%@", pathComponents[0], pathComponents[1]]];
                }
            }
            if (ipaUploadInfo.dbIPAFullPath){
                [uploadRecord setDbIPAFullPath:ipaUploadInfo.dbIPAFullPath.absoluteString];
            }
            if (ipaUploadInfo.dbManifestFullPath){
                [uploadRecord setDbManifestFullPath:ipaUploadInfo.dbManifestFullPath.absoluteString];
            }
            if (ipaUploadInfo.ipaFileDBShareableURL){
                [uploadRecord setDbSharedIPAURL:ipaUploadInfo.ipaFileDBShareableURL.absoluteString];
            }
            if (ipaUploadInfo.manifestFileSharableURL){
                [uploadRecord setDbSharedManifestURL:ipaUploadInfo.manifestFileSharableURL.absoluteString];
            }
            
            if (ipaUploadInfo.ipaFullPath){
                [uploadRecord setLocalBuildPath:[ipaUploadInfo.ipaFullPath.resourceSpecifier stringByRemovingPercentEncoding]];
            }
            if (ipaUploadInfo.appShortShareableURL){
                [uploadRecord setShortURL:ipaUploadInfo.appShortShareableURL.stringValue];
            }
            if (ipaUploadInfo.build){
                [uploadRecord setBuild:ipaUploadInfo.build];
            }
            if (ipaUploadInfo.version){
                [uploadRecord setVersion:ipaUploadInfo.version];
            }
            
            [uploadRecord setKeepSameLink:[NSNumber numberWithBool:ipaUploadInfo.isKeepSameLinkEnabled]];
            [uploadRecord setDatetime:[NSDate date]];
            
            if (ipaUploadInfo.mobileProvision){
                @try {
                    //check either existing provisioning profile already exist or not
                    NSFetchRequest *provisioningProfileFetchRequest = [ABProvisioningProfile fetchRequest];
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uuid = %@", ipaUploadInfo.mobileProvision.uuid];
                    [provisioningProfileFetchRequest setPredicate:predicate];
                    NSArray *fetchedResult = [[[AppDelegate appDelegate] managedObjectContext] executeFetchRequest:provisioningProfileFetchRequest error:nil];
                    
                    if (fetchedResult.count > 0 && [fetchedResult.firstObject isKindOfClass:[ABProvisioningProfile class]]) {
                        //if provisioning profile exist update records
                        ABProvisioningProfile *provisioningProfile = (ABProvisioningProfile *)fetchedResult.firstObject;
                        [provisioningProfile addUploadRecordObject:uploadRecord];
                        [uploadRecord setProvisioningProfile:provisioningProfile];
                    } else {
                        //Create new provisioning profile record
                        NSMutableOrderedSet<ABProvisionedDevice *> *provisionDeviceSet = [[NSMutableOrderedSet<ABProvisionedDevice *> alloc] init];
                        [ipaUploadInfo.mobileProvision.provisionedDevices enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            //Create ProvisionedDevice Object and Add into Set
                            ABProvisionedDevice *device = [NSEntityDescription insertNewObjectForEntityForName:@"ProvisionedDevice" inManagedObjectContext:[[AppDelegate appDelegate] managedObjectContext]];
                            [device setDeviceId:obj];
                            [provisionDeviceSet addObject:device];
                        }];
                        
                        ABProvisioningProfile *provisioningProfile = [NSEntityDescription insertNewObjectForEntityForName:@"ProvisioningProfile" inManagedObjectContext:[[AppDelegate appDelegate] managedObjectContext]];
                        [provisioningProfile setUuid:ipaUploadInfo.mobileProvision.uuid];
                        [provisioningProfile setTeamId:ipaUploadInfo.mobileProvision.teamId];
                        [provisioningProfile setTeamName:ipaUploadInfo.mobileProvision.teamName];
                        [provisioningProfile setBuildType:ipaUploadInfo.mobileProvision.buildType];
                        [provisioningProfile setCreateDate:ipaUploadInfo.mobileProvision.createDate];
                        [provisioningProfile setExpirationDate:ipaUploadInfo.mobileProvision.expirationDate];
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
					DDLogError(@"Exception %@",exception.abDescription);
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
		DDLogError(@"Exception %@",exception.abDescription);
    }
    return nil;
}

@end
