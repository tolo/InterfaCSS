//
//  ISSNestedElementSelector.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSNestedElementSelector.h"

#import "ISSStylingManager.h"

#import "ISSElementStylingProxy.h"
#import "ISSStylingContext.h"
#import "ISSRuntimeIntrospectionUtils.h"


@implementation ISSNestedElementSelector

+ (instancetype) selectorWithNestedElementKeyPath:(NSString*)nestedElementKeyPath {
    // We reuse/repurpose the elementId field of ISSSelector, with the rationale that identifying a sub element using a key path is really a specialized version of identifying an element using an id
    return [[self alloc] initWithType:nil elementId:nestedElementKeyPath styleClasses:nil pseudoClasses:nil];
}

- (NSString*) nestedElementKeyPath {
    return self.elementId;
}

- (BOOL) matchesElement:(ISSElementStylingProxy*)elementDetails stylingContext:(ISSStylingContext*)stylingContext {
    ISSElementStylingProxy* parentDetails = [elementDetails.ownerElement interfaCSS];
    NSString* validParentKeyPath = parentDetails.validNestedElements[self.nestedElementKeyPath];

    if( validParentKeyPath ) {
        return [elementDetails.ownerElement valueForKey:validParentKeyPath] == elementDetails.uiElement;
    } else {
        return NO;
    }
}

- (NSString*) displayDescription {
    return [NSString stringWithFormat:@"$%@", self.nestedElementKeyPath];
}

- (BOOL) isEqual:(id)object {
    if ( [object isKindOfClass:ISSNestedElementSelector.class] ) {
        return [super isEqual:object];
    }
    return NO;
}

@end
