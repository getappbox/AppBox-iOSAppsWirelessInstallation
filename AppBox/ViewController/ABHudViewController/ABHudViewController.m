//
//  ABHudViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 29/12/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "ABHudViewController.h"

@interface ABHudViewController ()

@end

@implementation ABHudViewController {
    
}

#pragma mark - Hud View
+ (ABHudViewController *)hudForView:(NSView *)view hide:(BOOL)hide{
    static NSMutableDictionary *hudDictionary = nil;
    if (hudDictionary == nil) {
        hudDictionary = [[NSMutableDictionary alloc] init];
    }
    if (hide && [hudDictionary.allKeys containsObject:view.description]) {
        ABHudViewController *hud = [hudDictionary objectForKey:view.description];
        [hud.view removeFromSuperview];
        return nil;
    } else {
        ABHudViewController *hud;
        if ([hudDictionary.allKeys containsObject:view.description]) {
            hud = [hudDictionary objectForKey:view.description];
        } else {
            hud = [[ABHudViewController alloc] initWithNibName:NSStringFromClass([ABHudViewController class]) bundle:nil];
            view.postsFrameChangedNotifications = YES;
            hud.view.frame = view.frame;
            hud.hudSuperView = view;
            [[NSNotificationCenter defaultCenter] addObserver:hud selector:@selector(viewFrameChanged:) name:NSViewFrameDidChangeNotification object:nil];
            [hudDictionary setObject:hud forKey:view.description];
        }
        if (![view.subviews containsObject:hud.view]) {
            [view addSubview:hud.view];
        }
        return hud;
    }
}

#pragma mark - View Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //White color progress indicator
    CIFilter *lighten = [CIFilter filterWithName:@"CIColorControls"];
    [lighten setDefaults];
    [lighten setValue:@1 forKey:@"inputBrightness"];
    [progressIndicator setContentFilters:[NSArray arrayWithObjects:lighten, nil]];
}

- (void)viewFrameChanged:(NSNotification *)notifictaion {
    self.view.frame = self.hudSuperView.frame;
}

#pragma mark - Properties

-(void)setAdURL:(NSString *)adURL{
    
}

-(void)setAdTitle:(NSString *)adTitle{
    adTitleLabel.stringValue = adTitle;
}

-(void)setAdSubtitle:(NSString *)adSubtitle{
    adSubtitleLabel.stringValue = adSubtitle;
}

-(void)setStatus:(NSString *)status{
    progressLabel.stringValue = status;
}

-(void)setProgress:(NSNumber *)progress{
    [progressIndicator startAnimation:self];
    [progressIndicator setHidden:(progress.integerValue == -2)];
    [resultImageView setHidden:YES];
    if (progress.integerValue == -1){
        [progressIndicator setIndeterminate: YES];
    } else {
        [progressIndicator setIndeterminate: NO];
        progressIndicator.doubleValue = progress.doubleValue;
    }
}

-(void)setResult:(BOOL)result{
    [resultImageView setHidden:NO];
    [progressIndicator setHidden:YES];
    NSImage *resultImage = result ? [NSImage imageNamed:@"Check"] : [NSImage imageNamed:@"Multiply"];
    [resultImageView setImage:resultImage];
}

#pragma mark - Actions

- (IBAction)adViewClickGestureRecognized:(NSClickGestureRecognizer *)sender {
    NSURL *url = [NSURL URLWithString:self.adURL];
    if (url){
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}
@end
