//
//  ISSRootView.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-01-31.
//  Copyright (c) 2014 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSRootView.h"

#import "UIView+InterfaCSS.h"
#import "ISSRectValue.h"

@implementation ISSRootView

- (id) init {
    return [self initWithView:nil];
}

- (id) initWithView:(UIView*)view {
    self = [super init];
    if ( self ) {
        self.wrappedRootView = view;
        self.frame = [[ISSRectValue windowRect] rectForView:self];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (void) setWrappedRootView:(UIView*)wrappedRootView {
    [_wrappedRootView removeFromSuperview];
    _wrappedRootView = wrappedRootView;
    if( _wrappedRootView ) [self addSubview:_wrappedRootView];
}

- (void) setFrame:(CGRect)frame {
    [super setFrame:frame];
    _wrappedRootView.frame = self.bounds;
    [self scheduleApplyStyling];
}

- (void) didMoveToSuperview {
    [self scheduleApplyStyling];
}

@end
