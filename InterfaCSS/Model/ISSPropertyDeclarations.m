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

- (BOOL) matchesView:(UIView*)view {
    for(ISSSelectorChain* selectorChain in _selectorChains) {
        if ( [selectorChain matchesView:view] )  return YES;
    }
    return NO;
}

- (NSString*) displayDescription {
    NSMutableString* chains = [NSMutableString string];
    for(ISSSelectorChain* chain in _selectorChains) {
        if( chains.length == 0 ) [chains appendFormat:@"%@", chain.displayDescription];
        else [chains appendFormat:@", %@", chain.displayDescription];
    }
    return [NSString stringWithFormat:@"%@ : %@", chains, _properties];
}


#pragma mark - NSObject overrides


- (NSString*) description {
    return [NSString stringWithFormat:@"ISSPropertyDeclarations[%@]", self.displayDescription];
}

- (BOOL) isEqual:(id)object {
    return [[object class] isKindOfClass:self.class] && [_selectorChains isEqualToArray:[object selectorChains]] &&
                                                         [_properties isEqualToDictionary:[object properties]];
}

- (NSUInteger) hash {
    return self.description.hash;
}


@end
