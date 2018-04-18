//
//  ABHudViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 29/12/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

typedef enum : NSUInteger {
    HudTypeProgress,
    HudTypeStatus,
    HudTypeResult,
} HudType;

@interface ABHudViewController : NSViewController {
    __weak IBOutlet NSProgressIndicator *progressIndicator;
    __weak IBOutlet NSProgressIndicator *progressIndicatorAds;
    __weak IBOutlet NSTextField *progressLabel;
    __weak IBOutlet NSTextField *progressLabelAds;
    __weak IBOutlet NSTextField *adTitleLabel;
    __weak IBOutlet NSTextField *adSubtitleLabel;
    __weak IBOutlet NSImageView *resultImageView;
    __weak IBOutlet NSImageView *resultImageViewAds;
}
@property (weak) IBOutlet NSView *hudWithoutAds;
@property (weak) IBOutlet NSView *hudWithAds;
@property(nonatomic, weak) NSView *hudSuperView;
@property(nonatomic, weak) IBOutlet NSBox *adBoxView;
@property(nonatomic, strong) NSString *status;
@property(nonatomic, strong) NSString *adTitle;
@property(nonatomic, strong) NSString *adSubtitle;
@property(nonatomic, strong) NSString *adURL;
@property(nonatomic, strong) NSNumber *progress;
@property(nonatomic, assign) HudType hudType;
@property(nonatomic, assign) BOOL result;
@property(nonatomic, assign) BOOL showAds;

+ (ABHudViewController *)hudForView:(NSView *)view hide:(BOOL)hide;
- (IBAction)adViewClickGestureRecognized:(NSClickGestureRecognizer *)sender;
- (IBAction)previousButtonClicked:(NSButton *)sender;
- (IBAction)nextButtonClicked:(NSButton *)sender;

@end
