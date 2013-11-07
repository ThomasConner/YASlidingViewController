//
//  YASlidingViewController.m
//
//  Created by Thomas Conner on 11/7/13.
//  Copyright (c) 2013 Thomas Conner. All rights reserved.
//

#import "SlidingViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface SlidingViewController () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *leftUnderlayView;
@property (nonatomic, strong) UIView *topUnderlayView;
@property (nonatomic, strong) UIView *topOverlayView;

- (void)setDefaults;
- (void)createTopOverlayView;
- (void)removeTopOverlayView;

@end

@implementation SlidingViewController
@synthesize leftViewController = _leftViewController;
@synthesize topViewController = _topViewController;
@synthesize viewState = _viewState;

@synthesize leftUnderlayView = _leftUnderlayView;
@synthesize topUnderlayView = _topUnderlayView;
@synthesize topOverlayView = _topOverlayView;

#pragma mark -
#pragma mark Setup and Tear Down

- (id)init {
    self = [super init];
    if (self) {
        _viewState = SlidingViewStateClosed;
        _previousViewStates = [NSMutableArray array];
    }
    return self;
}

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setDefaults];
}

- (void)setDefaults {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        // iOS 7, offset it below the status bar
        self.topViewOffsetY = 20.0f;
    } else {
        self.topViewOffsetY = 0.0f;
    }
    
    self.allowOverswipe = NO;
    self.allowNavigationBarOnly = NO;
    self.peakAmount = 140.0f;
    self.peakThreshold = 0.5f;
    self.cornerRadius = 4.0f;
    self.shadowOpacity = 0.3f;
    self.shadowOffsetX = self.shadowOffsetY = 3.0f;
    self.shadowColor = [UIColor blackColor];
    self.shadowRadius = 4.0f;
    self.animationDelay = 0.0f;
    self.animationDuration = 0.25f;
}

#pragma mark -
#pragma mark Views

- (UIView *)leftUnderlayView {
    // Return the left underlay view if we have already created it
    if (_leftUnderlayView) {
        return _leftUnderlayView;
    }
    
    // Create the left underlay view
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
    view.backgroundColor = [UIColor clearColor];
    view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight;
    view.layer.masksToBounds = NO;
    view.layer.shadowColor = self.shadowColor.CGColor;
    view.layer.shadowOffset = CGSizeMake(self.shadowOffsetX, self.shadowOffsetY);
    view.layer.shadowRadius = self.shadowRadius;
    view.layer.shadowOpacity = self.shadowOpacity;
    UIBezierPath *menuUnderlayViewPath = [UIBezierPath bezierPathWithRect:view.bounds];
    view.layer.shadowPath = menuUnderlayViewPath.CGPath;
    view.layer.shouldRasterize = YES;
    view.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    // Set the left underlay view
    self.leftUnderlayView = view;
    
    // Add the left underlay view to the view
    [self.view addSubview:view];
    [self.view sendSubviewToBack:view];
    
    // Return the view
    return view;
}

- (UIView *)topUnderlayView {
    // Return the top underlay view if we have already created it
    if (_topUnderlayView) {
        return _topUnderlayView;
    }
    
    // Create the top underlay view
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, self.topViewOffsetY, self.view.frame.size.width, self.view.frame.size.height - self.topViewOffsetY)];
    view.backgroundColor = [UIColor clearColor];
    view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.layer.masksToBounds = NO;
    view.layer.shadowColor = self.shadowColor.CGColor;
    view.layer.shadowOffset = CGSizeMake(self.shadowOffsetX, self.shadowOffsetY);
    view.layer.shadowRadius = self.shadowRadius;
    view.layer.shadowOpacity = self.shadowOpacity;
    UIBezierPath *contentUnderlayViewPath = [UIBezierPath bezierPathWithRect:view.bounds];
    view.layer.shadowPath = contentUnderlayViewPath.CGPath;
    view.layer.shouldRasterize = YES;
    view.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    // Set the top underlay view
    self.topUnderlayView = view;
    
    // Add the top underlay view to the view
    [self.view addSubview:view];
    [self.view bringSubviewToFront:view];
    
    // Add the pan gesture recognizer
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    panGestureRecognizer.cancelsTouchesInView = NO;
    panGestureRecognizer.delegate = self;
    [view addGestureRecognizer:panGestureRecognizer];
    
    // Return the view
    return view;
}

- (UIView *)topOverlayView {
    // Return the top overlay view if we have already created it
    if (_topOverlayView) {
        return _topOverlayView;
    }
    
    // Adjust the frame for the navigation bar
    CGRect frame = self.topViewController.view.bounds;
    CGFloat navigationBarHeight = (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) && [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) ? 32.0f : 44.0f;
    frame.size.height -= navigationBarHeight;
    frame.origin.y += navigationBarHeight;
    
    // Create the view
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.backgroundColor = [UIColor clearColor];
    
    // Set the view
    self.topOverlayView = view;
    
    // Add the top overlay view to the view
    [self.topViewController.view addSubview:view];
    [self.topViewController.view bringSubviewToFront:view];
    
    // Add tap gesture recognizer
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedTopOverlayView)];
    [view addGestureRecognizer:tapGestureRecognizer];
    
    // Return the view
    return view;
}

- (void)createTopOverlayView {
    // Remove the overlay view
    [self removeTopOverlayView];
    
    // Just call the getter to create the overlay view
    __unused UIView *view = self.topOverlayView;
}

- (void)removeTopOverlayView {
    if (_topOverlayView) {
        [_topOverlayView removeFromSuperview];
        _topOverlayView = nil;
    }
}

#pragma mark -
#pragma mark View Rotation

- (BOOL)shouldAutorotate {
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // Adjust top view controller, underlay, and overlay view
    // Adjust left view controller and underlay view
    
    // Account for ipad to show left view controller
    
    CGRect contentRect = self.view.bounds;
    
    // If the device is a pad and the orientation is landscape
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        // Adjust the top underlay view frame
        CGRect topUnderlayViewFrame = CGRectMake(self.peakAmount, 0.0f, contentRect.size.width - self.peakAmount, contentRect.size.height);
        self.topUnderlayView.frame = CGRectIntegral(topUnderlayViewFrame);
        
        // Update the view state
        [_previousViewStates addObject:[NSNumber numberWithInt:self.viewState]];
        _viewState = SlidingViewStateLocked;
        
        // Remove the top overlay view
        if (self.topOverlayView) {
            [self.topOverlayView removeFromSuperview];
            self.topOverlayView = nil;
        }
    }
    else {
        // Adjust the top underlay view frame
        CGRect rect = CGRectMake(0.0f, self.topViewOffsetY, self.view.bounds.size.width, self.view.bounds.size.height - self.topViewOffsetY);
        self.topUnderlayView.frame = CGRectIntegral(rect);
        
        // If the view state is locked and we have a previous view state
        if (self.viewState == SlidingViewStateLocked && _previousViewStates.count > 0) {
            NSNumber *prevViewState = [_previousViewStates objectAtIndex:_previousViewStates.count - 1];
            _viewState = prevViewState.intValue;
            [_previousViewStates removeLastObject];
        }
        
        // If the view state is openeed
        if (self.viewState == SlidingViewStateOpened) {
            self.topUnderlayView.frame = CGRectOffset(contentRect, self.peakAmount, 0.0f);
            
            // Create the top overlay view
            [self createTopOverlayView];
        }
    }
    
    // Adjust the shadows
    UIBezierPath *leftUnderlayViewPath = [UIBezierPath bezierPathWithRoundedRect:self.leftUnderlayView.bounds cornerRadius:self.cornerRadius];
    self.leftUnderlayView.layer.shadowPath = leftUnderlayViewPath.CGPath;
    UIBezierPath *topUnderlayViewPath = [UIBezierPath bezierPathWithRoundedRect:self.topUnderlayView.bounds cornerRadius:self.cornerRadius];
    self.topUnderlayView.layer.shadowPath = topUnderlayViewPath.CGPath;
}

#pragma mark -
#pragma mark View Controllers

- (void)displayTopViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.topViewController = viewController;
    [self hideLeftAnimated:animated];
}

- (void)setLeftViewController:(UIViewController *)leftViewController {
    // Remove the old left view controller
    if (self.leftViewController) {
        [self.leftViewController.view removeFromSuperview];
        [self.leftViewController willMoveToParentViewController:nil];
        [self.leftViewController removeFromParentViewController];
    }
    
    // Set the new left view controller
    [leftViewController.view removeFromSuperview];
    [leftViewController willMoveToParentViewController:nil];
    [leftViewController removeFromParentViewController];
    _leftViewController = leftViewController;
    [self.leftUnderlayView addSubview:leftViewController.view];
    [self addChildViewController:leftViewController];
    [leftViewController didMoveToParentViewController:self];
    
    // Adjust the frame
    leftViewController.view.frame = CGRectIntegral(self.leftUnderlayView.bounds);
}

- (void)setTopViewController:(UIViewController *)topViewController {
    // Remove the old top view controller
    if (self.topViewController) {
        [self.topViewController.view removeFromSuperview];
        [self.topViewController willMoveToParentViewController:nil];
        [self.topViewController removeFromParentViewController];
    }
    
    // Set the new top view controller
    [topViewController.view removeFromSuperview];
    [topViewController willMoveToParentViewController:nil];
    [topViewController removeFromParentViewController];
    _topViewController = topViewController;
    [self.topUnderlayView addSubview:topViewController.view];
    [self addChildViewController:topViewController];
    [topViewController didMoveToParentViewController:self];
    
    // Added a corner radius
    topViewController.view.autoresizingMask = self.topUnderlayView.autoresizingMask;
    topViewController.view.layer.masksToBounds = YES;
    topViewController.view.layer.cornerRadius = self.cornerRadius;
    
    // Adjust the frame
    topViewController.view.frame = CGRectIntegral(self.topUnderlayView.bounds);
}

#pragma mark -
#pragma mark Show and Hide Left

- (void)tappedTopOverlayView {
    [self hideLeftAnimated:YES];
}

- (void)toggleLeftAnimated:(BOOL)animated {
    if (self.viewState == SlidingViewStateClosed) {
        [self showLeftAnimated:animated];
    }
    else if (self.viewState == SlidingViewStateOpened) {
        [self hideLeftAnimated:animated];
    }
}

- (void)showLeftAnimated:(BOOL)animated {
    // Return if the view state is locked
    if (self.viewState == SlidingViewStateLocked) {
        return;
    }
    
    // Get the rect
    CGRect rect = CGRectMake(0.0f, self.topViewOffsetY, self.view.bounds.size.width, self.view.bounds.size.height - self.topViewOffsetY);
    
    // Dismiss the keyboard if it is showing
    [self.topViewController.view endEditing:YES];
    
    if (animated) {
        [UIView animateWithDuration:self.animationDuration
                              delay:self.animationDelay
                            options:UIViewAnimationOptionCurveEaseInOut  | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             // Adjust the top underlay view frame
                             self.topUnderlayView.frame = CGRectOffset(rect, self.peakAmount, 0.0f);
                         }
                         completion:^(BOOL finished) {
                             if (finished) {
                                 // Update the view state
                                 [_previousViewStates addObject:[NSNumber numberWithInt:self.viewState]];
                                 _viewState = SlidingViewStateOpened;
                                 
                                 // Create the top overlay view
                                 [self createTopOverlayView];
                             }
                         }];
    }
    else {
        // Adjust the top underlay view frame
        self.topUnderlayView.frame = CGRectOffset(rect, self.peakAmount, 0.0f);
        
        // Update the view state
        [_previousViewStates addObject:[NSNumber numberWithInt:self.viewState]];
        _viewState = SlidingViewStateOpened;

        // Create the top overlay view
        [self createTopOverlayView];
    }
}

- (void)hideLeftAnimated:(BOOL)animated {
    // Return if the view state is locked
    if (self.viewState == SlidingViewStateLocked) {
        return;
    }
    
    // Get the rect
    CGRect rect = CGRectMake(0.0f, self.topViewOffsetY, self.view.bounds.size.width, self.view.bounds.size.height - self.topViewOffsetY);
    
    if (animated) {
        [UIView animateWithDuration:self.animationDuration
                              delay:self.animationDelay
                            options:UIViewAnimationOptionCurveEaseInOut  | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             // Adjust the top underlay view frame
                             self.topUnderlayView.frame = CGRectIntegral(rect);
                         }
                         completion:^(BOOL finished) {
                             if (finished) {
                                 // Update the view state
                                 [_previousViewStates addObject:[NSNumber numberWithInt:self.viewState]];
                                 _viewState = SlidingViewStateClosed;
                                 
                                 // Remove the overlay view
                                 [self removeTopOverlayView];
                             }
                         }];
    }
    else {
        // Adjust the top underlay view frame
        self.topUnderlayView.frame = CGRectIntegral(rect);
        
        // Update the view state
        [_previousViewStates addObject:[NSNumber numberWithInt:self.viewState]];
        _viewState = SlidingViewStateClosed;
        
        // Remove the overlay view
        [self removeTopOverlayView];
    }
}


#pragma mark -
#pragma mark Swiping

- (void)handleSwipe:(UIPanGestureRecognizer *)gestureRecognizer {
    // Return if the view state is locked
    if (self.viewState == SlidingViewStateLocked) {
        return;
    }
    
    // If we are beginning
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        // Dismiss the keyboard if it is showing
        [self.topViewController.view endEditing:YES];
        
        CGPoint startingPoint = [gestureRecognizer locationInView:self.view];
        
        // we only trigger a swipe if either navigationBarOnly is deactivated
        // or we swiped in the navigationBar
        if (!self.allowNavigationBarOnly || startingPoint.y <= 44.0f) {
            [_previousViewStates addObject:[NSNumber numberWithInt:self.viewState]];
            _viewState = SlidingViewStateDragging;
        }
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateChanged && self.viewState == SlidingViewStateDragging) {
        CGPoint translation = [gestureRecognizer translationInView:self.view];
        [gestureRecognizer setTranslation:CGPointMake(0, 0) inView:self.view];
        
        [UIView animateWithDuration:0.01f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             gestureRecognizer.view.center = CGPointMake(gestureRecognizer.view.center.x + translation.x, gestureRecognizer.view.center.y);
                             
                             // Get the rect
                             CGRect rect = CGRectMake(0.0f, self.topViewOffsetY, self.view.bounds.size.width, self.view.bounds.size.height - self.topViewOffsetY);
                             
                             // Adjust the view
                             if (gestureRecognizer.view.frame.origin.x > self.peakAmount) {
                                 gestureRecognizer.view.frame = CGRectIntegral(CGRectOffset(rect, self.peakAmount, 0.0f));
                             }
                             else if (gestureRecognizer.view.frame.origin.x < 0.0f) {
                                 gestureRecognizer.view.frame = CGRectIntegral(rect);
                             }
                         }
                         completion:^(BOOL finished) {
                             // Nothing to do
                         }];
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateEnded && self.viewState == SlidingViewStateDragging) {
        CGPoint velocity = [gestureRecognizer velocityInView:self.view];
        
        // If the swipe was to the right
        if (velocity.x > 0) {
            if (self.topUnderlayView.frame.origin.x <= 100.0f) {
                [self hideLeftAnimated:YES];
            }
            else {
                [self showLeftAnimated:YES];
            }
        }
        // else is must have been to the left
        else {
            if (self.topUnderlayView.frame.origin.x >= 100.0f) {
                [self showLeftAnimated:YES];
            } else {
                [self hideLeftAnimated:YES];
            }
        }
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer {
    CGPoint startingPoint = [panGestureRecognizer locationInView:self.view];
    
    // we only trigger a swipe if either navigationBarOnly is deactivated
    // or we swiped in the navigationBar
    if (!self.allowNavigationBarOnly || startingPoint.y <= 44.0f) {
        return YES;
    }
    
    return NO;
}

@end