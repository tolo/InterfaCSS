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
#import "NSObject+ISSLogSupport.h"


NSObject* const ISSPropertyDefinitionUseCurrentValue = @"<current>";


@implementation ISSPropertyDeclaration

- (instancetype) initWithProperty:(ISSPropertyDefinition*)property nestedElementKeyPath:(NSString*)nestedElementKeyPath {
    self = [super init];
    if ( self ) {
        _nestedElementKeyPath = nestedElementKeyPath;
        _property = property;
    }
    return self;
}

- (instancetype) initWithProperty:(ISSPropertyDefinition*)property parameters:(NSArray*)parameters nestedElementKeyPath:(NSString*)nestedElementKeyPath {
    self = [super init];
    if ( self ) {
        _nestedElementKeyPath = nestedElementKeyPath;
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
    if( _unrecognizedName ) decl = [[(id)self.class allocWithZone:zone] initWithUnrecognizedProperty:_unrecognizedName];
    else {
        decl = [[(id) self.class allocWithZone:zone] initWithProperty:self.property parameters:self.parameters nestedElementKeyPath:self.nestedElementKeyPath];
        decl.propertyValue = self.propertyValue;
        decl.lazyPropertyTransformationBlock = self.lazyPropertyTransformationBlock;
    }
    return decl;
}


#pragma mark - Public interface

- (BOOL) dynamicValue {
    return self.property.supportsDynamicValue;
}

- (BOOL) transformValueIfNeeded {
    if( self.lazyPropertyTransformationBlock ) {
        self.propertyValue = self.lazyPropertyTransformationBlock(self);
        self.lazyPropertyTransformationBlock = nil;
        return YES;
    }
    return NO;
}

- (BOOL) applyPropertyValueOnTarget:(id)target {
    if( !self.property ) {
        ISSLogWarning(@"Cannot apply property value - unknown property!");
        return NO;
    }
    if( !self.propertyValue ) {
        ISSLogWarning(@"Cannot apply property value - value is nil!");
        return NO;
    }
    if( self.propertyValue == ISSPropertyDefinitionUseCurrentValue ) {
        ISSLogTrace(@"Property value not changed - using existing value");
        return YES;
    }

    id valueBeforeTransform = self.propertyValue;
    BOOL didTransform = [self transformValueIfNeeded];
    if( didTransform && !self.propertyValue ) {
        ISSLogWarning(@"Cannot apply property value - empty property value after transform! Value before transform: '%@'.", valueBeforeTransform);
        return NO;
    }

    return [self.property setValue:self.propertyValue onTarget:target andParameters:self.parameters];
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
            [NSString iss_string:[object nestedElementKeyPath] isEqualToString:self.nestedElementKeyPath] ) {
        if( [object parameters] == self.parameters ) return YES;
        else return [[object parameters] isEqualToArray:self.parameters];
    }
    return NO;
}

- (NSUInteger) hash {
    return self.property.hash;
}

@end
