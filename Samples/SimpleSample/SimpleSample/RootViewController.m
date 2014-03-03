//
//  RootViewController.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-24.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "RootViewController.h"

#import "UIView+InterfaCSS.h"

@implementation RootViewController

- (void) updateStylesForInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    // Add or remove orientation dependent style
    if( UIInterfaceOrientationIsPortrait(toInterfaceOrientation) ) {
        [self.view removeStyleClass:@"landscape"];
    } else {
        [self.view addStyleClass:@"landscape"];
    }
    
    // The addStyleClass/removeStyleClass calls above will only schedule (delayed performSelector) a call to re-apply styles - call applyStyling
    // to force styling within the current animation block:
    [self.view applyStyling];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateStylesForInterfaceOrientation:self.interfaceOrientation];
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self updateStylesForInterfaceOrientation:toInterfaceOrientation];
}

@end
