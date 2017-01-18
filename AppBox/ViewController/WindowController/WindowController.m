//
//  WindowController.m
//  AppBox
//
//  Created by Vineet Choudhary on 18/01/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "WindowController.h"

@interface WindowController ()

@end

@implementation WindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(BOOL)windowShouldClose:(id)sender{
    if ([[AppDelegate appDelegate] processing]){
        //show alert if anything in processing
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText: @"Are you sure you want to close the \"AppBox\"?"];
        [alert setInformativeText:@"Closing this will stop the current task."];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert addButtonWithTitle:@"Stop Tasks"];
        [alert addButtonWithTitle:@"NO"];
        if ([alert runModal] == NSAlertFirstButtonReturn){
            return YES;
        }
        return NO;
    }else{
        return YES;
    }
}

@end
