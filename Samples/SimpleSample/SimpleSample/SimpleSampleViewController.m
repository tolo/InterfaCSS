//
//  SimpleSampleViewController.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-24.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "SimpleSampleViewController.h"

// Define this to enable using ISSViewBuilder shorthand macros:
//#define ISS_VIEW_BUILDER_SHORTHAND_ENABLED

#import <InterfaCSS.h>
#import <InterfaCSS/ISSViewBuilder.h>
#import <InterfaCSS/UIView+InterfaCSS.h>


@interface SimpleSampleViewController ()

@property (nonatomic, strong) UILabel* mainTitleLabel;
@property (nonatomic, strong) UIButton* mainTitleButton;

@property (nonatomic, strong) UILabel* contentTitleLabel;
@property (nonatomic, strong) UILabel* contentSubtitleLabel;

@property (nonatomic, strong) UIView* simpleSampleContentView;
@property (nonatomic, strong) UIButton* mainButtonTop;
@property (nonatomic, strong) UIButton* mainButton;

@end



@implementation SimpleSampleViewController


#pragma mark - Lifecycle

- (id)init {
    self = [super init];
    if (self) {
        self.title = @"Simple";
    }
    return self;
}

- (void) loadView {
    // Construct the view hierachy for this view controller using ISSViewBuilder
    self.view = [ISSViewBuilder rootViewWithStyle:@"simpleSampleMainView" andSubViews:^{
        return @[
          self.mainTitleLabel = [ISSViewBuilder labelWithStyle:@"mainTitleLabel"],
          self.mainTitleButton = [ISSViewBuilder buttonWithStyle:@"mainTitleButton"],
          self.simpleSampleContentView = [ISSViewBuilder viewWithStyle:@"simpleSampleContentView" andSubViews:^{ return @[
                self.contentTitleLabel = [ISSViewBuilder labelWithStyle:@"simpleSampleContentTitleLabel"],
                self.contentSubtitleLabel = [ISSViewBuilder labelWithStyle:@"simpleSampleContentSubtitleLabel"],
                // You can also add and setup an already existing view object using the view builder:
                [ISSViewBuilder setupView:[[UIView alloc] init] withStyleClass:@"simpleSampleButtonContainer" andSubViews:^{
                    return @[
                             self.mainButtonTop = [ISSViewBuilder buttonWithStyle:@"simpleSampleMainButton1"],
                             self.mainButton = [ISSViewBuilder buttonWithStyle:@"simpleSampleMainButton2"],
                             [ISSViewBuilder buttonWithStyle:@"simpleSampleMainButton3"]];
                }] ];
          }] ];
    }];
    
    [self.mainButton addTarget:self action:@selector(touchedButton:event:) forControlEvents:UIControlEventAllTouchEvents];

    // NOTE: Uncomment below to disable styling of cornerRadius (just to test what disabling a property feels like)
    //[self.mainButton disableStylingForPropertyISS:@"cornerRadius"];
    
    [self.mainTitleButton setTitle:@"Sample button" forState:UIControlStateNormal];
    
    self.contentTitleLabel.text = @"Content Main";
    self.contentSubtitleLabel.text = @"Content Sub";

    // Setup notification blocks to get notified when styles are applied to mainButton
    self.mainButton.willApplyStylingBlockISS = ^(NSArray* styles) {
        // Use this block to for instance override which style properties are allowed to be set at the moment.
        //NSLog(@"Will apply styles to mainButton - %lu properties", (unsigned long)styles.count);
        return styles;
    };
    self.mainButton.didApplyStylingBlockISS = ^(NSArray* styles) {
        // In this block it's possible to for instance update any derived styling properties, or override values set during styling.
        //NSLog(@"Did apply styles to mainButton - %lu properties", (unsigned long)styles.count);
    };

    // Apply styling only once as startup to mainButtonTop, then disable automatic re-styling, to make it possible do adjust styling manually in code.
    [self.mainButtonTop applyStylingOnceISS];
    
    // Add custom style to tab bar item
    [[InterfaCSS sharedInstance] addStyleClass:@"tab1" forUIElement:self.tabBarItem];
}

- (NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Debug log matching styles for self.mainTitleLabel:
#if DEBUG == 1
    [[InterfaCSS interfaCSS] logMatchingStyleDeclarationsForUIElement:self.mainTitleLabel];
#endif

    [self performSelector:@selector(animateSimpleSampleContentView) withObject:nil afterDelay:.0f];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.simpleSampleContentView removeStyleClassISS:@"simpleSampleContentViewAtRest" scheduleStyling:NO];
}

- (void) animateSimpleSampleContentView {
    [UIView animateWithDuration:1.0f delay:.0f usingSpringWithDamping:0.25 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.simpleSampleContentView addStyleClassISS:@"simpleSampleContentViewAtRest" scheduleStyling:NO];
        [self.simpleSampleContentView applyStylingISS];
    } completion:nil];
}


#if __IPHONE_OS_VERSION_MIN_REQUIRED < 80000

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    // Debug log matching styles for self.mainTitleLabel:
    [[InterfaCSS interfaCSS] logMatchingStyleDeclarationsForUIElement:self.mainTitleLabel];
}

#else

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Debug log matching styles for self.mainTitleLabel:
    [self iss_logDebug:@"Matching declarations before rotation:"];
    [[InterfaCSS interfaCSS] logMatchingStyleDeclarationsForUIElement:self.mainTitleLabel];
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self iss_logDebug:@"Matching declarations after rotation:"];
        [[InterfaCSS interfaCSS] logMatchingStyleDeclarationsForUIElement:self.mainTitleLabel];
    }];
}

#endif


#pragma mark - Actions 

- (void) touchedButton:(id)btn event:(UIEvent*)event {
    UITouch* touch = [event.allTouches anyObject];
    if( touch.phase == UITouchPhaseBegan ) {
        NSString* title;
        if( [self.mainButtonTop.currentTitle hasPrefix:@"T"] ) title = [self.mainButtonTop.currentTitle lowercaseString];
        else title = [self.mainButtonTop.currentTitle uppercaseString];
        [self.mainButtonTop setTitle:title forState:UIControlStateNormal];
        
        [self.mainButton addStyleClassISS:@"touched" animated:YES];
    } else if( touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled ) {
        [self.mainButton removeStyleClassISS:@"touched" animated:YES];
    }
}


@end
