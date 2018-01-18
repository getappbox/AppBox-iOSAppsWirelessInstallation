//
//  AppDelegate.m
//  AppBox
//
//  Created by Vineet Choudhary on 29/08/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)awakeFromNib{
    [super awakeFromNib];
    //Handle URL Scheme
    
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleGetURLWithEvent:andReply:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    [center setDelegate:self];
    self.sessionLog = [[NSMutableString alloc] init];
    
    //Default Setting
    [DefaultSettings setFirstTimeSettings];
    [DefaultSettings setEveryStartupSettings];
    
    //Check Dropbox Keys
    [Common checkDropboxKeys];
    
    //Init Crashlytics
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"NSApplicationCrashOnExceptions": @YES }];
    [Fabric with:@[[Crashlytics class], [Answers class]]];
    
    //Check for update
    [UpdateHandler isNewVersionAvailableCompletion:^(bool available, NSURL *url) {
        if (available){
            if (![UserData updateAlertEnable]){
                [UpdateHandler showUpdateAlertWithUpdateURL:url];
            }
        }
    }];
    
    //Check for arguments
    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    [ABLog log:@"All Command Line Arguments = %@",arguments];
    for (NSString *argument in arguments) {
        if ([argument containsString:@"build="]) {
            NSArray *components = [argument componentsSeparatedByString:@"build="];
            [ABLog log:@"Path Components = %@",components];
            if (components.count == 2) {
                [self handleProjectAtPath:[components lastObject]];
            } else {
                [ABLog log:@"Invalid command %@",arguments];
                exit(abExitCodeForUnstableBuild);
            }
            break;
        } else if ([arguments indexOfObject:argument] == arguments.count - 1){
            [ABLog log:@"Normal Run"];
        }
    }
    
    //Load Ads
    [AdStore loadAds];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self saveCoreDataChanges];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender{
    return YES;
}



#pragma mark - AppDelegate Helper

+(AppDelegate *)appDelegate{
    return ((AppDelegate *)[[NSApplication sharedApplication] delegate]);
}

-(void)addSessionLog:(NSString *)sessionLog{
    NSLog(@"%@",sessionLog);
    [_sessionLog appendFormat: @"%@\n",sessionLog];
    [[NSNotificationCenter defaultCenter] postNotificationName:abSessionLogUpdated object:nil];
}

//URISchem URL Handler
-(void)handleGetURLWithEvent:(NSAppleEventDescriptor *)event andReply:(NSAppleEventDescriptor *)reply{
    NSURL *url = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
    [self addSessionLog:[NSString stringWithFormat:@"Handling URL = %@",url]];
    
    //Check for Dropbox auth
    DBOAuthResult *authResult = [DBClientsManager handleRedirectURL:url];
    if (authResult != nil) {
        if ([authResult isSuccess]) {
            [[AppDelegate appDelegate] addSessionLog:@"Success! User is logged into Dropbox."];
            [Answers logLoginWithMethod:@"Dropbox" success:@YES customAttributes:@{}];
            [[NSNotificationCenter defaultCenter] postNotificationName:abDropBoxLoggedInNotification object:nil];
        } else if ([authResult isCancel]) {
            [[AppDelegate appDelegate] addSessionLog:@"Authorization flow was manually canceled by user."];
            [Answers logLoginWithMethod:@"Dropbox" success:NO customAttributes:@{@"Error" : @"Canceled by User"}];
            [Common showAlertWithTitle:@"Authorization Canceled." andMessage:abEmptyString];
        } else if ([authResult isError]) {
            [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Error: %@", authResult.errorDescription]];
            [Answers logLoginWithMethod:@"Dropbox" success:NO customAttributes:@{@"Error" : authResult.errorDescription}];
            [Common showAlertWithTitle:@"Authorization Canceled." andMessage:abEmptyString];
        }
    } else if (url != nil) {
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"query = %@", url.query]];
        if (url.query != nil && url.query.length > 0) {
            [self handleProjectAtPath:url.query];
        }
    }
}

-(void)handleProjectAtPath:(NSString *)projectPath {
    NSString *certInfoPath = [RepoBuilder isValidRepoForCertificateFileAtPath:projectPath];
    [RepoBuilder installCertificateWithDetailsInFile:certInfoPath andRepoPath:projectPath];
    
    NSString *settingPath = [RepoBuilder isValidRepoForSettingFileAtPath:projectPath Index:@0];
    XCProject *project = [RepoBuilder xcProjectWithRepoPath:projectPath andSettingFilePath:settingPath];
    if (project == nil) {
        [self addSessionLog:@"AppBox can't able to create project model of this repo."];
        exit(abExitCodeForUnstableBuild);
        return;
    }
    if (self.isReadyToBuild) {
        [self addSessionLog:@"AppBox is ready to build."];
        [[NSNotificationCenter defaultCenter] postNotificationName:abBuildRepoNotification object:project];
    } else {
        [[NSNotificationCenter defaultCenter] addObserverForName:abAppBoxReadyToBuildNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            [self addSessionLog:@"AppBox is ready to build. [Block]"];
            [[NSNotificationCenter defaultCenter] postNotificationName:abBuildRepoNotification object:project];
        }];
    }
}

#pragma mark - Notification Center Delegate
-(void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    [center removeDeliveredNotification:notification];
}

#pragma mark - Core Data stack

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.developerinsider.AppBox" in the user's Application Support directory.
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"com.developerinsider.AppBox"];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"AppBox" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationDocumentsDirectory = [self applicationDocumentsDirectory];
    BOOL shouldFail = NO;
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    
    // Make sure the application files directory is there
    NSDictionary *properties = [applicationDocumentsDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    if (properties) {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            failureReason = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationDocumentsDirectory path]];
            shouldFail = YES;
        }
    } else if ([error code] == NSFileReadNoSuchFileError) {
        error = nil;
        [fileManager createDirectoryAtPath:[applicationDocumentsDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    if (!shouldFail && !error) {
        NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        NSURL *url = [applicationDocumentsDirectory URLByAppendingPathComponent:@"OSXCoreDataObjC.storedata"];
        if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
            coordinator = nil;
        }
        _persistentStoreCoordinator = coordinator;
    }
    
    if (shouldFail || error) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        if (error) {
            dict[NSUnderlyingErrorKey] = error;
        }
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

#pragma mark - Core Data Saving and Undo support

- (void)saveCoreDataChanges{
    // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    NSError *error = nil;
    if ([[self managedObjectContext] hasChanges] && ![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
    return [[self managedObjectContext] undoManager];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertFirstButtonReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

@end
