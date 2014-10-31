//
//  InterfaCSS
//  UIView+ISSPrototypeView.m
//  
//  Created by Tobias Löfstrand on 2014-10-29.
//  Copyright (c) 2014 Leafnode AB. All rights reserved.
//


#import "UIView+ISSPrototypeView.h"

#import "InterfaCSS.h"
#import "ISSUIElementDetails.h"


@implementation UIView (ISSPrototypeView)

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
    NSString* reuseIdentifier = nil;
    if( [self respondsToSelector:@selector(reuseIdentifier)] ) {
        reuseIdentifier = [(id)self performSelector:@selector(reuseIdentifier)];
    }

    if( reuseIdentifier && !self.initializedFromPrototypeISS) {
        [[InterfaCSS sharedInstance] viewFromPrototypeWithName:reuseIdentifier parentObject:self];
        self.initializedFromPrototypeISS = YES;
    }
}

@end
