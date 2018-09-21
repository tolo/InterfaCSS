//
//  ISSPropertyDeclaration.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import "ISSPropertyDeclaration.h"

#import "ISSStyleSheetManager.h"

#import "ISSPropertyDefinition.h"
#import "NSString+ISSAdditions.h"
#import "NSObject+ISSLogSupport.h"
#import "ISSDownloadableResource.h"
#import "ISSElementStylingProxy.h"
#import "ISSUpdatableValue.h"


NSString* const ISSPropertyDeclarationUseCurrentValue = @"<current>";


@implementation ISSPropertyDeclaration

#pragma mark - Initialization

- (instancetype) initWithPropertyName:(NSString*)name rawValue:(NSString*)rawValue rawParameters:(NSArray<NSString*>*)rawParameters nestedElementKeyPath:(NSString*)nestedElementKeyPath {
    if ( self = [super init] ) {
        _propertyName = name;
        _rawValue = rawValue;
        _rawParameters = rawParameters;
        _nestedElementKeyPath = nestedElementKeyPath;
    }
    return self;
}

- (instancetype) initWithNestedElementKeyPathToRegister:(NSString*)nestedElementKeyPath {
    if ( self = [super init] ) {
        _nestedElementKeyPath = nestedElementKeyPath;
    }
    return self;
}

- (id) copyWithZone:(NSZone*)zone {
    return [[(id) self.class allocWithZone:zone] initWithPropertyName:self.propertyName rawValue:self.rawValue rawParameters:self.rawParameters nestedElementKeyPath:self.nestedElementKeyPath];
}


#pragma mark - Properties

- (BOOL) isNestedElementKeyPathRegistrationPlaceholder {
    return _propertyName == nil && _nestedElementKeyPath != nil;
}

- (BOOL) useCurrentValue {
    return _rawValue == ISSPropertyDeclarationUseCurrentValue;
}

- (NSString*) fqn {
    if( self.isNestedElementKeyPathRegistrationPlaceholder ) {
        return _nestedElementKeyPath ?: @"";
    }
    if( _nestedElementKeyPath ) {
        return [[_nestedElementKeyPath stringByAppendingString:@"."] stringByAppendingString:_propertyName];
    }
    return _propertyName ?: @"";
}

- (NSString*) stringRepresentation {
    NSMutableString* str = [[NSMutableString alloc] initWithString:self.fqn];
    if( self.rawParameters ) {
        [str appendFormat:@"(%@)", [self.rawParameters componentsJoinedByString:@", "]];
    }
    if( self.rawValue ) {
        [str appendFormat:@" = %@;", self.rawValue];
    }
    return [str copy];
}


#pragma mark - NSObject overrides

- (NSString*) description {
    return [NSString stringWithFormat:@"ISSPropertyDeclaration[%@]", self.stringRepresentation];
}

- (BOOL) isEqual:(id)object {
    if( object == self ) return YES;
    else if( [object isKindOfClass:ISSPropertyDeclaration.class] ) {
        ISSPropertyDeclaration* other = object;
        return [self.stringRepresentation isEqualToString:other.stringRepresentation];
    }
    return NO;
}

- (NSUInteger) hash {
    return self.fqn.hash;
}

@end
