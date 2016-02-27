//
//  UIView+ISSPrototypeReusableView.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "UIView+ISSPrototypeReusableView.h"

#import "InterfaCSS.h"
#import "ISSUIElementDetails.h"


@implementation UIView (ISSPrototypeReusableView)

- (BOOL) initializedFromPrototypeISS {
    ISSUIElementDetails* elementDetails = [[InterfaCSS interfaCSS] detailsForUIElement:self];
    NSNumber* cellInitializedISS = elementDetails.additionalDetails[ISSPrototypeViewInitializedKey];
    return [cellInitializedISS boolValue];
}

- (void) setInitializedFromPrototypeISS:(BOOL)initializedFromPrototype {
    ISSUIElementDetails* elementDetails = [[InterfaCSS interfaCSS] detailsForUIElement:self];
    elementDetails.additionalDetails[ISSPrototypeViewInitializedKey] = @(initializedFromPrototype);
}

- (void) setupViewFromPrototypeISS {
    [self setupViewFromPrototypeRegisteredInViewISS:nil];
}

- (void) setupViewFromPrototypeRegisteredInViewISS:(UIView*)registeredInView {
    NSString* prototypeName = nil;
    if( [self respondsToSelector:@selector(reuseIdentifier)] ) {
        prototypeName = [(id)self performSelector:@selector(reuseIdentifier)];
    }

    if( prototypeName && !self.initializedFromPrototypeISS ) {
        [[InterfaCSS sharedInstance] viewFromPrototypeWithName:prototypeName registeredInElement:registeredInView prototypeParent:self];
        self.initializedFromPrototypeISS = YES;
    }
}

@end
