//
//  ISSPropertyDefinition.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSPropertyDefinition.h"

#import "ISSPropertyDeclaration.h"

#import <objc/runtime.h>

#import "NSObject+ISSLogSupport.h"
#import "ISSLazyValue.h"
#import "NSDictionary+ISSDictionaryAdditions.h"
#import "NSAttributedString+ISSAdditions.h"
#import "InterfaCSS.h"
#import "ISSPropertyRegistry.h"
#import "ISSRuntimeIntrospectionUtils.h"


@protocol NSValueTransformer
- (NSValue*) transformToNSValue;
@end


NSString* const ISSAnonymousPropertyDefinitionName = @"ISSAnonymousPropertyDefinition";


@implementation ISSPropertyDefinition

- (id) initAnonymousPropertyDefinitionWithType:(ISSPropertyType)type {
    return [self initWithName:ISSAnonymousPropertyDefinitionName aliases:@[] type:type];
}

- (id) initWithName:(NSString *)name type:(ISSPropertyType)type {
    return [self initWithName:name aliases:nil type:type];
}

- (id) initWithName:(NSString *)name type:(ISSPropertyType)type useIntrospection:(BOOL)useIntrospection {
    return [self initWithName:name aliases:nil type:type enumValues:nil enumBitMaskType:NO setterBlock:nil parameterEnumValues:nil useIntrospection:useIntrospection];
}

- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISSPropertyType)type {
    return [self initWithName:name aliases:aliases type:type enumValues:nil enumBitMaskType:NO];
}

- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISSPropertyType)type enumValues:(NSDictionary*)enumValues enumBitMaskType:(BOOL)enumBitMaskType {
    return [self initWithName:name aliases:aliases type:type enumValues:enumValues enumBitMaskType:enumBitMaskType setterBlock:nil parameterEnumValues:nil useIntrospection:NO];
}

// Deprecated
- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISSPropertyType)type enumValues:(NSDictionary*)enumValues
    enumBitMaskType:(BOOL)enumBitMaskType setterBlock:(PropertySetterBlock)setterBlock parameterEnumValues:(NSDictionary*)parameterEnumValues {
    
    ISSPropertySetterBlock issPropertySetterBlock = nil;
    if( setterBlock ) {
        issPropertySetterBlock = ^(ISSPropertyDefinition* property, id viewObject, id value, NSArray* parameters) {
            setterBlock(property, viewObject, value, parameters);
            return YES;
        };
    }
    
    return [self initWithName:name aliases:aliases type:type enumValues:enumValues enumBitMaskType:enumBitMaskType setterBlock:issPropertySetterBlock parameterEnumValues:parameterEnumValues useIntrospection:NO];
}

- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISSPropertyType)type enumValues:(NSDictionary*)enumValues
          enumBitMaskType:(BOOL)enumBitMaskType setterBlock:(ISSPropertySetterBlock)setterBlock parameterEnumValues:(NSDictionary*)parameterEnumValues useIntrospection:(BOOL)useIntrospection {
    if (self = [super init]) {
        _name = name;

        _allNames = [NSSet setWithObject:[name lowercaseString]];
        for(NSString* alias in aliases) {
            _allNames = [_allNames setByAddingObject:[alias lowercaseString]];
        }

        _type = type;
        _enumValues = [enumValues iss_dictionaryWithLowerCaseKeys];
        _enumBitMaskType = enumBitMaskType;

        _propertySetterBlock = setterBlock;
        _parameterEnumValues = [parameterEnumValues iss_dictionaryWithLowerCaseKeys];

        _nameIsKeyPath = [_name rangeOfString:@"."].location != NSNotFound; // Check if property name contains a "key path prefix"
        
        _useIntrospection = useIntrospection;
    }
    return self;
}

- (BOOL) anonymous {
    return self.name == ISSAnonymousPropertyDefinitionName;
}

- (BOOL) setValueUsingKVC:(id)value onTarget:(id)obj {
    @try {
        if( [value isKindOfClass:ISSLazyValue.class] ) value = [value evaluateWithParameter:obj];

        // Check if value can be transformed to NSValue (to be properly set via KVC)
        if( [value respondsToSelector:@selector(transformToNSValue)] ) value = [value transformToNSValue];

        [obj setValue:value forKeyPath:self.name]; // Will throw exception if property doesn't exist
        return YES;
    } @catch (NSException* e) {
        // Attempt to set via reflection:
        BOOL result = [ISSRuntimeIntrospectionUtils invokeSetterForProperty:self.name withValue:value inObject:obj];
        if( !result ) {
            ISSLogDebug(@"Unable to set value for property %@ - %@", self.name, e);
        }
        return result;
    }
}


#pragma mark - Public interface

- (BOOL) setValue:(id)value onTarget:(id)obj andParameters:(NSArray*)params {
    if( [value isKindOfClass:ISSLazyValue.class] ) value = [value evaluateWithParameter:obj];
    if( value && value != [NSNull null] ) {
        BOOL result;
        if( self.propertySetterBlock ) {
            result = self.propertySetterBlock(self, obj, value, params);
        }
        else if( self.useIntrospection ) {
            result = [ISSRuntimeIntrospectionUtils invokeSetterForProperty:self.name withValue:value inObject:obj];
        }
        else {
            result = [self setValueUsingKVC:value onTarget:obj];
        }
        // If property couldn't be set - try overridden definition, if available
        if( !result && self.overriddenDefinition ) {
            return [self.overriddenDefinition setValue:value onTarget:obj andParameters:params];
        }
        return result;
    }
    return NO;
}

- (BOOL) isParameterizedProperty {
    return self.parameterEnumValues != nil;
}

- (NSString*) displayDescription {
    return self.name;
}

- (NSString*) uniqueTypeDescription {
    if( self.type == ISSPropertyTypeEnumType ) return [NSString stringWithFormat:@"Enum(%@)", self.name];
    else return [self typeDescription];
}

- (NSString*) typeDescription {
    switch(self.type) {
        case ISSPropertyTypeAttributedString : return @"NSAttributedString";
        case ISSPropertyTypeBool : return @"Boolean";
        case ISSPropertyTypeNumber : return @"Number";
        case ISSPropertyTypeOffset : return @"UIOffset";
        case ISSPropertyTypeRect : return @"CGRect";
        case ISSPropertyTypeLayout : return @"ISSLayout";
        case ISSPropertyTypeSize : return @"CGSize";
        case ISSPropertyTypePoint : return @"CGPoint";
        case ISSPropertyTypeEdgeInsets : return @"UIEdgeInsets";
        case ISSPropertyTypeColor : return @"UIColor";
        case ISSPropertyTypeCGColor : return @"CGColor";
        case ISSPropertyTypeTransform : return @"CGAffineTransform";
        case ISSPropertyTypeFont : return @"UIFont";
        case ISSPropertyTypeImage : return @"UIImage";
        case ISSPropertyTypeEnumType : return @"Enum";
        default: return @"NSString";
    }
}

- (BOOL) supportsDynamicValue {
    return self.type == ISSPropertyTypeRect || self.type == ISSPropertyTypePoint; // i.e. value could be relative rect or relative point
}

- (NSComparisonResult) compareByName:(ISSPropertyDefinition*)other {
    return [self.name compare:other.name];
}

#pragma mark - NSObject overrides


- (NSString*) description {
    return [NSString stringWithFormat:@"ISSPropertyDefinition[%@]", self.displayDescription];
}

- (BOOL) isEqual:(id)object {
    if( object == self ) return YES;
    else return [object isKindOfClass:ISSPropertyDefinition.class] &&
           [self.name isEqualToString:((ISSPropertyDefinition*)object).name] &&
           self.type == ((ISSPropertyDefinition*)object).type;
}

- (NSUInteger) hash {
    return self.name.hash;
}

@end