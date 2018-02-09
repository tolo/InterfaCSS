//
//  ISSPropertyDeclaration.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import "ISSPropertyDeclaration.h"

#import "ISSPropertyDefinition.h"
#import "NSString+ISSAdditions.h"
#import "NSObject+ISSLogSupport.h"
#import "ISSDownloadableResource.h"
#import "ISSElementStylingProxy.h"
#import "ISSUpdatableValue.h"


NSObject* const ISSPropertyDeclarationUseCurrentValue = @"<current>";


@interface ISSPropertyDeclaration ()

@property (nonatomic, strong) NSMutableDictionary* cachedTransformedValues; // TODO: Cache must be clearable (when variables change for instance)

@end


@implementation ISSPropertyDeclaration

#pragma mark - Initialization

- (instancetype) initWithPropertyName:(NSString*)name nestedElementKeyPath:(NSString*)nestedElementKeyPath {
    if ( self = [super init] ) {
        _nestedElementKeyPath = nestedElementKeyPath;
        _propertyName = name;
    }
    return self;
}

- (instancetype) initWithPropertyName:(NSString*)name parameters:(NSArray*)parameters nestedElementKeyPath:(NSString*)nestedElementKeyPath {
    if ( self = [super init] ) {
        _nestedElementKeyPath = nestedElementKeyPath;
        _propertyName = name;
        _parameters = parameters;
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
    ISSPropertyDeclaration* propertyValue = [[(id) self.class allocWithZone:zone] initWithPropertyName:self.propertyName parameters:self.parameters nestedElementKeyPath:self.nestedElementKeyPath];
    propertyValue.rawValue = self.rawValue;
    propertyValue.valueTransformationBlock = self.valueTransformationBlock;
    return propertyValue;
}


#pragma mark - Properties

- (BOOL) isNestedElementKeyPathRegistrationPlaceholder {
    return _propertyName == nil && _nestedElementKeyPath != nil;
}

- (BOOL) useCurrentValue {
    return _rawValue == ISSPropertyDeclarationUseCurrentValue;
}


#pragma mark - Property value tranform

- (id) valueForProperty:(ISSPropertyDefinition*)property {
    return [self valueForPropertyType:property.type enumValueMapping:property.enumValueMapping valueCacheKey:property.fqn];
}

- (id) valueForPropertyType:(ISSPropertyType)propertyType enumValueMapping:(ISSPropertyEnumValueMapping*)enumValueMapping valueCacheKey:(NSString*)valueCacheKey {
    id value = valueCacheKey ? self.cachedTransformedValues[valueCacheKey] : nil;
    if( !value ) {
        BOOL containsVariables = NO;
        value = self.valueTransformationBlock(self, propertyType, &containsVariables);
        
        if( !value ) {
            ISSLogWarning(@"Cannot apply property value for %@(%@) - empty property value after transform! Value before transform: '%@'.", self.propertyName, valueCacheKey, _rawValue);
            value = [NSNull null];
        } else if ( enumValueMapping ) {
            value = [enumValueMapping enumValueFromString:value];
        }
        
        if( containsVariables ) {
            ISSLogTrace(@"Value for %@(%@) not cacheable - contains variable references (%@)", self.propertyName, valueCacheKey, _rawValue);
        } else if ( valueCacheKey && self.cachedTransformedValues ) {
            self.cachedTransformedValues[valueCacheKey] = value;
        } else if ( valueCacheKey ) {
            self.cachedTransformedValues = [NSMutableDictionary dictionaryWithObject:value forKey:valueCacheKey];
        }
    } else if( value == [NSNull null] ) {
        return nil;
    }
    return value;
}


#pragma mark - NSObject overrides

- (NSString*) description {
    if( self.parameters.count ) {
        NSString* paramDesc = [[[self.parameters description] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        return [NSString stringWithFormat:@"ISSPropertyDeclaration[%@ %@]", self.propertyName, paramDesc];
    }
    else return [NSString stringWithFormat:@"ISSPropertyDeclaration[%@]", self.propertyName];
}

- (BOOL) isEqual:(id)object {
    if( object == self ) return YES;
    else if( [object isKindOfClass:ISSPropertyDeclaration.class] ) {
        ISSPropertyDeclaration* other = object;
        BOOL result = NO;
        if( [NSString iss_string:other.propertyName isEqualToString:self.propertyName] && [NSString iss_string:other.nestedElementKeyPath isEqualToString:self.nestedElementKeyPath] ) {
            if( other.parameters == self.parameters ) result = YES;
            else result = [other.parameters isEqualToArray:self.parameters];
        }
        return result && (other.isNestedElementKeyPathRegistrationPlaceholder == self.isNestedElementKeyPathRegistrationPlaceholder) &&
        ((other.rawValue == self.rawValue) || [other.rawValue isEqual:self.rawValue]);
    }
    return NO;
}

- (NSUInteger) hash {
    return self.propertyName.hash;
}

@end
