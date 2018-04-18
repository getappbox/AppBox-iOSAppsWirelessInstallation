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
    NSNumber *adIndex;
}

#pragma mark - Hud View
+ (ABHudViewController *)hudForView:(NSView *)view hide:(BOOL)hide{
    if ([AdStore shared].ads.count == 0){
        [AdStore loadAds];
    }
    static NSMutableDictionary *hudDictionary = nil;
    if (hudDictionary == nil) {
        hudDictionary = [[NSMutableDictionary alloc] init];
    }
    if (hide) {
        if ([hudDictionary.allKeys containsObject:view.description]) {
            ABHudViewController *hud = [hudDictionary objectForKey:view.description];
            [hud.view removeFromSuperview];
        }
        return nil;
    } else {
        ABHudViewController *hud;
        if ([hudDictionary.allKeys containsObject:view.description]) {
            hud = [hudDictionary objectForKey:view.description];
        } else {
            hud = [[ABHudViewController alloc] initWithNibName:NSStringFromClass([ABHudViewController class]) bundle:nil];
            view.postsFrameChangedNotifications = YES;
            hud.view.frame = view.frame;
            hud.showAds = YES;
            hud.hudSuperView = view;
            [[NSNotificationCenter defaultCenter] addObserver:hud selector:@selector(viewFrameChanged:) name:NSViewFrameDidChangeNotification object:nil];
            [hudDictionary setObject:hud forKey:view.description];
            [hud updateAd:nil];
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
    [progressIndicatorAds setContentFilters:[NSArray arrayWithObjects:lighten, nil]];
    
    //set default adindex
    adIndex = @0;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:abAdsLoadCompleted object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [self updateAd:nil];
    }];
}

- (void)viewFrameChanged:(NSNotification *)notifictaion {
    self.view.frame = self.hudSuperView.frame;
}

#pragma mark - Ad Manager

-(void)updateAd:(NSNumber *)index{
    NSArray<Ads *> *ads = [[AdStore shared] ads];
    NSPredicate *activeAdsPredicate = [NSPredicate predicateWithFormat:@"active = 1"];
    ads = [ads filteredArrayUsingPredicate:activeAdsPredicate];
    if (index == nil) {
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
    } else {
        if (ads.count > index.integerValue) {
            Ads *ad = [ads objectAtIndex:index.integerValue];
            if (ad) {
                self.adURL = ad.url;
                self.adTitle = ad.title;
                self.adSubtitle = ad.subtitle;
            }
        } else {
            index = @0;
        }
    }
}

#pragma mark - Properties

-(void)setShowAds:(BOOL)showAds{
    _showAds = showAds;
    //show ads
    [self.adBoxView setHidden:!showAds];
    [self.hudWithAds setHidden:!showAds];
    //hide ads
    [self.hudWithoutAds setHidden:showAds];
}

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
    [progressLabel setStringValue: status];
    [progressLabelAds setStringValue: status];
}

-(void)setProgress:(NSNumber *)progress{
    _progress = progress;
    [resultImageView setHidden:YES];
    [resultImageViewAds setHidden:YES];
    [progressIndicator setHidden:NO];
    [progressIndicatorAds setHidden:NO];
    [progressIndicator startAnimation:self];
    [progressIndicatorAds startAnimation:self];
    if (progress.integerValue == -1){
        [progressIndicator setIndeterminate: YES];
        [progressIndicatorAds setIndeterminate: YES];
    } else {
        [progressIndicator setIndeterminate: NO];
        [progressIndicator setDoubleValue: progress.doubleValue];
        [progressIndicatorAds setIndeterminate: NO];
        [progressIndicatorAds setDoubleValue: progress.doubleValue];
    }
}

-(void)setResult:(BOOL)result{
    _result = result;
    [resultImageView setHidden:NO];
    [resultImageViewAds setHidden:NO];
    [progressIndicator setHidden:YES];
    [progressIndicatorAds setHidden:YES];
    NSImage *resultImage = result ? [NSImage imageNamed:@"Check"] : [NSImage imageNamed:@"Multiply"];
    [resultImageView setImage:resultImage];
    [resultImageViewAds setImage:resultImage];
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
    if (self.adURL != nil) {
        NSString *utm = @"?utm_source=appbox&utm_medium=appbox-native&utm_campaign=appbox";
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.adURL, utm]];
        if (url){
            [EventTracker logEventSettingWithType:LogEventAdsClicked andSettings:@{@"Title": self.adTitle, @"URL": self.adURL}];
            [[NSWorkspace sharedWorkspace] openURL:url];
        }
    }
}

- (IBAction)previousButtonClicked:(NSButton *)sender {
    if (adIndex.integerValue > 0) {
        adIndex = [NSNumber numberWithInteger:(adIndex.integerValue - 1)];
    } else {
        adIndex = [NSNumber numberWithInteger:([[AdStore shared] ads].count - 1)];
    }
    [self updateAd:adIndex];
}

- (IBAction)nextButtonClicked:(NSButton *)sender {
    if (adIndex.integerValue ==( [[AdStore shared] ads].count - 1)) {
        adIndex = @0;
    } else {
        adIndex = [NSNumber numberWithInteger:(adIndex.integerValue + 1)];
    }
    [self updateAd:adIndex];
}
@end
