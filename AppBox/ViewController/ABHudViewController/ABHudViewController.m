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
            [hud updateAd];
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

#pragma mark - Ad Manager

-(void)updateAd{
    NSArray<Ads *> *ads = [[AdStore shared] ads];
    NSPredicate *activeAdsPredicate = [NSPredicate predicateWithFormat:@"active = 1"];
    ads = [ads filteredArrayUsingPredicate:activeAdsPredicate];
    if (ads.count > 0) {
        NSPredicate *featuredPredicate = [NSPredicate predicateWithFormat:@"featured = 1"];
        NSArray<Ads *> *featuredAds = [ads filteredArrayUsingPredicate:featuredPredicate];
        Ads *ad = nil;
        if (featuredAds.count > 0) {
            ad = [featuredAds lastObject];
        } else {
            int random = arc4random() % (ads.count - 1);
            if (random < ads.count){
                ad = [ads objectAtIndex:random];
            } else {
                ad = [ads firstObject];
            }
        }
        if (ad) {
            self.adURL = ad.url;
            self.adTitle = ad.title;
            self.adSubtitle = ad.subtitle;
        }
    }
}

#pragma mark - Properties

-(void)setAdURL:(NSString *)adURL{
    _adURL = adURL;
}

-(void)setAdTitle:(NSString *)adTitle{
    _adTitle = adTitle;
    adTitleLabel.stringValue = adTitle;
}

-(void)setAdSubtitle:(NSString *)adSubtitle{
    _adSubtitle = adSubtitle;
    adSubtitleLabel.stringValue = adSubtitle;
}

-(void)setStatus:(NSString *)status{
    _status = status;
    progressLabel.stringValue = status;
}

-(void)setProgress:(NSNumber *)progress{
    _progress = progress;
    [progressIndicator startAnimation:self];
    if (progress.integerValue == -1){
        [progressIndicator setIndeterminate: YES];
    } else {
        [progressIndicator setIndeterminate: NO];
        progressIndicator.doubleValue = progress.doubleValue;
    }
}

-(void)setResult:(BOOL)result{
    _result = result;
    NSImage *resultImage = result ? [NSImage imageNamed:@"Check"] : [NSImage imageNamed:@"Multiply"];
    [resultImageView setImage:resultImage];
}

-(void)setHudType:(HudType)hudType{
    switch (hudType) {
        case HudTypeResult:{
            [resultImageView setHidden:NO];
            [progressIndicator setHidden:YES];
        }break;
            
        case HudTypeStatus: {
            [progressIndicator setHidden:YES];
            [resultImageView setHidden:YES];
        }break;
            
        case HudTypeProgress: {
            [progressIndicator setHidden:NO];
            [resultImageView setHidden:YES];
        }break;
            
        default:
            break;
    }
}

#pragma mark - Actions

- (IBAction)adViewClickGestureRecognized:(NSClickGestureRecognizer *)sender {
    NSURL *url = [NSURL URLWithString:self.adURL];
    if (url){
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}
@end
