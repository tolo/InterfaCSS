//
//  ISSSelectorChain.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-03-02.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSSelectorChain.h"

#import "InterfaCSS.h"
#import "ISSSelector.h"
#import "ISSUIElementDetails.h"

@implementation ISSSelectorChain

#pragma mark - Utility methods

+ (ISSUIElementDetails*) findMatchingDescendantSelectorParent:(ISSUIElementDetails*)parentDetails forSelector:(ISSSelector*)selector
                                        ignoringPseudoClasses:(BOOL)ignorePseudoClasses {
    if( !parentDetails ) return nil;
    else if( [selector matchesElement:parentDetails ignoringPseudoClasses:ignorePseudoClasses] ) return parentDetails;
    else return [self findMatchingDescendantSelectorParent:[[InterfaCSS interfaCSS] detailsForUIElement:parentDetails.parentElement]
                                               forSelector:selector ignoringPseudoClasses:ignorePseudoClasses];
}

+ (ISSUIElementDetails*) findMatchingChildSelectorParent:(ISSUIElementDetails*)parentDetails forSelector:(ISSSelector*)selector
                                   ignoringPseudoClasses:(BOOL)ignorePseudoClasses {
    if( parentDetails && [selector matchesElement:parentDetails ignoringPseudoClasses:ignorePseudoClasses] ) return parentDetails;
    else return nil;
}

+ (ISSUIElementDetails*) findMatchingAdjacentSiblingTo:(ISSUIElementDetails*)elementDetails inParent:(ISSUIElementDetails*)parentDetails
                                           forSelector:(ISSSelector*)selector ignoringPseudoClasses:(BOOL)ignorePseudoClasses {
    NSArray* subviews = parentDetails.view.subviews;
    NSInteger index = [subviews indexOfObject:elementDetails.uiElement];
    if( index != NSNotFound && (index-1) >= 0 ) {
        UIView* sibling = subviews[(NSUInteger) (index - 1)];
        ISSUIElementDetails* siblingDetails = [[InterfaCSS interfaCSS] detailsForUIElement:sibling];
        if( [selector matchesElement:siblingDetails ignoringPseudoClasses:ignorePseudoClasses] ) return siblingDetails;
    }
    return nil;
}

+ (ISSUIElementDetails*) findMatchingGeneralSiblingTo:(ISSUIElementDetails*)elementDetails inParent:(ISSUIElementDetails*)parentDetails
                                          forSelector:(ISSSelector*)selector ignoringPseudoClasses:(BOOL)ignorePseudoClasses {
    for(UIView* sibling in parentDetails.view.subviews) {
        ISSUIElementDetails* siblingDetails = [[InterfaCSS interfaCSS] detailsForUIElement:sibling];
        if( sibling != elementDetails.uiElement && [selector matchesElement:siblingDetails ignoringPseudoClasses:ignorePseudoClasses] ) return siblingDetails;
    }
    return nil;
}

+ (ISSUIElementDetails*) matchElement:(ISSUIElementDetails*)elementDetails withSelector:(ISSSelector*)selector andCombinator:(ISSSelectorCombinator)combinator
                ignoringPseudoClasses:(BOOL)ignorePseudoClasses {
    ISSUIElementDetails* nextUIElementDetails = nil;
    ISSUIElementDetails* parentDetails = [[InterfaCSS interfaCSS] detailsForUIElement:elementDetails.parentElement];
    parentDetails = [parentDetails copy]; // Use copy of parent to make sure any modification to stylesCacheable flag does not affect original object
    switch (combinator) {
        case ISSSelectorCombinatorDescendant: {
            nextUIElementDetails = [self findMatchingDescendantSelectorParent:parentDetails forSelector:selector ignoringPseudoClasses:ignorePseudoClasses];
            break;
        }
        case ISSSelectorCombinatorChild: {
            nextUIElementDetails = [self findMatchingChildSelectorParent:parentDetails forSelector:selector ignoringPseudoClasses:ignorePseudoClasses];
            break;
        }
        case ISSSelectorCombinatorAdjacentSibling: {
            nextUIElementDetails = [self findMatchingAdjacentSiblingTo:elementDetails inParent:parentDetails forSelector:selector ignoringPseudoClasses:ignorePseudoClasses];
            break;
        }
        case ISSSelectorCombinatorGeneralSibling: {
            nextUIElementDetails = [self findMatchingGeneralSiblingTo:elementDetails inParent:parentDetails forSelector:selector ignoringPseudoClasses:ignorePseudoClasses];
            break;
        }
    }
    return nextUIElementDetails;
}


#pragma mark - SelectorChain interface

- (id) initWithComponents:(NSArray*)selectorComponents hasPseudoClassSelector:(BOOL)hasPseudoClassSelector { // Private initializer
    if( self = [super init] ) {
        _selectorComponents = selectorComponents;
        _hasPseudoClassSelector = hasPseudoClassSelector;
    }
    return self;
}

+ (instancetype) selectorChainWithSelector:(ISSSelector*)selector {
    return [self selectorChainWithComponents:@[selector]];
}

+ (instancetype) selectorChainWithComponents:(NSArray*)selectorComponents {
    // Validate selector components
    if( selectorComponents.count % 2 == 1 ) { // Selector chain must always contain odd number of components
        BOOL hasPseudoClassSelector = NO;
        for(NSUInteger i=0; i<selectorComponents.count; i++) {
            if( i%2 == 0 && ![selectorComponents[i] isKindOfClass:ISSSelector.class] ) return nil;
            else if( i%2 == 1 && ![selectorComponents[i] isKindOfClass:NSNumber.class] ) return nil;

            if( (i%2 == 0) && !hasPseudoClassSelector ) hasPseudoClassSelector = ((ISSSelector*)selectorComponents[i]).pseudoClasses.count > 0;
        }
        return [[self alloc] initWithComponents:selectorComponents hasPseudoClassSelector:hasPseudoClassSelector];
    }
    return nil;
}

- (id) copyWithZone:(NSZone*)zone {
    return [[ISSSelectorChain allocWithZone:zone] initWithComponents:self.selectorComponents hasPseudoClassSelector:_hasPseudoClassSelector];
}

- (ISSSelectorChain*) selectorChainByAddingDescendantSelector:(ISSSelector*)selector {
    NSArray* newComponents = [self.selectorComponents arrayByAddingObjectsFromArray:@[@(ISSSelectorCombinatorDescendant), selector]];
    return [[ISSSelectorChain alloc] initWithComponents:newComponents hasPseudoClassSelector:_hasPseudoClassSelector || (selector.pseudoClasses.count > 0)];
}

- (ISSSelectorChain*) selectorChainByAddingDescendantSelectorChain:(ISSSelectorChain*)selectorChain {
    NSArray* newComponents = [self.selectorComponents arrayByAddingObject:@(ISSSelectorCombinatorDescendant)];
    newComponents = [newComponents arrayByAddingObjectsFromArray:selectorChain.selectorComponents];
    return [[ISSSelectorChain alloc] initWithComponents:newComponents hasPseudoClassSelector:_hasPseudoClassSelector || selectorChain.hasPseudoClassSelector];
}

- (NSString*) displayDescription {
    NSMutableString* str = [NSMutableString string];
    for(id selectorComponent in _selectorComponents) {
        if( [selectorComponent isKindOfClass:ISSSelector.class] ) [str appendString:[selectorComponent displayDescription]];
        else {
            switch ((ISSSelectorCombinator)[selectorComponent integerValue]) {
                case ISSSelectorCombinatorDescendant: {
                    [str appendString:@" "]; break;
                }
                case ISSSelectorCombinatorChild: {
                    [str appendString:@" > "]; break;
                }
                case ISSSelectorCombinatorAdjacentSibling: {
                    [str appendString:@" + "]; break;
                }
                case ISSSelectorCombinatorGeneralSibling: {
                    [str appendString:@" ~ "]; break;
                }
            }
        }
    }
    return str;
}

- (BOOL) matchesElement:(ISSUIElementDetails*)elementDetails ignoringPseudoClasses:(BOOL)ignorePseudoClasses {
    ISSSelector* lastSelector = [_selectorComponents lastObject];
    if( [lastSelector matchesElement:elementDetails ignoringPseudoClasses:ignorePseudoClasses] ) { // Match last selector...
        NSUInteger remainingCount = _selectorComponents.count - 1;
        ISSUIElementDetails* nextUIElementDetails = elementDetails;
        for(NSUInteger i=remainingCount; i>1 && nextUIElementDetails; i-=2) { // ...then rest of selector chain
            ISSSelectorCombinator combinator = (ISSSelectorCombinator)[_selectorComponents[i - 1] integerValue];
            ISSSelector* selector = _selectorComponents[i-2];
            nextUIElementDetails = [ISSSelectorChain matchElement:elementDetails withSelector:selector andCombinator:combinator ignoringPseudoClasses:ignorePseudoClasses];
        }
        return nextUIElementDetails != nil;
    } else {
        return NO;
    }
}


#pragma mark - NSObject overrides

- (NSString*) description {
    return [NSString stringWithFormat:@"SelectorChain[%@]", self.displayDescription];
}

- (BOOL) isEqual:(id)object {
    if( object == self ) return YES;
    else if( [object isKindOfClass:ISSSelectorChain.class] ) {
        if (self.selectorComponents == [object selectorComponents]) return YES;
        else [self.selectorComponents isEqualToArray:[object selectorComponents]];
    }
    return NO;
}

- (NSUInteger) hash {
    return _selectorComponents.hash;
}

@end
