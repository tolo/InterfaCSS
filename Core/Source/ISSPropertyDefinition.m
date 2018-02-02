//
//  ISSPropertyDefinition.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <objc/runtime.h>

#import "ISSPropertyDefinition.h"

#import "ISSPropertyManager.h"

#import "ISSPropertyDeclaration.h"
#import "ISSRuntimeIntrospectionUtils.h"
#import "ISSRuntimeProperty.h"

#import "NSObject+ISSLogSupport.h"



ISSPropertyType const ISSPropertyTypeString = @"String";
ISSPropertyType const ISSPropertyTypeAttributedString = @"AttributedString";
ISSPropertyType const ISSPropertyTypeTextAttributes = @"TextAttributes";
ISSPropertyType const ISSPropertyTypeBool = @"Bool";
ISSPropertyType const ISSPropertyTypeNumber = @"Number";
ISSPropertyType const ISSPropertyTypeOffset = @"Offset";
ISSPropertyType const ISSPropertyTypeRect = @"Rect";
ISSPropertyType const ISSPropertyTypeSize = @"Size";
ISSPropertyType const ISSPropertyTypePoint = @"Point";
ISSPropertyType const ISSPropertyTypeEdgeInsets = @"EdgeInsets";
ISSPropertyType const ISSPropertyTypeColor = @"Color";
ISSPropertyType const ISSPropertyTypeCGColor = @"CGColor";
ISSPropertyType const ISSPropertyTypeTransform = @"Transform";
ISSPropertyType const ISSPropertyTypeFont = @"Font";
ISSPropertyType const ISSPropertyTypeImage = @"Image";
ISSPropertyType const ISSPropertyTypeEnumType = @"EnumType";
ISSPropertyType const ISSPropertyTypeUnknown = @"Unknown";



@implementation ISSPropertyEnumValueMapping

- (instancetype) initWithEnumValues:(NSDictionary*)enumValues defaultValue:(nullable id)defaultValue {
    if (self = [super init]) {
        _enumValues = enumValues;
        _enumBitMaskType = NO;
        _defaultValue = defaultValue;
    }
    return self;
}

- (instancetype) initWithBitMaskEnumValues:(NSDictionary*)enumValues defaultValue:(nullable id)defaultValue {
    if (self = [super init]) {
        _enumValues = enumValues;
        _enumBitMaskType = YES;
        _defaultValue = defaultValue;
    }
    return self;
}

- (instancetype) initWithEnumValues:(NSDictionary*)enumValues enumBitMaskType:(BOOL)enumBitMaskType {
    if (self = [super init]) {
        _enumValues = enumValues;
        _enumBitMaskType = enumBitMaskType;
    }
    return self;
}

- (id) enumValueFromString:(NSString*)string {
    if( self.enumBitMaskType ) {
        NSArray* values = [[string lowercaseString] componentsSeparatedByString:@" "];
        NSNumber* result = self.defaultValue;
        for(NSString* value in values) {
            id enumValue = self.enumValues[value];
            if( enumValue ) {
                NSUInteger constVal = [enumValue unsignedIntegerValue];
                if( result ) result = @([result unsignedIntegerValue] | constVal);
                else result = @(constVal);
            } else {
                [self iss_logWarning:@"Unrecognized enum value: '%@'", value];
            }
        }
        return result;
        
    } else {
        return self.enumValues[[string lowercaseString]] ?: self.defaultValue;
    }
}

@end


@implementation ISSPropertyDefinition

- (instancetype) initCustomPropertyWithName:(NSString*)name inClass:(Class)clazz type:(ISSPropertyType)type setterBlock:(ISSPropertySetterBlock)setter {
    if (self = [super init]) {
        _name = name;
        _declaredInClass = clazz;
        _type = type;
        _setterBlock = setter;
    }
    return self;
}

- (instancetype) initWithRuntimeProperty:(ISSRuntimeProperty*)runtimeProperty type:(ISSPropertyType)type enumValueMapping:(nullable ISSPropertyEnumValueMapping*)enumValueMapping {
    return [self initCustomPropertyWithName:runtimeProperty.propertyName inClass:runtimeProperty.foundInClass type:type setterBlock:^BOOL(ISSPropertyDefinition* property, id target, id value, NSArray* parameters) {
        id effectiveValue = enumValueMapping ? [enumValueMapping enumValueFromString:value] : value;
        return [ISSRuntimeIntrospectionUtils invokeSetterForRuntimeProperty:runtimeProperty withValue:effectiveValue inObject:target];
    }];
}

- (instancetype) initParameterizedPropertyWithName:(NSString*)name inClass:(Class)clazz type:(ISSPropertyType)type selector:(SEL)selector parameterTransformers:(NSArray*)parameterTransformers {
    return [self initCustomPropertyWithName:name inClass:clazz type:type setterBlock:^BOOL(ISSPropertyDefinition* property, id target, id value, NSArray* parameters) {
        NSMutableArray* arguments = [NSMutableArray arrayWithObject:value];
        for(int i=0; i<parameterTransformers.count; i++) {
            ISSPropertyParameterTransformer transformer = parameterTransformers[i];
            [arguments addObject:transformer(property, i< parameters.count ? parameters[i] : [NSNull null])];
        }
        return [ISSRuntimeIntrospectionUtils invokeInstanceSelector:selector withArguments:arguments inObject:target];
    }];
}

- (NSString*) fqn {
    return [NSString stringWithFormat:@"%@.%@", NSStringFromClass(self.declaredInClass), self.name];
}


- (BOOL) setValue:(nullable id)value onTarget:(nullable id)target withParameters:(nullable NSArray*)params {
    return self.setterBlock(self, target, value, params);
}


#pragma mark - NSObject overrides

- (NSString*) description {
    return [NSString stringWithFormat:@"ISSPropertyDefinition[%@]", self.fqn];
}

- (BOOL) isEqual:(id)object {
    if( object == self ) return YES;
    else return [object isKindOfClass:ISSPropertyDefinition.class] &&
           [self.fqn isEqualToString:((ISSPropertyDefinition*)object).fqn] &&
           self.type == ((ISSPropertyDefinition*)object).type;
}

- (NSUInteger) hash {
    return self.fqn.hash;
}

@end
