//
//  AccountCellView.h
//  AppBox
//
//  Created by Vineet Choudhary on 05/02/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AccountCellView : NSTableCellView
@property(nonatomic, weak) IBOutlet NSTextField * accountIdLabel;
@property(nonatomic, weak) IBOutlet NSTextField * accountDescLabel;
@end
