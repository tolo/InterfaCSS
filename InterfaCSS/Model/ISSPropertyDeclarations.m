//
//  ISSPropertyDeclarations.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSPropertyDeclarations.h"

#import "ISSSelectorChain.h"
#import "ISSUIElementDetails.h"

@implementation ISSPropertyDeclarations {
    NSArray* _selectorChains;
    NSDictionary* _properties;
}


#pragma mark - ISSPropertyDeclarations interface


- (id) initWithSelectorChains:(NSArray*)selectorChains andProperties:(NSDictionary*)properties {
    if( self = [super init] ) {
        _selectorChains = selectorChains;
        _properties = properties;
    }
    return self;
}

- (BOOL) matchesElement:(ISSUIElementDetails*)elementDetails {
    for(ISSSelectorChain* selectorChain in _selectorChains) {
        if ( [selectorChain matchesElement:elementDetails] )  return YES;
    }
    return NO;
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
    return [NSString stringWithFormat:@"ISSPropertyDeclarations[%@]", self.displayDescription];
}

- (BOOL) isEqual:(id)object {
    return [object isKindOfClass:ISSPropertyDeclarations.class] && [_selectorChains isEqualToArray:[object selectorChains]] &&
                                                         [_properties isEqualToDictionary:[object properties]];
}

- (NSUInteger) hash {
    return self.description.hash;
}


@end
