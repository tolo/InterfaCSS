//
//  UIView+ISSPrototypeReusableView.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


@interface UIView (ISSPrototypeReusableView)

@property (nonatomic) BOOL initializedFromPrototypeISS;

- (void) setupViewFromPrototypeISS;
- (void) setupViewFromPrototypeRegisteredInViewISS:(UIView*)registeredInView;

@end
