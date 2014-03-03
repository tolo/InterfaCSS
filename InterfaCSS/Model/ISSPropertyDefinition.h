//
//  ISSPropertyDefinition.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

typedef NS_ENUM(NSInteger, ISStyleSheetPropertyType) {
    ISStyleSheetPropertyTypeString,
    ISStyleSheetPropertyTypeBool,
    ISStyleSheetPropertyTypeNumber,
    ISStyleSheetPropertyTypeOffset,
    ISStyleSheetPropertyTypeRect,
    ISStyleSheetPropertyTypeSize,
    ISStyleSheetPropertyTypePoint,
    ISStyleSheetPropertyTypeEdgeInsets,
    ISStyleSheetPropertyTypeColor,
    ISStyleSheetPropertyTypeCGColor,
    ISStyleSheetPropertyTypeTransform,
    ISStyleSheetPropertyTypeFont,
    ISStyleSheetPropertyTypeImage,
    ISStyleSheetPropertyTypeEnumType,
};

@interface ISSPropertyDefinition : NSObject

@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) NSArray* allNames;

@property (nonatomic, readonly) ISStyleSheetPropertyType type;
@property (nonatomic, readonly) NSDictionary* parameterEnumValues;
@property (nonatomic, readonly) NSDictionary* enumValues;
@property (nonatomic, readonly) BOOL enumBitMaskType;

@property (nonatomic, readonly) BOOL isParameterizedProperty;

@property (nonatomic, readonly) NSString* displayDescription;

- (void) setValue:(id)value onTarget:(id)target withPrefixKeyPath:(NSString*)prefixKeyPath;
- (void) setValue:(id)value onTarget:(id)target andParameters:(NSArray*)params withPrefixKeyPath:(NSString*)prefixKeyPath;

+ (NSSet*) propertyDefinitions;
+ (NSSet*) propertyDefinitionsForType:(ISStyleSheetPropertyType)propertyType;
+ (NSSet*) propertyDefinitionsForViewClass:(Class)viewClass;
+ (NSString*) typeForViewClass:(Class)viewClass;

#if DEBUG == 1
+ (NSString*) propertyDescriptionsForMarkdown;
#endif

@end
