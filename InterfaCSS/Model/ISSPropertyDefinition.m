//
//  ISSPropertyDefinition.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSPropertyDefinition+Private.h"

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


@implementation ISSPropertyDefinition {
    BOOL _prePrefixed;
}

- (id) initAnonymousPropertyDefinitionWithType:(ISSPropertyType)type {
    return [self initWithName:ISSAnonymousPropertyDefinitionName aliases:@[] type:type];
}

- (id) initWithName:(NSString *)name type:(ISSPropertyType)type {
    return [self initWithName:name aliases:@[] type:type];
}

- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISSPropertyType)type {
    return [self initWithName:name aliases:aliases type:type enumBlock:nil enumBitMaskType:NO];
}

- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISSPropertyType)type enumBlock:(NSDictionary*)enumValues enumBitMaskType:(BOOL)enumBitMaskType {
    return [self initWithName:name aliases:aliases type:type enumValues:enumValues enumBitMaskType:enumBitMaskType setterBlock:nil parameterEnumValues:nil];
}

- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISSPropertyType)type enumValues:(NSDictionary*)enumValues
          enumBitMaskType:(BOOL)enumBitMaskType setterBlock:(void (^)(ISSPropertyDefinition*, id, id, NSArray*))setterBlock parameterEnumValues:(NSDictionary*)parameterEnumValues {
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

        _prePrefixed = [_name rangeOfString:@"."].location != NSNotFound; // Check if property name contains a "key path prefix"
    }
    return self;
}

- (BOOL) anonymous {
    return self.name == ISSAnonymousPropertyDefinitionName;
}

- (id) targetObjectForObject:(id)obj andPrefixKeyPath:(NSString*)prefixKeyPath {
    if( prefixKeyPath ) {
        if( _prePrefixed && ([_name rangeOfString:prefixKeyPath options:NSCaseInsensitiveSearch].location == 0) ) {
            // Use prefix for "prePrefixed" property, only if different than prefix found in _name...
            return obj;
        }

        // First, check if prefix key path is a valid selector
        if( [obj respondsToSelector:NSSelectorFromString(prefixKeyPath)] ) {
            return [obj valueForKeyPath:prefixKeyPath];
        } else {
            // Then attempt to match prefix key path against known prefix key paths, and make sure correct name is used
            NSString* validPrefix = [InterfaCSS sharedInstance].propertyRegistry.validPrefixKeyPaths[[prefixKeyPath lowercaseString]];
            if( validPrefix && [obj respondsToSelector:NSSelectorFromString(validPrefix)] ) {
                return [obj valueForKeyPath:validPrefix];
            }

            ISSLogDebug(@"Unable to find prefix key path '%@' in %@", prefixKeyPath, obj);
        }
    }
    return obj;
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

- (void) setValue:(id)value onTarget:(id)obj andParameters:(NSArray*)params withPrefixKeyPath:(NSString*)prefixKeyPath {
    obj = [self targetObjectForObject:obj andPrefixKeyPath:prefixKeyPath];
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
        case ISSPropertyTypeBool : return @"Boolean";
        case ISSPropertyTypeNumber : return @"Number";
        case ISSPropertyTypeOffset : return @"UIOffset";
        case ISSPropertyTypeRect : return @"CGRect";
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