//
//  DashboardViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 19/09/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "DashboardViewController.h"

#define ShortURLCellId @"ShortURLCellId"

typedef enum : NSUInteger {
    DashBoardColumnName = 0,
    DashBoardColumnBundleIdentifer,
    DashBoardColumnVersion,
    DashBoardColumnShortURL,
    DashBoardColumnDate,
    DashBoardColumnBuidlType,
    DashBoardColumnScheme,
    DashBoardColumnTeamId
} DashBoardColumn;


@implementation DashboardViewController{
    NSMutableArray<ABUploadRecord *> *uploadRecords;
    UploadManager *uploadManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Setup TableView
    [_dashboardTableView setAllowsEmptySelection:NO];
    
    //Load data
    [self loadData];
    [self setupUploadManager];
    
    //Track screen
    [EventTracker logScreen:@"Dashboard Screen"];
    
    //Coredata changes notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadData) name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
}

-(void)viewDidDisappear{
    [super viewDidDisappear];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)setupUploadManager{
    uploadManager = [[UploadManager alloc] init];
    [uploadManager setCurrentViewController:self];
    __unsafe_unretained typeof(self) weakSelf = self;
    __unsafe_unretained typeof(UploadManager *) weakUploadManager = uploadManager;
    [uploadManager setCompletionBlock:^{
        [ABHudViewController hideAllHudFromView:weakSelf.view after:0];
        if (weakUploadManager.uploadRecord){
            [[[AppDelegate appDelegate] managedObjectContext] deleteObject: weakUploadManager.uploadRecord];
        }
        [[AppDelegate appDelegate] saveCoreDataChanges];
        [weakSelf loadData];
    }];
    
    [uploadManager setErrorBlock:^(NSError *error, BOOL terminate){
        [ABHudViewController hideAllHudFromView:weakSelf.view after:0];
    }];
}

-(void)loadData{
    NSError *error;
    NSFetchRequest *fetchRequest = [ABUploadRecord fetchRequest];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"datetime" ascending:NO];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    NSArray *fetchResults = [[[AppDelegate appDelegate] managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    
    //remove any existing upload request
    if (uploadRecords){
        [uploadRecords removeAllObjects];
    }
    
    //handle fetchrequest error, manage action view and reload data
    if (error){
        [Common showAlertWithTitle:@"Error" andMessage:error.localizedDescription];
    }else if (fetchResults.count > 0){
        uploadRecords = [NSMutableArray arrayWithArray:fetchResults];
    } else if (fetchResults.count == 0) {
        [self setActionButtonViewHidden:YES];
    }
    [_dashboardTableView reloadData];
}

-(void)setActionButtonViewHidden:(BOOL)hidden{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
        context.duration = 0.25;
        context.allowsImplicitAnimation = YES;
        actionViewHeightConstraint.constant = hidden ? 0 : 65;
		self.openURLView.hidden = hidden;
		self.cloneURLView.hidden = hidden;
		self.showQRCodeView.hidden = hidden;
		self.deleteBuildView.hidden = hidden;
		self.provisioningProfileView.hidden = hidden;
		self.showInFinderView.hidden = hidden;
		self.showInDropboxView.hidden = hidden;
        [self.view layoutSubtreeIfNeeded];
    } completionHandler:nil];
}

//MARK: - NSTableView Delegate and DataSource
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return uploadRecords.count;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    ABUploadRecord *uploadRecord = [uploadRecords objectAtIndex:row];
    NSTableCellView *cell = [tableView makeViewWithIdentifier:ShortURLCellId owner:nil];
    
    //Project Name
    if (tableColumn == [tableView.tableColumns objectAtIndex:DashBoardColumnName]) {
        NSString *projectName = uploadRecord.project.name == nil ? @"N/A" : uploadRecord.project.name;
        [cell.textField setStringValue: projectName];
    }
    
    //Bundle Identifer
    else if (tableColumn == [tableView.tableColumns objectAtIndex:DashBoardColumnBundleIdentifer]) {
        NSString *bundleIdentifer = uploadRecord.project.bundleIdentifier == nil ? @"N/A" : uploadRecord.project.bundleIdentifier;
        [cell.textField setStringValue: bundleIdentifer];
    }
    
    //Version and Build
    else if (tableColumn == [tableView.tableColumns objectAtIndex: DashBoardColumnVersion]){
        NSString *version = uploadRecord.version == nil ? @"N/A" : uploadRecord.version;
        NSString *build = uploadRecord.build == nil ? @"N/A" : uploadRecord.build;
        [cell.textField setStringValue:[NSString stringWithFormat:@"%@ (%@)", version, build]];
    }
    
    //Short URL
    else if (tableColumn == [tableView.tableColumns objectAtIndex:DashBoardColumnShortURL]){
        NSString *shortURL = uploadRecord.shortURL == nil ? @"N/A" : uploadRecord.shortURL;
        [cell.textField setStringValue:shortURL];
    }
    
    //Upload Date
    else if (tableColumn == [tableView.tableColumns objectAtIndex:DashBoardColumnDate]){
        NSString *uploadDate = uploadRecord.datetime == nil ? @"N/A" : uploadRecord.datetime.string;
        [cell.textField setStringValue:uploadDate];
    }
    
    //Build Type
    else if (tableColumn == [tableView.tableColumns objectAtIndex:DashBoardColumnBuidlType]){
        if (uploadRecord.provisioningProfile && uploadRecord.provisioningProfile.buildType) {
            [cell.textField setStringValue:uploadRecord.provisioningProfile.buildType.capitalizedString];
        } else {
            [cell.textField setStringValue:@"N/A"];
        }
    }
    
    //TeamId
    else if (tableColumn == [tableView.tableColumns objectAtIndex:DashBoardColumnTeamId]){
        if (uploadRecord.provisioningProfile && uploadRecord.provisioningProfile.teamId && uploadRecord.provisioningProfile.teamName) {
            [cell.textField setStringValue:[NSString stringWithFormat:@"%@ - %@", uploadRecord.provisioningProfile.teamId, uploadRecord.provisioningProfile.teamName]];
        } else {
            [cell.textField setStringValue:@"N/A"];
        }
    }
    return cell;
}

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row{
    [self setActionButtonViewHidden:NO];
    return YES;
}

//MARK: - Build Action
- (IBAction)copyURLButtonTapped:(NSButton *)sender {
    ABUploadRecord *uploadRecord = [self selectedUploadRecord];
    if (uploadRecord){
        [[NSPasteboard generalPasteboard] clearContents];
		[[NSPasteboard generalPasteboard] setString:uploadRecord.shortURL forType:NSPasteboardTypeString];
        [ABHudViewController showOnlyStatus:@"Copied!!" onView:self.view];
        [EventTracker logEventWithType:LogEventTypeCopyToClipboardFromDashboard];
    }
}

- (IBAction)deleteBuildButtonTapped:(NSButton *)sender {
    ABUploadRecord *uploadRecord = [self selectedUploadRecord];
	
    if (uploadRecord){
        //Show Delete Alert
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText: @"Are you sure you want to delete this build?"];
        [alert setInformativeText:[NSString stringWithFormat:@"You're about to delete \"%@-%@(%@)\". This is permanent!", uploadRecord.project.name, uploadRecord.version, uploadRecord.build]];
        [alert setAlertStyle:NSInformationalAlertStyle];
		[alert addButtonWithTitle: @"Delete from Dropbox and Dashboard"];
        [alert addButtonWithTitle: @"Delete only from Dashboard"];
        [alert addButtonWithTitle: @"Cancel"];
		NSModalResponse modelResponse = [alert runModal];
		
		//delete from dropbox and dashboard
        if (modelResponse == NSAlertFirstButtonReturn) {
            [uploadManager setUploadRecord: uploadRecord];
            [uploadManager setProject: uploadRecord.xcProject];
            [uploadManager deleteBuildFromDropboxAndDashboard];
		}
		
		//delete only from dashboard
		else if (modelResponse == NSAlertSecondButtonReturn) {
			[uploadManager setUploadRecord: uploadRecord];
			[uploadManager setProject: uploadRecord.xcProject];
			[uploadManager deleteBuildFromDashboard];
		}
		
        [EventTracker logEventWithType: LogEventTypeDeleteBuild];
    }
}

- (IBAction)provisioningDetailsButtonTapped:(NSButton *)sender {
    ABUploadRecord *uploadRecord = [self selectedUploadRecord];
    if (uploadRecord){
        if (uploadRecord.provisioningProfile){
            ProvisioningDetailsViewController *provisioningDetailsViewController = [[ProvisioningDetailsViewController alloc] initWithNibName:NSStringFromClass([ProvisioningDetailsViewController class]) bundle:nil];
            [provisioningDetailsViewController setUploadRecord:uploadRecord];
            [self presentViewControllerAsSheet:provisioningDetailsViewController];
        } else {
            [Common showAlertWithTitle:@"Information" andMessage:@"Provisioning profiles details not available for this build."];
        }
    }
}

- (IBAction)openURLButtonTapped:(NSButton *)sender {
    ABUploadRecord *uploadRecord = [self selectedUploadRecord];
    if (uploadRecord){
        NSURL *analyticsURL = [NSURL URLWithString:uploadRecord.shortURL];
        [[NSWorkspace sharedWorkspace] openURL:analyticsURL];
    }
}

- (IBAction)showQRCodeButtonTapped:(NSButton *)sender {
    NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    QRCodeViewController *qrCodeViewController = [storyBoard instantiateControllerWithIdentifier:NSStringFromClass([QRCodeViewController class])];
    [qrCodeViewController setUploadRecord:[self selectedUploadRecord]];
    [self presentViewControllerAsSheet:qrCodeViewController];
}



- (IBAction)showInFinderButtonTapped:(NSButton *)sender {
    ABUploadRecord *uploadRecord = [self selectedUploadRecord];
    if (uploadRecord){
        ABUploadRecord *uploadRecord = [uploadRecords objectAtIndex:_dashboardTableView.selectedRow];
		BOOL isDirectory = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:uploadRecord.localBuildPath isDirectory:&isDirectory]) {
            NSURL *fileURL = [NSURL fileURLWithPath:uploadRecord.localBuildPath];
            [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
        } else {
            [Common showAlertWithTitle:@"Error" andMessage:@"File not found."];
        }
        [EventTracker logEventWithType:LogEventTypeOpenInFinder];
    }
}

- (IBAction)showInDropBoxButtonTapped:(NSButton *)sender {
    ABUploadRecord *uploadRecord = [self selectedUploadRecord];
    if (uploadRecord){
        NSString *dropboxURLString = [NSString stringWithFormat:@"%@%@", abDropBoxAppBaseURL, uploadRecord.dbDirectroy];
        NSURL *dropboxURL = [NSURL URLWithString: dropboxURLString];
        [[NSWorkspace sharedWorkspace] openURL:dropboxURL];
        [EventTracker logEventWithType:LogEventTypeOpenInDropbox];
    }
}

//MARK: - Helper Method
-(ABUploadRecord *)selectedUploadRecord{
    if (_dashboardTableView.selectedRow == -1 || uploadRecords == nil || (uploadRecords && uploadRecords.count == 0)){
        return nil;
    }
    ABUploadRecord *uploadRecord = [uploadRecords objectAtIndex:_dashboardTableView.selectedRow];
    return uploadRecord;
}

@end
