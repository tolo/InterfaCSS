//
//  ISSRootView.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-01-31.
//  Copyright (c) 2014 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

@interface ISSRootView : UIView

@property (nonatomic, weak) UIView* wrappedRootView;

- (id) initWithView:(UIView*)view;

@end
