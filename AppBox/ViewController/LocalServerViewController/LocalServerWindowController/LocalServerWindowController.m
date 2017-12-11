//
//  LocalServerWindowController.m
//  AppBox
//
//  Created by Vineet Choudhary on 11/12/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "LocalServerWindowController.h"

@interface LocalServerWindowController ()

@end

@implementation LocalServerWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(BOOL)windowShouldClose:(id)sender{
    //show alert if anything in processing
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText: @"Are you sure you want to close the \"AppBox Local Server\"?"];
    [alert setInformativeText:@"Closing this will stop the \"AppBox Local Server\"."];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert addButtonWithTitle:@"Stop Local Server"];
    [alert addButtonWithTitle:@"NO"];
    if ([alert runModal] == NSAlertFirstButtonReturn){
        [[NSNotificationCenter defaultCenter] postNotificationName:abStopAppBoxLocalServer object:nil];
        return YES;
    } else {
        return NO;
    }
}


@end
