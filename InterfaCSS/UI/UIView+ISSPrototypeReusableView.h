//
//  InterfaCSS
//  UIView+ISSPrototypeReusableView.h
//  
//  Created by Tobias Löfstrand on 2014-10-29.
//  Copyright (c) 2014 Leafnode AB. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


@interface UIView (ISSPrototypeReusableView)

@property (nonatomic) BOOL initializedFromPrototypeISS;

- (void) setupViewFromPrototypeISS;
- (void) setupViewFromPrototypeRegisteredInViewISS:(UIView*)registeredInView;

@end
