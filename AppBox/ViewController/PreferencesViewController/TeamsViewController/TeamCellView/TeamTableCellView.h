//
//  TeamTableCellView.h
//  AppBox
//
//  Created by Vineet Choudhary on 30/09/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface TeamTableCellView : NSTableCellView
@property(nonatomic, weak) IBOutlet NSTextField * teamNameLabel;
@property(nonatomic, weak) IBOutlet NSTextField * teamDescLabel;

@end

NS_ASSUME_NONNULL_END
