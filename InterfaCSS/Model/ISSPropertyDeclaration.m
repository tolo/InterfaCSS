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
#import "NSString+ISSStringAdditions.h"
#import "ISSLazyValue.h"
#import "NSObject+ISSLogSupport.h"

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
    ISSPropertyDeclaration* decl;
    if( _unrecognizedName ) decl = [[self.class allocWithZone:zone] initWithUnrecognizedProperty:_unrecognizedName];
    else {
        decl = [[self.class allocWithZone:zone] initWithProperty:self.property parameters:self.parameters prefix:self.prefix];
        decl.propertyValue = self.propertyValue;
        decl.lazyPropertyTransformationBlock = self.lazyPropertyTransformationBlock;
    }
    return decl;
}


#pragma mark - Public interface


- (void) transformValueIfNeeded {
    if( self.lazyPropertyTransformationBlock ) {
        self.propertyValue = self.lazyPropertyTransformationBlock(self);
        self.lazyPropertyTransformationBlock = nil;
    }
}

- (BOOL) applyPropertyValueOnTarget:(id)target {
    if( !self.property ) return NO;

    [self transformValueIfNeeded];
    if( !self.propertyValue ) return NO;

    [self.property setValue:self.propertyValue onTarget:target andParameters:self.parameters withPrefixKeyPath:self.prefix];

    return YES;
}


#pragma mark - NSObject overrides

- (NSString*) description {
    if( self.parameters.count ) {
        NSString* paramDesc = [[[self.parameters description] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        return [NSString stringWithFormat:@"ISSPropertyDeclaration[%@ %@]", self.property.displayDescription, paramDesc];
    }
    else if( self.unrecognizedName ) return [NSString stringWithFormat:@"ISSPropertyDeclaration[%@]", self.unrecognizedName];
    else return [NSString stringWithFormat:@"ISSPropertyDeclaration[%@]", self.property.displayDescription];
}

- (BOOL) isEqual:(id)object {
    if( object == self ) return YES;
    else if( [object isKindOfClass:ISSPropertyDeclaration.class] && [[object property] isEqual:self.property] &&
            [NSString iss_string:[object prefix] isEqualToString:self.prefix] ) {
        if( [object parameters] == self.parameters ) return YES;
        else return [[object parameters] isEqualToArray:self.parameters];
    }
    return NO;
}

- (NSUInteger) hash {
    return self.property.hash;
}

@end
