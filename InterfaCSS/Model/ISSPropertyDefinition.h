//
//  ISSPropertyDefinition.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

typedef NS_ENUM(NSInteger, ISSPropertyType) {
    ISSPropertyTypeString,
    ISSPropertyTypeBool,
    ISSPropertyTypeNumber,
    ISSPropertyTypeOffset,
    ISSPropertyTypeRect,
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
@property (nonatomic, readonly) BOOL anonymous;
@property (nonatomic, readonly) NSSet* allNames; // lowercase names/aliases

@property (nonatomic, readonly) ISSPropertyType type;
@property (nonatomic, readonly) NSString* typeDescription;
@property (nonatomic, readonly) NSString* uniqueTypeDescription;
@property (nonatomic, readonly) NSDictionary* parameterEnumValues;
@property (nonatomic, readonly) NSDictionary* enumValues;
@property (nonatomic, readonly) BOOL enumBitMaskType;

@property (nonatomic, readonly) BOOL isParameterizedProperty;

@property (nonatomic, readonly) NSString* displayDescription;

- (void) setValue:(id)value onTarget:(id)target andParameters:(NSArray*)params withPrefixKeyPath:(NSString*)prefixKeyPath;

- (id) initAnonymousPropertyDefinitionWithType:(ISSPropertyType)type;

@end
