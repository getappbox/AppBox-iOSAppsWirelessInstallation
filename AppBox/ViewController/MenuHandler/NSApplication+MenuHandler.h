//
//  NSApplication+MenuHandler.h
//  AppBox
//
//  Created by Vineet Choudhary on 02/01/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSApplication (MenuHandler)

- (IBAction)logoutGmailTapped:(NSMenuItem *)sender;
- (IBAction)logoutDropBoxTapped:(NSMenuItem *)sender;

@end
