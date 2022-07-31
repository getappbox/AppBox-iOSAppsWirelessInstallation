//
//  AppDelegate.h
//  AppBox
//
//  Created by Vineet Choudhary on 29/08/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

#import "DefaultSettings.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate>

//stored properties
@property (nonatomic) BOOL processing;
@property (nonatomic) BOOL isReadyToBuild;
@property (nonatomic) BOOL isInternetConnected;

//menu iboutlet
@property (nonatomic, weak) IBOutlet NSMenuItem *dropboxLogoutButton;
@property (nonatomic, weak) IBOutlet NSMenuItem *dropboxSpaceButton;
@property (nonatomic, weak) IBOutlet NSMenuItem *dropboxAccountButton;
@property (nonatomic, weak) IBOutlet NSMenuItem *dropboxNameButton;

//coredata
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
-(void)saveCoreDataChanges;

+(AppDelegate *)appDelegate;
-(void)openLatestLogFile;
-(void)openFileWithPath:(NSString *)filePath;

@end

