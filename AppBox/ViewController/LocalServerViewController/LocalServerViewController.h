//
//  LocalServerViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 10/12/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LocalServerHandler.h"

@interface LocalServerViewController : NSViewController{
    
    __weak IBOutlet NSLevelIndicator *serverStatusIndicator;
    __unsafe_unretained IBOutlet NSTextView *serverLogTextView;
}

@end
