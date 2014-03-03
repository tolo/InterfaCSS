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
#import "ISSStyleSheetParser.h"

@implementation ISSSelectorChain {
    NSArray* _selectorComponents;
}


#pragma mark - Utility methods

+ (BOOL) matchComponent:(id)lastComponent againstSelectorChain:(NSArray*)selectorComponents firstMatch:(BOOL)firstMatch {
    if ( selectorComponents.count && lastComponent ) {
        ISSSelector* lastSelectorComponent = [selectorComponents lastObject];
        
        BOOL selectorMatch = NO;
        // TODO: Add support for combinators '+' and '>'
        
        if ( (selectorMatch = [lastSelectorComponent matchesComponent:lastComponent]) ) {
            // If match - move up the selector chain
            selectorComponents = [selectorComponents subarrayWithRange:NSMakeRange(0, selectorComponents.count-1)];
        }
        if ( firstMatch && !selectorMatch ) {
            return NO; // Rightmost selector must match
        } else {
            // Move up the component chain
            lastComponent = [lastComponent respondsToSelector:@selector(superview)] ? [lastComponent superview] :
                                    [[InterfaCSS interfaCSS] parentViewForUIObject:lastComponent];
            return [ISSSelectorChain matchComponent:lastComponent againstSelectorChain:selectorComponents firstMatch:NO];
        }
    }
    else if ( !selectorComponents.count ) return YES; // All selector components matched - match success
    else return NO;
}


#pragma mark - SelectorChain interface

- (id) initWithComponents:(NSArray*)selectorComponents {
    if( self = [super init] ) {
        _selectorComponents = selectorComponents;
    }
    return self;
}

- (id) copyWithZone:(NSZone*)zone {
    return [[ISSSelectorChain allocWithZone:zone] initWithComponents:self.selectorComponents];
}

- (ISSSelectorChain*) selectorChainByAddingSelector:(ISSSelector*)selector {
    return [[ISSSelectorChain alloc] initWithComponents:[self.selectorComponents arrayByAddingObject:selector]];
}

- (ISSSelectorChain*) selectorChainByAddingSelectorChain:(ISSSelectorChain*)selectorChain {
    return [[ISSSelectorChain alloc] initWithComponents:[self.selectorComponents arrayByAddingObjectsFromArray:selectorChain.selectorComponents]];
}

- (NSString*) displayDescription {
    NSMutableString* str = [NSMutableString string];
    for(ISSSelector* comp in _selectorComponents) {
        if( str.length == 0 ) [str appendFormat:@"%@", comp.displayDescription];
        else [str appendFormat:@" %@", comp.displayDescription];
    }
    return str;
}

- (BOOL) matchesView:(id)view {
    return [ISSSelectorChain matchComponent:view againstSelectorChain:_selectorComponents firstMatch:YES];
}


#pragma mark - NSObject overrides

- (NSString*) description {
    return [NSString stringWithFormat:@"SelectorChain[%@]", self.displayDescription];
}

- (BOOL) isEqual:(id)object {
    return [[object class] isKindOfClass:self.class] && [_selectorComponents isEqualToArray:[object selectorComponents]];
}

- (NSUInteger) hash {
    return _selectorComponents.hash;
}

@end
