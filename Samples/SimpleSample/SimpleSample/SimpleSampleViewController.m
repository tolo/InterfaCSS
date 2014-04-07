//
//  SimpleSampleViewController.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-24.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "SimpleSampleViewController.h"

#import <InterfaCSS.h>
#import <InterfaCSS/ISSViewBuilder.h>
#import <InterfaCSS/UIView+InterfaCSS.h>
#import <InterfaCSS/ISSViewHierarchyParser.h>


@interface SimpleSampleViewController ()

@property (nonatomic, strong) UILabel* mainTitleLabel;
@property (nonatomic, strong) UILabel* mainSubtitleLabel;

@property (nonatomic, strong) UILabel* contentTitleLabel;
@property (nonatomic, strong) UILabel* contentSubtitleLabel;

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
          self.mainSubtitleLabel = [ISSViewBuilder labelWithStyle:@"mainSubtitleLabel"],
          [ISSViewBuilder viewWithStyle:@"simpleSampleContentView" andSubViews:^{ return @[
                self.contentTitleLabel = [ISSViewBuilder labelWithStyle:@"simpleSampleContentTitleLabel"],
                self.contentSubtitleLabel = [ISSViewBuilder labelWithStyle:@"simpleSampleContentSubtitleLabel"],
                [ISSViewBuilder setupView:[[UIView alloc] init] withStyleClass:@"simpleSampleButtonContainer" andSubViews:^{
                    return @[ self.mainButton = [ISSViewBuilder buttonWithStyle:@"simpleSampleMainButton"] ];
                }] ];
          }] ];
    }];
    
    [self.mainButton addTarget:self action:@selector(touchedButton:event:) forControlEvents:UIControlEventAllTouchEvents];
    
    self.mainTitleLabel.text = @"Simple Sample Main";
    self.mainTitleLabel.tag = 123;
    self.mainSubtitleLabel.text = @"Sample Sub";
    
    self.contentTitleLabel.text = @"Content Main";
    self.contentSubtitleLabel.text = @"Content Sub";
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
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    // Debug log matching styles for self.mainTitleLabel:
#if DEBUG == 1
    [[InterfaCSS interfaCSS] logMatchingStyleDeclarationsForUIElement:self.mainTitleLabel];
#endif
}


#pragma mark - Actions 

- (void) touchedButton:(id)btn event:(UIEvent*)event {
    UITouch* touch = [event.allTouches anyObject];
    if( touch.phase == UITouchPhaseBegan ) {
        [self.mainButton addStyleClassISS:@"touched" animated:YES];
    } else if( touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled ) {
        [self.mainButton removeStyleClassISS:@"touched" animated:YES];
    }
}


@end
