//
//  ISSPropertyDeclaration.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSPropertyDeclaration.h"

#import "ISSPropertyDefinition.h"

@implementation ISSPropertyDeclaration

- (instancetype) initWithProperty:(ISSPropertyDefinition*)property prefix:(NSString*)prefix {
    self = [super init];
    if ( self ) {
        _prefix = prefix;
        _property = property;
    }
    return self;
}

- (instancetype) initWithProperty:(ISSPropertyDefinition*)property parameters:(NSArray*)parameters prefix:(NSString*)prefix {
    self = [super init];
    if ( self ) {
        _prefix = prefix;
        _property = property;
        _parameters = parameters;
    }
    return self;
}

- (instancetype) initWithUnrecognizedProperty:(NSString*)unrecognizedPropertyName {
    self = [super init];
    if ( self ) {
        _unrecognizedName = unrecognizedPropertyName;
    }
    return self;
}

#pragma mark - NSCopying

- (id) copyWithZone:(NSZone*)zone {
    return [[self.class allocWithZone:zone] initWithProperty:self.property parameters:self.parameters prefix:self.prefix];
}


#pragma mark - Public interface

- (BOOL) setValue:(id)value onTarget:(id)target {
    if( !self.property ) return NO;

    if ( self.parameters.count ) {
        [self.property setValue:value onTarget:target andParameters:self.parameters withPrefixKeyPath:self.prefix];
    } else {
        [self.property setValue:value onTarget:target withPrefixKeyPath:self.prefix];
    }
    return YES;
}


#pragma mark - NSObject overrides

- (NSString*) description {
    if( self.parameters.count ) {
        NSString* paramDesc = [[[self.parameters description] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        return [NSString stringWithFormat:@"ISSPropertyDeclaration[%@ %@]", self.property.displayDescription, paramDesc];
    } else return [NSString stringWithFormat:@"ISSPropertyDeclaration[%@]", self.property.displayDescription];
}

- (BOOL) isEqual:(id)object {
    if( [object isKindOfClass:ISSPropertyDeclaration.class] && [[object property] isEqual:self.property] ) {
        if( [object parameters] == self.parameters ) return YES;
        else return [[object parameters] isEqualToArray:self.parameters];
    }
    return NO;
}

- (NSUInteger) hash {
    return self.property.hash;
}

@end