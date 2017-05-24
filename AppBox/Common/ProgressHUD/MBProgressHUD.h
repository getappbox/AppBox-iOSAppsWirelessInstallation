#import <Foundation/Foundation.h>
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    #import <CoreGraphics/CoreGraphics.h>
    #if __IPHONE
        #import <UIKit/UIKit.h>
    #endif  // __IPHONE
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    #import <Cocoa/Cocoa.h>
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

@protocol MBProgressHUDDelegate;

typedef enum {
	/** Progress is shown using an UIActivityIndicatorView. This is the default. */
	MBProgressHUDModeIndeterminate,
	/** Progress is shown using a round, pie-chart like, progress view. */
	MBProgressHUDModeDeterminate,
	/** Progress is shown using a horizontal progress bar */
	MBProgressHUDModeDeterminateHorizontalBar,
	/** Progress is shown using a ring-shaped progress view. */
	MBProgressHUDModeAnnularDeterminate,
	/** Shows a custom view */
	MBProgressHUDModeCustomView,
	/** Shows only labels */
	MBProgressHUDModeText
} MBProgressHUDMode;

typedef enum {
	/** Opacity animation */
	MBProgressHUDAnimationFade,
	/** Opacity + scale animation */
	MBProgressHUDAnimationZoom,
	MBProgressHUDAnimationZoomOut = MBProgressHUDAnimationZoom,
	MBProgressHUDAnimationZoomIn
} MBProgressHUDAnimation;


#ifndef MB_INSTANCETYPE
#if __has_feature(objc_instancetype)
#define MB_INSTANCETYPE instancetype
#else
#define MB_INSTANCETYPE id
#endif
#endif

#ifndef MB_STRONG
#if __has_feature(objc_arc)
#define MB_STRONG strong
#else
#define MB_STRONG retain
#endif
#endif

#ifndef MB_WEAK
#if __has_feature(objc_arc_weak)
#define MB_WEAK weak
#elif __has_feature(objc_arc)
#define MB_WEAK unsafe_unretained
#else
#define MB_WEAK assign
#endif
#endif

#if NS_BLOCKS_AVAILABLE
typedef void (^MBProgressHUDCompletionBlock)();
#endif

#if !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

enum {
    NSViewAutoresizingNone                 = NSViewNotSizable,
    NSViewAutoresizingFlexibleLeftMargin   = NSViewMinXMargin,
    NSViewAutoresizingFlexibleWidth        = NSViewWidthSizable,
    NSViewAutoresizingFlexibleRightMargin  = NSViewMaxXMargin,
    NSViewAutoresizingFlexibleTopMargin    = NSViewMaxYMargin,
    NSViewAutoresizingFlexibleHeight       = NSViewHeightSizable,
    NSViewAutoresizingFlexibleBottomMargin = NSViewMinYMargin
};

#endif

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@interface MBProgressHUD : UIView
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@interface MBProgressHUD : NSView
{
    CGColorRef _cgColorFromNSColor;
}
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

#pragma mark - Class methods


#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (MB_INSTANCETYPE)showHUDAddedTo:(UIView *)view animated:(BOOL)animated;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (MB_INSTANCETYPE)showHUDAddedTo:(NSView *)view animated:(BOOL)animated;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (BOOL)hideHUDForView:(UIView *)view animated:(BOOL)animated;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (BOOL)hideHUDForView:(NSView *)view animated:(BOOL)animated;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)


#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (NSUInteger)hideAllHUDsForView:(UIView *)view animated:(BOOL)animated;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (NSUInteger)hideAllHUDsForView:(NSView *)view animated:(BOOL)animated;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)


#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (MB_INSTANCETYPE)HUDForView:(UIView *)view;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (MB_INSTANCETYPE)HUDForView:(NSView *)view;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)


#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (NSArray *)allHUDsForView:(UIView *)view;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (NSArray *)allHUDsForView:(NSView *)view;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)


#if !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (CGColorRef)NSColorToCGColor:(NSColor *)nscolor;
#endif  // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

#pragma mark - Lifecycle


#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (id)initWithWindow:(UIWindow *)window;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (id)initWithWindow:(NSWindow *)window;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)


#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (id)initWithView:(UIView *)view;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (id)initWithView:(NSView *)view;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

#pragma mark - Show & hide


- (void)show:(BOOL)animated;

- (void)hide:(BOOL)animated;

- (void)hide:(BOOL)animated afterDelay:(NSTimeInterval)delay;

- (BOOL)isFinished;

#pragma mark - Threading

- (void)showWhileExecuting:(SEL)method onTarget:(id)target withObject:(id)object animated:(BOOL)animated;

#if NS_BLOCKS_AVAILABLE

- (void)showAnimated:(BOOL)animated whileExecutingBlock:(dispatch_block_t)block;

- (void)showAnimated:(BOOL)animated whileExecutingBlock:(dispatch_block_t)block completionBlock:(MBProgressHUDCompletionBlock)completion;

- (void)showAnimated:(BOOL)animated whileExecutingBlock:(dispatch_block_t)block onQueue:(dispatch_queue_t)queue;

- (void)showAnimated:(BOOL)animated whileExecutingBlock:(dispatch_block_t)block onQueue:(dispatch_queue_t)queue
     completionBlock:(MBProgressHUDCompletionBlock)completion;

#pragma mark - Properties

@property (copy) MBProgressHUDCompletionBlock completionBlock;

#endif  // NS_BLOCKS_AVAILABLE

@property (assign) MBProgressHUDMode mode;
@property (assign) MBProgressHUDAnimation animationType;

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) UIView *customView;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) NSView *customView;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

@property (MB_WEAK) id<MBProgressHUDDelegate> delegate;
@property (copy) NSString *labelText;
@property (copy) NSString *detailsLabelText;
@property (assign) float opacity;

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) UIColor *color;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) NSColor *color;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

@property (assign) float xOffset;
@property (assign) float yOffset;
@property (assign) float spinsize;
@property (assign) float margin;
@property (assign) float cornerRadius;
@property (assign) BOOL dimBackground;
@property (assign) BOOL dismissible;
@property (assign) float graceTime;
@property (assign) float minShowTime;
@property (assign) BOOL taskInProgress;
@property (assign) BOOL removeFromSuperViewOnHide;

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) UIFont* labelFont;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) NSFont* labelFont;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) UIColor* labelColor;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) NSColor* labelColor;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) UIFont* detailsLabelFont;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) NSFont* detailsLabelFont;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) UIColor* detailsLabelColor;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) NSColor* detailsLabelColor;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

@property (assign) float progress;
@property (assign) CGSize minSize;
@property (assign, getter = isSquare) BOOL square;

@end


@protocol MBProgressHUDDelegate <NSObject>

@optional

- (void)hudWasHidden:(MBProgressHUD *)hud;
- (void)hudWasHiddenAfterDelay:(MBProgressHUD *)hud;
- (void)hudWasTapped:(MBProgressHUD *)hud;

#if !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (CGColorRef)NSColorToCGColor:(NSColor *)nscolor;
#endif  // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

@end

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@interface MBRoundProgressView : UIView
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@interface MBRoundProgressView : NSView
{
    CGColorRef _cgColorFromNSColor;
}
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

@property (nonatomic, assign) float progress;

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (nonatomic, MB_STRONG) UIColor *progressTintColor;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (nonatomic, MB_STRONG) NSColor *progressTintColor;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (nonatomic, MB_STRONG) UIColor *backgroundTintColor;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (nonatomic, MB_STRONG) NSColor *backgroundTintColor;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

@property (nonatomic, assign, getter = isAnnular) BOOL annular;

@end


#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@interface MBBarProgressView : UIView
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@interface MBBarProgressView : NSView
{
    CGColorRef _cgColorFromNSColor;
}
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

@property (nonatomic, assign) float progress;


#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (nonatomic, MB_STRONG) UIColor *lineColor;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (nonatomic, MB_STRONG) NSColor *lineColor;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (nonatomic, MB_STRONG) UIColor *progressRemainingColor;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (nonatomic, MB_STRONG) NSColor *progressRemainingColor;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (nonatomic, MB_STRONG) UIColor *progressColor;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (nonatomic, MB_STRONG) NSColor *progressColor;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

#if !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (CGColorRef)NSColorToCGColor:(NSColor *)nscolor;
#endif  // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

@end

#if !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

@interface MBSpinnerProgressView : NSProgressIndicator

@end

@interface YRKSpinningProgressIndicator : NSView {
    int _position;
    int _numFins;
#if __has_feature(objc_arc)
    NSMutableArray *_finColors;
#else
    NSColor **_finColors;
#endif
    
    BOOL _isAnimating;
    BOOL _isFadingOut;
    NSTimer *_animationTimer;
	NSThread *_animationThread;
    
    NSColor *_foreColor;
    NSColor *_backColor;
    BOOL _drawsBackground;
    
    BOOL _displayedWhenStopped;
    BOOL _usesThreadedAnimation;
	
    // For determinate mode
    BOOL _isIndeterminate;
    double _currentValue;
    double _maxValue;
}

@property (nonatomic, retain) NSColor *color;
@property (nonatomic, retain) NSColor *backgroundColor;
@property (nonatomic, assign) BOOL drawsBackground;

@property (nonatomic, assign, getter=isDisplayedWhenStopped) BOOL displayedWhenStopped;
@property (nonatomic, assign) BOOL usesThreadedAnimation;

@property (nonatomic, assign, getter=isIndeterminate) BOOL indeterminate;
@property (nonatomic, assign) double doubleValue;
@property (nonatomic, assign) double maxValue;

- (void)stopAnimation:(id)sender;
- (void)startAnimation:(id)sender;

@end

#endif  // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
