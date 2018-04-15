//
//  DragDropView.m
//  AppBox
//
//  Created by Vineet Choudhary on 15/04/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import "DragDropView.h"

@implementation DragDropView{
    NSSet *acceptedType;
    NSDictionary *readOptions;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    acceptedType = [NSSet setWithObjects:@"com.apple.iTunes.ipa", @"com.apple.dt.document.workspace", @"com.apple.xcode.project", NSURLPboardType, nil];
    readOptions = @{NSPasteboardURLReadingContentsConformToTypesKey: acceptedType.allObjects};
    [self registerForDraggedTypes:acceptedType.allObjects];
}

- (NSString *)getFilePath:(id<NSDraggingInfo>)sender{
    NSPasteboard *pasteboard = [sender draggingPasteboard];
    NSDictionary *options = [NSDictionary dictionaryWithObject:@YES forKey:NSPasteboardURLReadingFileURLsOnlyKey];
    NSArray *results = [pasteboard readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]] options:options];
    return (results.count > 0) ? [results.firstObject relativePath] : nil;
}

-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender{
    NSLog(@"draggingEntered");
    if (sender.draggingPasteboard.pasteboardItems.count > 1 && [AppDelegate appDelegate].processing) {
        return NSDragOperationNone;
    }
    NSString *filePath = [self getFilePath:sender];
    return ([acceptedType intersectsSet:[NSSet setWithArray:sender.draggingPasteboard.types]] && filePath.validURL) ? NSDragOperationCopy : NSDragOperationNone;
}

-(BOOL)performDragOperation:(id<NSDraggingInfo>)sender{
    NSString *filePath = [self getFilePath:sender];
    NSLog(@"%@", filePath);
    [[AppDelegate appDelegate] openFileWithPath:filePath];
    return YES;
}

@end
