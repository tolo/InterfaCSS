//
//  ISSPropertyDefinition.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@class ISSPropertyDefinition;

typedef void (^PropertySetterBlock)(ISSPropertyDefinition* property, id viewObject, id _Nullable value, NSArray* _Nullable parameters) __deprecated;

typedef BOOL (^ISSPropertySetterBlock)(ISSPropertyDefinition* property, id viewObject, id _Nullable value, NSArray* _Nullable parameters);


typedef NS_ENUM(NSInteger, ISSPropertyType) {
    ISSPropertyTypeString,
    ISSPropertyTypeAttributedString,
    ISSPropertyTypeBool,
    ISSPropertyTypeNumber,
    ISSPropertyTypeOffset,
    ISSPropertyTypeRect,
    ISSPropertyTypeLayout,
    ISSPropertyTypeSize,
    ISSPropertyTypePoint,
    ISSPropertyTypeEdgeInsets,
    ISSPropertyTypeColor,
    ISSPropertyTypeCGColor,
    ISSPropertyTypeTransform,
    ISSPropertyTypeFont,
    ISSPropertyTypeImage,
    ISSPropertyTypeEnumType,
};

/**
 * Represents the definition of a property that can be declared in a stylesheet. This class is also the repository for all available property definitions
 * supported by InterfaCSS.
 */
@interface ISSPropertyDefinition : NSObject

@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) BOOL nameIsKeyPath; // Indicates weather this property definition refers to a property in a nested property, i.e. the name field contains a property name prefix
@property (nonatomic, readonly) BOOL anonymous;
@property (nonatomic, readonly) NSSet* allNames; // lowercase names/aliases


@property (nonatomic, readonly) ISSPropertyType type;
@property (nonatomic, readonly) NSString* typeDescription;
@property (nonatomic, readonly) NSString* uniqueTypeDescription;
@property (nonatomic, readonly) BOOL supportsDynamicValue; // Indicates weather the value of this property may be dynamic, i.e. may need to be re-evaluated every time styles are applied

@property (nonatomic, readonly, nullable) NSDictionary* parameterEnumValues;
@property (nonatomic, readonly, nullable) NSDictionary* enumValues;
@property (nonatomic, readonly) BOOL enumBitMaskType;

@property (nonatomic, readonly) BOOL useIntrospection;

@property (nonatomic, copy, readonly, nullable) ISSPropertySetterBlock propertySetterBlock;

@property (nonatomic, readonly) BOOL isParameterizedProperty;

@property (nonatomic, readonly) NSString* displayDescription;

@property (nonatomic, strong, nullable) ISSPropertyDefinition* overriddenDefinition;


/**
 * Creates a temporary, anonymous, property definition.
 */
- (id) initAnonymousPropertyDefinitionWithType:(ISSPropertyType)type;

/**
 * Creates a simple property definition.
 */
- (id) initWithName:(NSString*)name type:(ISSPropertyType)type;

/**
 * Creates a simple property definition that optionally can set it's value via introspection (i.e. use declared or default setter method for property), instead of using KVC.
 */
- (id) initWithName:(NSString *)name type:(ISSPropertyType)type useIntrospection:(BOOL)useIntrospection;

/**
 * Creates a property definition with an optional number of aliases.
 */
- (id) initWithName:(NSString*)name aliases:(nullable NSArray*)aliases type:(ISSPropertyType)type;

/**
 * Creates a property definition with an optional number of aliases.
 * If this is an enum property, specify the enum values in the `enumValues` parameter. If the enum values are of a bit mask type, specify `YES` in the `enumBitMaskType` parameter.
 */
- (id) initWithName:(NSString*)name aliases:(nullable NSArray*)aliases type:(ISSPropertyType)type enumValues:(nullable NSDictionary*)enumValues enumBitMaskType:(BOOL)enumBitMaskType;

/**
 * Creates a property definition with an optional number of aliases.
 * If this is an enum property, specify the enum values in the `enumValues` parameter. If the enum values are of a bit mask type, specify `YES` in the `enumBitMaskType` parameter.
 * If this is a parameterized property, specify the parameter value transformation dictionary in `parameterEnumValues`.
 * To use a custom handling for setting the property value - specify a property setter block in the `setterBlock` parameter.
 */
- (id) initWithName:(NSString*)name aliases:(nullable NSArray*)aliases type:(ISSPropertyType)type enumValues:(nullable NSDictionary*)enumValues
    enumBitMaskType:(BOOL)enumBitMaskType setterBlock:(nullable PropertySetterBlock)setterBlock parameterEnumValues:(nullable NSDictionary*)parameterEnumValues 
    __deprecated_msg("Due to deprecation of setter block type`");

/**
 * Creates a property definition with an optional number of aliases, that optionally can set it's value via introspection (i.e. use declared or default setter method for property), instead of using KVC.
 * If this is an enum property, specify the enum values in the `enumValues` parameter. If the enum values are of a bit mask type, specify `YES` in the `enumBitMaskType` parameter.
 * If this is a parameterized property, specify the parameter value transformation dictionary in `parameterEnumValues`.
 * To use a custom handling for setting the property value - specify a property setter block in the `setterBlock` parameter.
 */
- (id) initWithName:(NSString*)name aliases:(nullable NSArray*)aliases type:(ISSPropertyType)type enumValues:(nullable NSDictionary*)enumValues
    enumBitMaskType:(BOOL)enumBitMaskType setterBlock:(nullable ISSPropertySetterBlock)setterBlock parameterEnumValues:(nullable NSDictionary*)parameterEnumValues useIntrospection:(BOOL)useIntrospection;


/**
 * Sets the value of the property represented by this object, on the specified target.
 */
- (BOOL) setValue:(nullable id)value onTarget:(nullable id)target andParameters:(nullable NSArray*)params;

- (NSComparisonResult) compareByName:(nullable ISSPropertyDefinition*)other;

@end

NS_ASSUME_NONNULL_END
