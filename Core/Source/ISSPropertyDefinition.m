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
#import "NSDictionary+ISSAdditions.h"


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

- (instancetype) initWithEnumValues:(NSDictionary*)enumValues enumBaseName:(NSString*)enumBaseName defaultValue:(nullable id)defaultValue {
    if (self = [super init]) {
        _enumValues = [enumValues iss_dictionaryWithLowerCaseKeys];
        _enumBaseName = [enumBaseName lowercaseString];
        _defaultValue = defaultValue;
    }
    return self;
}

- (id) enumValueFromString:(NSString*)string {
    NSString* lcEnumName = [string lowercaseString];
    id value = self.enumValues[lcEnumName];
    if ( !value && [lcEnumName hasPrefix:self.enumBaseName] ) {
        value = self.enumValues[[lcEnumName substringFromIndex:self.enumBaseName.length]];
    }
    return value ?: self.defaultValue;
}

@end

@implementation ISSPropertyBitMaskEnumValueMapping : ISSPropertyEnumValueMapping

static NSCharacterSet* bitMaskSeparator;

+ (NSCharacterSet*) bitMaskEnumValueSeparator {
    static dispatch_once_t rfc1123DateFormatterOnceToken;
    dispatch_once(&rfc1123DateFormatterOnceToken, ^{
        bitMaskSeparator = [NSCharacterSet characterSetWithCharactersInString:@" |"];
    });
    return bitMaskSeparator;
}

- (id) enumValueFromString:(NSString*)string {
    NSArray* stringValues = [[string lowercaseString] componentsSeparatedByCharactersInSet:[ISSPropertyBitMaskEnumValueMapping bitMaskEnumValueSeparator]];
    NSNumber* result = nil;
    for(NSString* stringValue in stringValues) {
        id enumValue = [super enumValueFromString:stringValue];
        if( enumValue ) {
            NSUInteger constVal = [enumValue unsignedIntegerValue];
            if( result ) result = @([result unsignedIntegerValue] | constVal);
            else result = @(constVal);
        } else {
            [self iss_logWarning:@"Unrecognized enum value: '%@'", stringValue];
        }
    }
    return result ?: self.defaultValue;
}

@end


@implementation ISSPropertyDefinition

- (instancetype) init {
    @throw([NSException exceptionWithName:NSInternalInconsistencyException reason:@"Hold on there professor, init not allowed!" userInfo:nil]);
}

- (instancetype) initCustomPropertyWithName:(NSString*)name inClass:(Class)clazz type:(ISSPropertyType)type enumValueMapping:(ISSPropertyEnumValueMapping*)enumValueMapping parameterTransformers:(NSArray*)parameterTransformers setterBlock:(ISSPropertySetterBlock)setter {
    if (self = [super init]) {
        _name = name;
        _declaredInClass = clazz;
        _type = type;
        _enumValueMapping = enumValueMapping;
        _parameterTransformers = parameterTransformers;
        _setterBlock = setter;
    }
    return self;
}

- (instancetype) initCustomPropertyWithName:(NSString*)name inClass:(Class)clazz type:(ISSPropertyType)type setterBlock:(ISSPropertySetterBlock)setter {
    return [self initCustomPropertyWithName:name inClass:clazz type:type enumValueMapping:nil parameterTransformers:nil setterBlock:setter];
}

- (instancetype) initWithRuntimeProperty:(ISSRuntimeProperty*)runtimeProperty type:(ISSPropertyType)type enumValueMapping:(nullable ISSPropertyEnumValueMapping*)enumValueMapping {
    return [self initCustomPropertyWithName:runtimeProperty.propertyName inClass:runtimeProperty.foundInClass type:type enumValueMapping:enumValueMapping parameterTransformers:nil setterBlock:^BOOL(ISSPropertyDefinition* property, id target, id value, NSArray* parameters) {
        return [ISSRuntimeIntrospectionUtils invokeSetterForRuntimeProperty:runtimeProperty withValue:value inObject:target];
    }];
}

- (instancetype) initParameterizedPropertyWithName:(NSString*)name inClass:(Class)clazz type:(ISSPropertyType)type selector:(SEL)selector enumValueMapping:(nullable ISSPropertyEnumValueMapping*)enumValueMapping parameterTransformers:(NSArray*)parameterTransformers {
    return [self initCustomPropertyWithName:name inClass:clazz type:type enumValueMapping:enumValueMapping parameterTransformers:parameterTransformers setterBlock:^BOOL(ISSPropertyDefinition* property, id target, id value, NSArray* parameters) {
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


- (BOOL) setValue:(id)value onTarget:(id)target withParameters:(NSArray*)params {
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
