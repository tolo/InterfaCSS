//
//  ISSSelectorChain.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSSelectorChain.h"

#import "InterfaCSS.h"
#import "ISSSelector.h"
#import "ISSUIElementDetails.h"
#import "ISSStylingContext.h"
#import "ISSNestedElementSelector.h"


@implementation ISSSelectorChain {
    BOOL _nestedElenentSelectorChain;
}

#pragma mark - Utility methods

+ (ISSUIElementDetails*) findMatchingDescendantSelectorParent:(ISSUIElementDetails*)parentDetails forSelector:(ISSSelector*)selector
                                        stylingContext:(ISSStylingContext*)stylingContext {
    if( !parentDetails ) return nil;
    else if( [selector matchesElement:parentDetails stylingContext:stylingContext] ) return parentDetails;
    else {
        ISSUIElementDetails* grandParentDetails = [[InterfaCSS sharedInstance] detailsForUIElement:parentDetails.parentElement];
        return [self findMatchingDescendantSelectorParent:grandParentDetails forSelector:selector stylingContext:stylingContext];
    }
}

+ (ISSUIElementDetails*) findMatchingChildSelectorParent:(ISSUIElementDetails*)parentDetails forSelector:(ISSSelector*)selector
                                   stylingContext:(ISSStylingContext*)stylingContext {
    if( parentDetails && [selector matchesElement:parentDetails stylingContext:stylingContext] ) return parentDetails;
    else return nil;
}

+ (ISSUIElementDetails*) findMatchingAdjacentSiblingTo:(ISSUIElementDetails*)elementDetails inParent:(ISSUIElementDetails*)parentDetails
                                           forSelector:(ISSSelector*)selector stylingContext:(ISSStylingContext*)stylingContext {
    NSArray* subviews = parentDetails.view.subviews;
    NSInteger index = [subviews indexOfObject:elementDetails.uiElement];
    if( index != NSNotFound && (index-1) >= 0 ) {
        UIView* sibling = subviews[(NSUInteger) (index - 1)];
        ISSUIElementDetails* siblingDetails = [[InterfaCSS sharedInstance] detailsForUIElement:sibling];
        if( [selector matchesElement:siblingDetails stylingContext:stylingContext] ) return siblingDetails;
    }
    return nil;
}

+ (ISSUIElementDetails*) findMatchingGeneralSiblingTo:(ISSUIElementDetails*)elementDetails inParent:(ISSUIElementDetails*)parentDetails
                                          forSelector:(ISSSelector*)selector stylingContext:(ISSStylingContext*)stylingContext {
    for(UIView* sibling in parentDetails.view.subviews) {
        ISSUIElementDetails* siblingDetails = [[InterfaCSS sharedInstance] detailsForUIElement:sibling];
        if( sibling != elementDetails.uiElement && [selector matchesElement:siblingDetails stylingContext:stylingContext] ) return siblingDetails;
    }
    return nil;
}

+ (ISSUIElementDetails*) matchElement:(ISSUIElementDetails*)elementDetails parentElement:(ISSUIElementDetails*)parentDetails
                         selector:(ISSSelector*)selector combinator:(ISSSelectorCombinator)combinator stylingContext:(ISSStylingContext*)stylingContext {
    ISSUIElementDetails* nextUIElementDetails = nil;
    
    switch (combinator) {
        case ISSSelectorCombinatorDescendant: {
            nextUIElementDetails = [self findMatchingDescendantSelectorParent:parentDetails forSelector:selector stylingContext:stylingContext];
            break;
        }
        case ISSSelectorCombinatorChild: {
            nextUIElementDetails = [self findMatchingChildSelectorParent:parentDetails forSelector:selector stylingContext:stylingContext];
            break;
        }
        case ISSSelectorCombinatorAdjacentSibling: {
            nextUIElementDetails = [self findMatchingAdjacentSiblingTo:elementDetails inParent:parentDetails forSelector:selector stylingContext:stylingContext];
            break;
        }
        case ISSSelectorCombinatorGeneralSibling: {
            nextUIElementDetails = [self findMatchingGeneralSiblingTo:elementDetails inParent:parentDetails forSelector:selector stylingContext:stylingContext];
            break;
        }
    }
    return nextUIElementDetails;
}


#pragma mark - SelectorChain interface

- (id) initWithComponents:(NSArray*)selectorComponents hasPseudoClassSelector:(BOOL)hasPseudoClassSelector { // Private initializer
    if( self = [super init] ) {
        if ( selectorComponents.count > 1 && [[selectorComponents lastObject] isKindOfClass:ISSNestedElementSelector.class] ) {
            _nestedElenentSelectorChain = YES;
        }
        
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

- (NSUInteger) specificity {
    NSUInteger specificity = 0;
    for(id selectorComponent in _selectorComponents) {
        if( [selectorComponent isKindOfClass:ISSSelector.class] ) {
            specificity += ((ISSSelector*)selectorComponent).specificity;
        }
    }
    return specificity;
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
    
    if( [InterfaCSS sharedInstance].useSelectorSpecificity ) {
        [str appendString:@" (specificity: "];
        [str appendFormat:@"%d", (int)self.specificity];
        [str appendString:@")"];
    }
    
    return str;
}

- (BOOL) matchesElement:(ISSUIElementDetails*)elementDetails stylingContext:(ISSStylingContext*)stylingContext {
    ISSSelector* lastSelector = [_selectorComponents lastObject];
    if( [lastSelector matchesElement:elementDetails stylingContext:(ISSStylingContext*)stylingContext] ) { // Match last selector...
        const NSUInteger remainingCount = _selectorComponents.count - 1;
        ISSUIElementDetails* nextUIElementDetails = elementDetails;
        for(NSUInteger i=remainingCount; i>1 && nextUIElementDetails; i-=2) { // ...then rest of selector chain
            ISSSelectorCombinator combinator = (ISSSelectorCombinator)[_selectorComponents[i - 1] integerValue];
            ISSSelector* selector = _selectorComponents[i-2];
            
            ISSUIElementDetails* nextParentUIElementDetails;
            if ( _nestedElenentSelectorChain && i == remainingCount ) { // In case last selector is ISSNestedElementSelector, we need to use ownerElement instead of parentElement
                nextParentUIElementDetails = [[InterfaCSS sharedInstance] detailsForUIElement:nextUIElementDetails.ownerElement];
            } else {
                nextParentUIElementDetails = [[InterfaCSS sharedInstance] detailsForUIElement:nextUIElementDetails.parentElement];
            }
            
            nextUIElementDetails = [ISSSelectorChain matchElement:nextUIElementDetails parentElement:nextParentUIElementDetails selector:selector
                                                    combinator:combinator stylingContext:(ISSStylingContext*)stylingContext];
        }
        // If element at least matched last selector in chain, but didn't match it completely - set a flag indicating that there are partial matches
        if( !nextUIElementDetails ) {
            stylingContext.containsPartiallyMatchedDeclarations = YES;
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
        else return [self.selectorComponents isEqualToArray:[object selectorComponents]];
    }
    return NO;
}

- (NSUInteger) hash {
    return _selectorComponents.hash;
}

@end
