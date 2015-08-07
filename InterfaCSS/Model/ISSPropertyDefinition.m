//
//  ISSPropertyDefinition.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
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


@protocol NSValueTransformer
- (NSValue*) transformToNSValue;
@end


NSString* const ISSAnonymousPropertyDefinitionName = @"ISSAnonymousPropertyDefinition";


@implementation ISSPropertyDefinition 

- (id) initAnonymousPropertyDefinitionWithType:(ISSPropertyType)type {
    return [self initWithName:ISSAnonymousPropertyDefinitionName aliases:@[] type:type];
}

- (id) initWithName:(NSString *)name type:(ISSPropertyType)type {
    return [self initWithName:name aliases:@[] type:type];
}

- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISSPropertyType)type {
    return [self initWithName:name aliases:aliases type:type enumValues:nil enumBitMaskType:NO];
}

- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISSPropertyType)type enumValues:(NSDictionary*)enumValues enumBitMaskType:(BOOL)enumBitMaskType {
    return [self initWithName:name aliases:aliases type:type enumValues:enumValues enumBitMaskType:enumBitMaskType setterBlock:nil parameterEnumValues:nil];
}

- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISSPropertyType)type enumValues:(NSDictionary*)enumValues
          enumBitMaskType:(BOOL)enumBitMaskType setterBlock:(PropertySetterBlock)setterBlock parameterEnumValues:(NSDictionary*)parameterEnumValues {
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
    }
    return self;
}

- (BOOL) anonymous {
    return self.name == ISSAnonymousPropertyDefinitionName;
}

- (void) setValueUsingKVC:(id)value onTarget:(id)obj {
    @try {
        if( [value isKindOfClass:ISSLazyValue.class] ) value = [value evaluateWithParameter:obj];

        // Check if value can be transformed to NSValue (to be properly set via KVC)
        if( [value respondsToSelector:@selector(transformToNSValue)] ) value = [value transformToNSValue];

        [obj setValue:value forKeyPath:_name]; // Will throw exception if property doesn't exist
    } @catch (NSException* e) {
        ISSLogDebug(@"Unable to set value for property %@ - %@", _name, e);
    }
}


#pragma mark - Public interface

- (void) setValue:(id)value onTarget:(id)obj andParameters:(NSArray*)params { //withPrefixKeyPath:(NSString*)prefixKeyPath {
    if( [value isKindOfClass:ISSLazyValue.class] ) value = [value evaluateWithParameter:obj];
    if( value && value != [NSNull null] ) {
        if( _propertySetterBlock ) {
            _propertySetterBlock(self, obj, value, params);
        } else {
            [self setValueUsingKVC:value onTarget:obj];
        }
    }
}

- (BOOL) isParameterizedProperty {
    return _parameterEnumValues != nil;
}

- (NSString*) displayDescription {
    return self.name;
}

- (NSString*) uniqueTypeDescription {
    if( self.type == ISSPropertyTypeEnumType ) return [NSString stringWithFormat:@"Enum(%@)", _name];
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