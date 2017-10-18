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
    DashBoardColumnVersion,
    DashBoardColumnShortURL,
    DashBoardColumnDate,
    DashBoardColumnBuidlType,
    DashBoardColumnTeamId,
    DashBoardColumnScheme,
    DashBoardColumnDropboxFolder
} DashBoardColumn;


@implementation DashboardViewController{
    NSMutableArray<UploadRecord *> *uploadRecords;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Setup TableView
    [_dashboardTableView setAllowsEmptySelection:NO];
    
    //Load data
    [self loadData];
    
    //Coredata changes notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadData) name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
}

-(void)viewDidDisappear{
    [super viewDidDisappear];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)loadData{
    NSError *error;
    NSFetchRequest *fetchRequest = [UploadRecord fetchRequest];
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
        [self.view layoutSubtreeIfNeeded];
    } completionHandler:nil];
}

#pragma mark - NSTableView Delegate and DataSource
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return uploadRecords.count;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    UploadRecord *uploadRecord = [uploadRecords objectAtIndex:row];
    NSTableCellView *cell = [tableView makeViewWithIdentifier:ShortURLCellId owner:nil];
    if (tableColumn == [tableView.tableColumns objectAtIndex:DashBoardColumnName]) {
        [cell.textField setStringValue: uploadRecord.project.name];
    } else if (tableColumn == [tableView.tableColumns objectAtIndex: DashBoardColumnVersion]){
        [cell.textField setStringValue:[NSString stringWithFormat:@"%@ (%@)", uploadRecord.version, uploadRecord.build]];
    } else if (tableColumn == [tableView.tableColumns objectAtIndex:DashBoardColumnShortURL]){
        [cell.textField setStringValue:uploadRecord.shortURL];
    } else if (tableColumn == [tableView.tableColumns objectAtIndex:DashBoardColumnDate]){
        [cell.textField setStringValue:uploadRecord.datetime.string];
    } else if (tableColumn == [tableView.tableColumns objectAtIndex:DashBoardColumnBuidlType] && uploadRecord.buildType){
        [cell.textField setStringValue:uploadRecord.buildType];
    } else if (tableColumn == [tableView.tableColumns objectAtIndex:DashBoardColumnTeamId] && uploadRecord.teamId){
        [cell.textField setStringValue:uploadRecord.teamId];
    } else if (tableColumn == [tableView.tableColumns objectAtIndex:DashBoardColumnScheme] && uploadRecord.buildScheme) {
        [cell.textField setStringValue:uploadRecord.buildScheme];
    } else if (tableColumn == [tableView.tableColumns objectAtIndex:DashBoardColumnDropboxFolder]) {
        [cell.textField setStringValue:uploadRecord.dbDirectroy];
    }
    return cell;
}

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row{
    [self setActionButtonViewHidden:NO];
    return YES;
}

#pragma mark - Build Action
- (IBAction)copyURLButtonTapped:(NSButton *)sender {
    UploadRecord *uploadRecord = [uploadRecords objectAtIndex:_dashboardTableView.selectedRow];
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:uploadRecord.shortURL forType:NSStringPboardType];
    [MBProgressHUD showOnlyStatus:@"Copied!!" onView:self.view];
}

- (IBAction)deleteBuildButtonTapped:(NSButton *)sender {
    UploadRecord *uploadRecord = [uploadRecords objectAtIndex:_dashboardTableView.selectedRow];
    
    //Show Delete Alert
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText: @"Are you sure you want to delete this build?"];
    [alert setInformativeText:[NSString stringWithFormat:@"You're about to delete \"%@-%@(%@)\". This is permanent! We warned you, k?", uploadRecord.project.name, uploadRecord.version, uploadRecord.build]];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert addButtonWithTitle:@"Delete"];
    [alert addButtonWithTitle:@"Cancel"];
    
    if ([alert runModal] == NSAlertFirstButtonReturn){
        [MBProgressHUD showStatus:@"Deleting..." onView:self.view];
        [[[[DBClientsManager authorizedClient] filesRoutes] deleteV2:uploadRecord.dbDirectroy] setResponseBlock:^(DBFILESDeleteResult * _Nullable result, DBFILESDeleteError * _Nullable routeError, DBRequestError * _Nullable networkError) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if (result) {
                [[[AppDelegate appDelegate] managedObjectContext] deleteObject:uploadRecord];
                [[AppDelegate appDelegate] saveCoreDataChanges];
                [self loadData];
            } else if (routeError) {
                [DBErrorHandler handleDeleteErrorWith:routeError];
            } else if (networkError) {
                [DBErrorHandler handleNetworkErrorWith:networkError];
            }
        }];
        [EventTracker logEventWithName:@"External Links" customAttributes:@{@"title":@"Update"} action:@"title" label:@"Update" value:@1];
    }
}

- (IBAction)showInFinderButtonTapped:(NSButton *)sender {
    UploadRecord *uploadRecord = [uploadRecords objectAtIndex:_dashboardTableView.selectedRow];
    if ([[NSFileManager defaultManager] fileExistsAtPath:uploadRecord.localBuildPath isDirectory:NO]) {
        NSURL *fileURL = [NSURL fileURLWithPath:uploadRecord.localBuildPath];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
    } else {
        [Common showAlertWithTitle:@"Error" andMessage:@"File not found."];
    }
}

- (IBAction)showInDropBoxButtonTapped:(NSButton *)sender {
    UploadRecord *uploadRecord = [uploadRecords objectAtIndex:_dashboardTableView.selectedRow];
    NSString *dropboxURLString = [NSString stringWithFormat:@"%@%@", abDropBoxAppBaseURL, uploadRecord.dbDirectroy];
    NSURL *dropboxURL = [NSURL URLWithString: dropboxURLString];
    [[NSWorkspace sharedWorkspace] openURL:dropboxURL];
}



@end
