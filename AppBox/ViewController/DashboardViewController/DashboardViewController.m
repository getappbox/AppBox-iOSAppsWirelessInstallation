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
    NSError *error;
    NSFetchRequest *fetchRequest = [UploadRecord fetchRequest];
    NSArray *fetchResults = [[[AppDelegate appDelegate] managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    if (error){
        //error in fetch request
        [Common showAlertWithTitle:@"Error" andMessage:error.localizedDescription];
    }else if (fetchResults.count > 0){
        uploadRecords = [NSMutableArray arrayWithArray:fetchResults];
    }
    [_dashboardTableView reloadData];
}

#pragma mark - NSTableView Delegate
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return uploadRecords.count;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    UploadRecord *uploadRecord = [uploadRecords objectAtIndex:row];
    NSTableCellView *cell = [tableView makeViewWithIdentifier:ShortURLCellId owner:nil];
    if (tableColumn == [tableView.tableColumns objectAtIndex:DashBoardColumnName]) {
        [cell.textField setStringValue: uploadRecord.project.name];
    } else if (tableColumn == [tableView.tableColumns objectAtIndex: DashBoardColumnVersion]){
        [cell.textField setStringValue:uploadRecord.version];
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
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
        context.duration = 0.25;
        context.allowsImplicitAnimation = YES;
        actionViewHeightConstraint.constant = 65;
        [self.view layoutSubtreeIfNeeded];
    } completionHandler:nil];
    return YES;
}

@end
