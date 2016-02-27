//
//  ISSNestedElementSelector.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSNestedElementSelector.h"

#import "ISSUIElementDetails.h"
#import "ISSRuntimeIntrospectionUtils.h"


@implementation ISSNestedElementSelector

+ (instancetype) selectorWithNestedElementKeyPath:(NSString*)nestedElementKeyPath {
    // We reuse/repurpose the elementId field of ISSSelector, with the rationale that identifying a sub element using a key path is really a specialized version of identifying an element using an id
    return [self selectorWithType:nil elementId:nestedElementKeyPath pseudoClasses:nil];
}

- (NSString*) nestedElementKeyPath {
    return self.elementId;
}

- (BOOL) matchesElement:(ISSUIElementDetails*)elementDetails stylingContext:(ISSStylingContext*)stylingContext {
    ISSUIElementDetails* parentDetails = [[InterfaCSS sharedInstance] detailsForUIElement:elementDetails.ownerElement];
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
