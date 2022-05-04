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
    
    //Init AppCenter
    [[NSUserDefaults standardUserDefaults] registerDefaults: @{ @"NSApplicationCrashOnExceptions": @YES }];
    NSString *appCenter = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"AppCenter"];
    [MSACAppCenter start:appCenter withServices: @[[MSACAnalytics class], [MSACCrashes class]]];
    [MSACCrashes notifyWithUserConfirmation: MSACUserConfirmationAlways];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    [center setDelegate:self];
    self.sessionLog = [[NSMutableString alloc] init];
    
    //Default Setting
    [DefaultSettings setFirstTimeSettings];
    [DefaultSettings setEveryStartupSettings];
    
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
        if ([argument containsString:abArgsIPA]) {
            NSArray *components = [argument componentsSeparatedByString:abArgsIPA];
            [ABLog log:@"IPA Components = %@",components];
            if (components.count == 2) {
                [self handleIPAAtPath:[components lastObject]];
            } else {
                [self addSessionLog:[NSString stringWithFormat:@"Invalid IPA Argument %@",arguments]];
                exit(abExitCodeForInvalidCommand);
            }
            break;
        }
    }
    
    //[self setAppBoxAsDefualt];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self saveCoreDataChanges];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender{
    return YES;
}

-(BOOL)application:(NSApplication *)sender openFile:(NSString *)filename{
    if (self.processing){
        return YES;
    }
    [self openFileWithPath:filename];
    return YES;
}

-(void)openFileWithPath:(NSString *)filePath{
    if (self.isReadyToBuild) {
        [ABLog log:@"AppBox is ready to use."];
        [[NSNotificationCenter defaultCenter] postNotificationName:abUseOpenFilesNotification object:filePath];
    } else {
        [[NSNotificationCenter defaultCenter] addObserverForName:abAppBoxReadyToUseNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            [ABLog log:@"AppBox is ready to use. [Block]"];
            [[NSNotificationCenter defaultCenter] postNotificationName:abUseOpenFilesNotification object:filePath];
        }];
    }
}

#pragma mark - Default Application
-(BOOL)setAppBoxAsDefualt{
    OSStatus returnStatus = LSSetDefaultRoleHandlerForContentType(CFSTR("com.apple.iTunes.ipa"), kLSRolesAll, (__bridge CFStringRef) [[NSBundle mainBundle] bundleIdentifier]);
    if (returnStatus != 0) {
        NSLog(@"Got an error when setting default application - %d", (int)returnStatus);
        return NO;
    }
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
    [DBClientsManager handleRedirectURL:url completion:^(DBOAuthResult * _Nullable authResult) {
        if (authResult != nil) {
            if ([authResult isSuccess]) {
                [[AppDelegate appDelegate] addSessionLog:@"Success! User is logged into Dropbox."];
                [EventTracker logEventWithType:LogEventTypeAuthDropboxSuccess];
                [[NSNotificationCenter defaultCenter] postNotificationName:abDropBoxLoggedInNotification object:nil];
            } else if ([authResult isCancel]) {
                [[AppDelegate appDelegate] addSessionLog:@"Authorization flow was manually canceled by user."];
                [EventTracker logEventWithType:LogEventTypeAuthDropboxCanceled];
                [Common showAlertWithTitle:@"Authorization Canceled." andMessage:abEmptyString];
            } else if ([authResult isError]) {
                [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Error: %@", authResult.errorDescription]];
                [EventTracker logEventWithType:LogEventTypeAuthDropboxError];
                [Common showAlertWithTitle:@"Authorization Canceled." andMessage:abEmptyString];
            }
        } else if (url != nil) {
            [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"query = %@", url.query]];
    //        if (url.query != nil && url.query.length > 0) {
    //            [self handleProjectAtPath:url.query];
    //        }
        }
    }];
}

-(void)handleIPAAtPath:(NSString *)ipaPath {
    XCProject *project = [CIProjectBuilder xcProjectWithIPAPath:ipaPath];
    if (self.isReadyToBuild) {
        [self addSessionLog:@"AppBox is ready to upload IPA."];
        [[NSNotificationCenter defaultCenter] postNotificationName:abBuildRepoNotification object:project];
    } else {
        [[NSNotificationCenter defaultCenter] addObserverForName:abAppBoxReadyToUseNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            [self addSessionLog:@"AppBox is ready to upload IPA. [Block]"];
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
        NSDictionary *presistentStoreOptions = @{NSInferMappingModelAutomaticallyOption: @YES,
                                                 NSMigratePersistentStoresAutomaticallyOption: @YES};
        if (![coordinator addPersistentStoreWithType: NSXMLStoreType
                                       configuration: nil
                                                 URL: url
                                             options: presistentStoreOptions
                                               error: &error]) {
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
