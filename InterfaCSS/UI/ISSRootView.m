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

- (void) commonInitWithView:(UIView*)view {
    self.wrappedRootView = view;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (id) init {
    if ( self = [super init] ) {
        [self commonInitWithView:nil];
        self.frame = [[ISSRectValue windowRect] rectForView:self];
    }
    return self;
}

- (id) initWithFrame:(CGRect)frame {
    if ( self = [super initWithFrame:frame] ) {
        [self commonInitWithView:nil];
    }
    return self;
}

- (id) initWithView:(UIView*)view {
    if ( self = [super init] ) {
        [self commonInitWithView:view];
        self.frame = [[ISSRectValue windowRect] rectForView:self];
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
    [self scheduleApplyStylingISS];
}

- (void) didMoveToSuperview {
    [self scheduleApplyStylingISS];
}

@end
