//
//  ISSRootView.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-01-31.
//  Copyright (c) 2014 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSLayoutContextView.h"


/**
 * UIView subclass that makes sure that styles are (re)applied every time the view is moved to a new superview, window or when it's frame is modified. Useful
 * as a the root view of a view controller, or for views that you don't add to the view hierarchy yourself (for instance cells or header views in table
 * views etc).
 */
@interface ISSRootView : ISSLayoutContextView

@property (nonatomic, weak) UIView* wrappedRootView;

/**
 * Creates an ISSRootView that will serve as a wrapper view for the specified view.
 */
- (id) initWithView:(UIView*)view;

@end
