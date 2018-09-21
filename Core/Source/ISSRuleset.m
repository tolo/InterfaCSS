//
//  ISSRuleset.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import "ISSRuleset.h"

#import "ISSSelectorChain.h"
#import "ISSElementStylingProxy.h"
#import "ISSStylingContext.h"
#import "ISSPropertyValue.h"


@implementation ISSRuleset {
    NSArray* _properties;
}

#pragma mark - ISSRuleset interface


- (id) initWithSelectorChains:(NSArray*)selectorChains andProperties:(NSArray*)properties {
    return [self initWithSelectorChains:selectorChains andProperties:properties extendedDeclarationSelectorChain:nil];
}

- (id) initWithSelectorChains:(NSArray*)selectorChains andProperties:(NSArray*)properties extendedDeclarationSelectorChain:(ISSSelectorChain*)extendedDeclarationSelectorChain {
    if( self = [super init] ) {
        _selectorChains = selectorChains;
        _properties = properties;
        _extendedDeclarationSelectorChain = extendedDeclarationSelectorChain;

        for(ISSSelectorChain* chain in selectorChains) {
            if( chain.hasPseudoClassSelector ) {
                _containsPseudoClassSelector = YES;
                break;
            }
        }
    }
    return self;
}

- (NSArray*) properties {
    if ( _extendedDeclaration && _extendedDeclaration != self ) {
        return [_extendedDeclaration.properties arrayByAddingObjectsFromArray:_properties];
    } else {
        return _properties;
    }
}

- (BOOL) matchesElement:(ISSElementStylingProxy*)elementDetails stylingContext:(ISSStylingContext*)stylingContext {
    for(ISSSelectorChain* selectorChain in _selectorChains) {
        if ( [selectorChain matchesElement:elementDetails stylingContext:stylingContext] ) return YES;
    }
    return NO;
}

- (ISSRuleset*) rulesetsMatchingElement:(ISSElementStylingProxy*)elementDetails stylingContext:(ISSStylingContext*)stylingContext {
    NSMutableArray* matchingChains = self.containsPseudoClassSelector ? [NSMutableArray array] : nil;
    for(ISSSelectorChain* selectorChain in _selectorChains) {
        if ( [selectorChain matchesElement:elementDetails stylingContext:stylingContext] ) {
            if( !self.containsPseudoClassSelector ) {
                return self; // If this style sheet declarations block doesn't contain any pseudo classes - return the declarations object itself directly when first selector chain match is found (since no additional matching needs to be done)
            }
            [matchingChains addObject:selectorChain];
        }
    }
    if( matchingChains.count ) return [[ISSRuleset alloc] initWithSelectorChains:matchingChains andProperties:self.properties];
    else return nil;
}

- (BOOL) containsSelectorChain:(ISSSelectorChain*)selectorChain {
    for(ISSSelectorChain* ruleSetSelectorChain in _selectorChains) {
        if ( [ruleSetSelectorChain isEqual:selectorChain] ) {
            return YES;
        }
    }
    return NO;
}

- (NSUInteger) specificity {
    NSUInteger specificity = 0;
    for(ISSSelectorChain* selectorChain in _selectorChains) {
        specificity += selectorChain.specificity;
    }
    return specificity;
}

- (NSString*) displayDescription:(BOOL)withProperties {
    NSMutableArray* chainsCopy = [_selectorChains mutableCopy];
    [chainsCopy enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) { chainsCopy[idx] = [obj displayDescription]; }];
    NSString* chainsDescription = [chainsCopy componentsJoinedByString:@", "];

    if( withProperties ) return [NSString stringWithFormat:@"%@ : %@", chainsDescription, _properties];
    else return chainsDescription;
}

- (NSString*) displayDescription {
    return [self displayDescription:YES];
}


#pragma mark - NSObject overrides


- (NSString*) description {
    return [NSString stringWithFormat:@"ISSRuleset[%@]", self.displayDescription];
}

- (BOOL) isEqual:(id)object {
    if( object == self ) return YES;
    else return [object isKindOfClass:ISSRuleset.class] && [_selectorChains isEqualToArray:[object selectorChains]] &&
                                                         [_properties isEqualToArray:[(ISSRuleset*)object properties]];
}

- (NSUInteger) hash {
    return self.description.hash;
}


@end
