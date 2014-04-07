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

+ (ISSUIElementDetails*) findMatchingDescendantSelectorParent:(ISSUIElementDetails*)parentDetails forSelector:(ISSSelector*)selector {
    if( !parentDetails ) return nil;
    else if( [selector matchesElement:parentDetails] ) return parentDetails;
    else return [self findMatchingDescendantSelectorParent:[[InterfaCSS interfaCSS] detailsForUIElement:parentDetails.parentView] forSelector:selector];
}

+ (ISSUIElementDetails*) findMatchingChildSelectorParent:(ISSUIElementDetails*)parentDetails forSelector:(ISSSelector*)selector {
    if( parentDetails && [selector matchesElement:parentDetails] ) return parentDetails;
    else return nil;
}

+ (ISSUIElementDetails*) findMatchingAdjacentSiblingTo:(ISSUIElementDetails*)elementDetails inParent:(ISSUIElementDetails*)parentDetails forSelector:(ISSSelector*)selector {
    NSArray* subviews = parentDetails.view.subviews;
    NSInteger index = [subviews indexOfObject:elementDetails.uiElement];
    if( index != NSNotFound && (index-1) >= 0 ) {
        UIView* sibling = [subviews objectAtIndex:(NSUInteger)(index-1)];
        ISSUIElementDetails* siblingDetails = [[InterfaCSS interfaCSS] detailsForUIElement:sibling];
        if( [selector matchesElement:siblingDetails] ) return siblingDetails;
    }
    return nil;
}

+ (ISSUIElementDetails*) findMatchingGeneralSiblingTo:(ISSUIElementDetails*)elementDetails inParent:(ISSUIElementDetails*)parentDetails forSelector:(ISSSelector*)selector {
    for(UIView* sibling in parentDetails.view.subviews) {
        ISSUIElementDetails* siblingDetails = [[InterfaCSS interfaCSS] detailsForUIElement:sibling];
        if( sibling != elementDetails.uiElement && [selector matchesElement:siblingDetails] ) return siblingDetails;
    }
    return nil;
}

+ (ISSUIElementDetails*) matchElement:(ISSUIElementDetails*)elementDetails withSelector:(ISSSelector*)selector andCombinator:(ISSSelectorCombinator)combinator {
    ISSUIElementDetails* nextUIElementDetails = nil;
    ISSUIElementDetails* parentDetails = [[InterfaCSS interfaCSS] detailsForUIElement:elementDetails.parentView];
    parentDetails = [parentDetails copy]; // Use copy of parent to make sure any modification to stylesCacheable flag does not affect original object
    switch (combinator) {
        case ISSSelectorCombinatorDescendant: {
            nextUIElementDetails = [self findMatchingDescendantSelectorParent:parentDetails forSelector:selector];
            break;
        }
        case ISSSelectorCombinatorChild: {
            nextUIElementDetails = [self findMatchingChildSelectorParent:parentDetails forSelector:selector];
            break;
        }
        case ISSSelectorCombinatorAdjacentSibling: {
            nextUIElementDetails = [self findMatchingAdjacentSiblingTo:elementDetails inParent:parentDetails forSelector:selector];
            break;
        }
        case ISSSelectorCombinatorGeneralSibling: {
            nextUIElementDetails = [self findMatchingGeneralSiblingTo:elementDetails inParent:parentDetails forSelector:selector];
            break;
        }
    }
    return nextUIElementDetails;
}


#pragma mark - SelectorChain interface

- (id) initWithComponents:(NSArray*)selectorComponents {
    if( self = [super init] ) {
        _selectorComponents = selectorComponents;
    }
    return self;
}

+ (instancetype) selectorChainWithComponents:(NSArray*)selectorComponents {
    // Validate selector components
    if( selectorComponents.count % 2 == 1 ) { // Selector chain must always contain odd number of components
        for(NSUInteger i=0; i<selectorComponents.count; i++) {
            if( i%2 == 0 && ![selectorComponents[i] isKindOfClass:ISSSelector.class] ) return nil;
            else if( i%2 == 1 && ![selectorComponents[i] isKindOfClass:NSNumber.class] ) return nil;
        }
        return [[self alloc] initWithComponents:selectorComponents];
    }
    return nil;
}

- (id) copyWithZone:(NSZone*)zone {
    return [[ISSSelectorChain allocWithZone:zone] initWithComponents:self.selectorComponents];
}

- (ISSSelectorChain*) selectorChainByAddingDescendantSelector:(ISSSelector*)selector {
    NSArray* newComponents = [self.selectorComponents arrayByAddingObjectsFromArray:@[@(ISSSelectorCombinatorDescendant), selector]];
    return [[ISSSelectorChain alloc] initWithComponents:newComponents];
}

- (ISSSelectorChain*) selectorChainByAddingDescendantSelectorChain:(ISSSelectorChain*)selectorChain {
    NSArray* newComponents = [self.selectorComponents arrayByAddingObject:@(ISSSelectorCombinatorDescendant)];
    newComponents = [newComponents arrayByAddingObjectsFromArray:selectorChain.selectorComponents];
    return [[ISSSelectorChain alloc] initWithComponents:newComponents];
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

- (BOOL) matchesElement:(ISSUIElementDetails*)elementDetails {
    ISSSelector* lastSelector = [_selectorComponents lastObject];
    if( [lastSelector matchesElement:elementDetails] ) { // Match last selector...
        NSUInteger remainingCount = _selectorComponents.count - 1;
        ISSUIElementDetails* nextUIElementDetails = elementDetails;
        for(NSUInteger i=remainingCount; i>1 && nextUIElementDetails; i-=2) { // ...then rest of selector chain
            ISSSelectorCombinator combinator = (ISSSelectorCombinator)[_selectorComponents[i - 1] integerValue];
            ISSSelector* selector = _selectorComponents[i-2];
            nextUIElementDetails = [ISSSelectorChain matchElement:elementDetails withSelector:selector andCombinator:combinator];
            // If parent element styles are not cacheable - disable caching for styles of current element:
            if( nextUIElementDetails && !nextUIElementDetails.stylesCacheable ) elementDetails.stylesCacheable = NO;
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
    return [object isKindOfClass:ISSSelectorChain.class] && [_selectorComponents isEqualToArray:[object selectorComponents]];
}

- (NSUInteger) hash {
    return _selectorComponents.hash;
}

@end
