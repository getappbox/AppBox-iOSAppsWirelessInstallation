//
//  Project+CoreDataClass.m
//  
//
//  Created by Vineet Choudhary on 08/02/17.
//
//

#import "Project+CoreDataClass.h"
#import "CISetting+CoreDataClass.h"
#import "UploadRecord+CoreDataClass.h"
@implementation Project

+(Project *)addProjectWithXCProject:(XCProject *)xcProject andSaveDetails:(SaveDetailTypes)saveDetailTypes{
    
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
        if (xcProject.fullPath){
            [project setProjectPath:[xcProject.fullPath.resourceSpecifier stringByRemovingPercentEncoding]];
        }
        
        if (saveDetailTypes == SaveCIDetails){
            //fetch exisiting CI setting based on branch
            NSFetchRequest *fetchRequest = [CISetting fetchRequest];
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"SELF.branchName = %@", xcProject.branch]];
            NSArray *ciSettings = [fetchRequest execute:&error];
            if (error){
                //error in fetch request
                [Common showAlertWithTitle:@"Error" andMessage:error.localizedDescription];
            }else{
                CISetting *ciSetting;
                if (ciSettings.count > 0){
                    //use existing setting
                    ciSetting = [ciSettings lastObject];
                }else{
                    //create new setting
                    ciSetting = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([CISetting class]) inManagedObjectContext:[[AppDelegate appDelegate] managedObjectContext]];
                    [ciSetting setBranchName:xcProject.branch];
                }
                
                //set ci settings properties
                [ciSetting setTeamId:xcProject.teamId];
                [ciSetting setBuildType:xcProject.buildType];
                [ciSetting setEmailAddress:xcProject.emails];
                [ciSetting setKeepSameLink:xcProject.keepSameLink];
                [ciSetting setBuildScheme:xcProject.selectedSchemes];
                [ciSetting setPersonalMessage:xcProject.personalMessage];
                
                NSMutableOrderedSet *ciSettingsSet;
                if (project.ciSettings.count > 0){
                    ciSettingsSet = [[NSMutableOrderedSet alloc] initWithOrderedSet:project.ciSettings];
                }else{
                    ciSettingsSet = [[NSMutableOrderedSet alloc] init];
                }
                [ciSettingsSet addObject:ciSetting];
                [project setCiSettings:ciSettingsSet];
            }
        } else if (saveDetailTypes == SaveUploadDetails){
            //create new upload record
            UploadRecord *uploadRecord = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([UploadRecord class]) inManagedObjectContext:[[AppDelegate appDelegate] managedObjectContext]];
            
            //set upload details
            if (xcProject.selectedSchemes){
                [uploadRecord setBuildScheme:xcProject.selectedSchemes];
            }
            if (xcProject.buildType){
                [uploadRecord setBuildScheme:xcProject.buildType];
            }
            if (xcProject.dbAppInfoJSONFullPath){
                [uploadRecord setDbAppInfoFullPath:xcProject.dbAppInfoJSONFullPath.absoluteString];
            }
            [uploadRecord setDbDirectroy:xcProject.dbDirectory.absoluteString];
            [uploadRecord setDbFolderName:[[xcProject.dbDirectory pathComponents] firstObject]];
            [uploadRecord setDbIPAFullPath:xcProject.dbIPAFullPath.absoluteString];
            [uploadRecord setDbManifestFullPath:xcProject.dbManifestFullPath.absoluteString];
            //[uploadRecord setDbSharedAppInfoURL:xcProject.ipaFileDBShareableURL.absoluteString];
            [uploadRecord setDbSharedIPAURL:xcProject.ipaFileDBShareableURL.absoluteString];
            [uploadRecord setDbSharedManifestURL:xcProject.manifestFileSharableURL.absoluteString];
            [uploadRecord setKeepSameLink:xcProject.keepSameLink];
            [uploadRecord setLocalBuildPath:[xcProject.ipaFullPath.resourceSpecifier stringByRemovingPercentEncoding]];
//            [uploadRecord setMailURL:];
            if (xcProject.teamId){
                [uploadRecord setTeamId:xcProject.teamId];
            }
            [uploadRecord setShortURL:xcProject.appShortShareableURL.absoluteString];
            [uploadRecord setBuild:xcProject.build];
            [uploadRecord setVersion:xcProject.version];
            [uploadRecord setDatetime:[NSDate date]];
            
            NSMutableOrderedSet *uploadRecordsSet;
            if (project.uploadRecords.count > 0){
                uploadRecordsSet = [[NSMutableOrderedSet alloc] initWithOrderedSet:project.uploadRecords];
            }else{
                uploadRecordsSet = [[NSMutableOrderedSet alloc] init];
            }
            [uploadRecordsSet addObject:uploadRecord];
            [project addUploadRecords:uploadRecordsSet];
        }
        
        [[AppDelegate appDelegate] saveCoreDataChanges];
        
        return project;
    }
    return nil;
}

@end
