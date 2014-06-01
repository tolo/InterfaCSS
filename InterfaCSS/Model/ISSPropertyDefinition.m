//
//  ISSPropertyDefinition.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <objc/runtime.h>
#import "ISSStyleSheetParser.h"

#import "NSObject+ISSLogSupport.h"
#import "NSString+ISSStringAdditions.h"
#import "ISSRectValue.h"
#import "ISSPointValue.h"
#import "ISSLazyValue.h"
#import "NSDictionary+ISSDictionaryAdditions.h"


@protocol NSValueTransformer
- (NSValue*) transformToNSValue;
@end


typedef void (^EnumValuesBlock)(ISSPropertyDefinition*);
typedef void (^PropertySetterBlock)(ISSPropertyDefinition* property, id viewObject, id value, NSArray* parameters);


NSString* const ISSAnonymousPropertyDefinitionName = @"ISSAnonymousPropertyDefinition";


#define S(selName) NSStringFromSelector(@selector(selName))

static NSDictionary* classesToTypeNames;
static NSDictionary* typeNamesToClasses;

static NSDictionary* classProperties;
static NSSet* allProperties;
static NSSet* validPrefixKeyPaths;



@interface ISSPropertyDefinition ()

@property (nonatomic, strong) NSDictionary* enumValues;
@property (nonatomic, copy) PropertySetterBlock propertySetterBlock;

- (id) initWithName:(NSString *)name type:(ISSPropertyType)type;
- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISSPropertyType)type;
- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISSPropertyType)type enumBlock:(NSDictionary*)enumValues enumBitMaskType:(BOOL)enumBitMaskType;
- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISSPropertyType)type enumValues:(NSDictionary*)enumValues
          enumBitMaskType:(BOOL)enumBitMaskType setterBlock:(void (^)(ISSPropertyDefinition*, id, id, NSArray*))setterBlock parameterEnumValues:(NSDictionary*)parameterEnumValues;

@end



static ISSPropertyDefinition* p(NSString* name, ISSPropertyType type) {
    return [[ISSPropertyDefinition alloc] initWithName:name type:type];
}

static ISSPropertyDefinition* ps(NSString* name, ISSPropertyType type, PropertySetterBlock setterBlock) {
    return [[ISSPropertyDefinition alloc] initWithName:name aliases:nil type:type enumValues:nil
                                          enumBitMaskType:NO setterBlock:setterBlock parameterEnumValues:nil];
}

static ISSPropertyDefinition* pa(NSString* name, NSArray* aliases, ISSPropertyType type) {
    return [[ISSPropertyDefinition alloc] initWithName:name aliases:aliases type:type];
}

static ISSPropertyDefinition* pe(NSString* name, NSDictionary* enumValues) {
    return [[ISSPropertyDefinition alloc] initWithName:name aliases:nil type:ISSPropertyTypeEnumType enumBlock:enumValues enumBitMaskType:NO];
}

static ISSPropertyDefinition* pea(NSString* name, NSArray* aliases, NSDictionary* enumValues) {
    return [[ISSPropertyDefinition alloc] initWithName:name aliases:aliases type:ISSPropertyTypeEnumType enumBlock:enumValues enumBitMaskType:NO];
}

static ISSPropertyDefinition* peo(NSString* name, NSDictionary* enumValues) {
    return [[ISSPropertyDefinition alloc] initWithName:name aliases:nil type:ISSPropertyTypeEnumType enumValues:enumValues enumBitMaskType:YES setterBlock:nil parameterEnumValues:nil];
}

static ISSPropertyDefinition* pp(NSString* name, NSDictionary* paramValues, ISSPropertyType type, PropertySetterBlock setterBlock) {
    return [[ISSPropertyDefinition alloc] initWithName:name aliases:nil type:type enumValues:nil
                                      enumBitMaskType:NO setterBlock:setterBlock parameterEnumValues:paramValues];
}

static void setTitleTextAttributes(id viewObject, id value, NSArray* parameters, NSString* attrName) {
    UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
    NSMutableDictionary* attrs = nil;
    if( [viewObject respondsToSelector:@selector(scopeBarButtonTitleTextAttributesForState:)] ) attrs = [NSMutableDictionary dictionaryWithDictionary:[viewObject scopeBarButtonTitleTextAttributesForState:state]];
    else if( [viewObject respondsToSelector:@selector(titleTextAttributesForState:)] ) attrs = [NSMutableDictionary dictionaryWithDictionary:[viewObject titleTextAttributesForState:state]];
    else if( [viewObject respondsToSelector:@selector(titleTextAttributes)] ) attrs = [NSMutableDictionary dictionaryWithDictionary:[viewObject titleTextAttributes]];

    attrs[attrName] = value;
    if( [viewObject isKindOfClass:UISearchBar.class] ) [viewObject setScopeBarButtonTitleTextAttributes:attrs forState:state];
    else if( [viewObject respondsToSelector:@selector(setTitleTextAttributes:forState:)] ) [viewObject setTitleTextAttributes:attrs forState:state];
    else if( [viewObject respondsToSelector:@selector(setTitleTextAttributes:)] ) [viewObject setTitleTextAttributes:attrs];
}


@implementation ISSPropertyDefinition

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

        _allNames = @[name];
        if( aliases ) _allNames = [_allNames arrayByAddingObjectsFromArray:aliases];

        _type = type;
        _enumValues = [enumValues iss_dictionaryWithLowerCaseKeys];
        _enumBitMaskType = enumBitMaskType;

        _propertySetterBlock = setterBlock;
        _parameterEnumValues = [parameterEnumValues iss_dictionaryWithLowerCaseKeys];
    }
    return self;
}

- (BOOL) anonymous {
    return self.name == ISSAnonymousPropertyDefinitionName;
}

- (id) targetObjectForObject:(id)obj andPrefixKeyPath:(NSString*)prefixKeyPath {
    if( prefixKeyPath ) {
        // First, check if prefix key path is a valid selector
        if( [obj respondsToSelector:NSSelectorFromString(prefixKeyPath)] ) {
            return [obj valueForKeyPath:prefixKeyPath];
        } else {
            // Then attempt to match prefix key path against known prefix key paths, and make sure correct name is used
            for(NSString* validPrefix in validPrefixKeyPaths) {
                if( [validPrefix iss_isEqualIgnoreCase:prefixKeyPath] && [obj respondsToSelector:NSSelectorFromString(validPrefix)] ) {
                    return [obj valueForKeyPath:validPrefix];
                }
            }

            ISSLogDebug(@"Unable to find prefix key path '%@' in %@", prefixKeyPath, obj);
        }
    }
    return obj;
}

- (void) setValueUsingKVC:(id)value onTarget:(id)obj withPrefixKeyPath:(NSString*)prefixKeyPath {
    @try {
        NSString* propertyName = _name;
        NSArray* dotSeparatedComponents = [propertyName componentsSeparatedByString:@"."];
        if( dotSeparatedComponents.count > 1 ) { // For instance layer.cornerRadius...
            if( ![prefixKeyPath iss_hasData] ) prefixKeyPath = dotSeparatedComponents[0];
            propertyName = dotSeparatedComponents[1];
        }

        obj = [self targetObjectForObject:obj andPrefixKeyPath:prefixKeyPath];
        
        if( [value isKindOfClass:ISSLazyValue.class] ) value = [value evaluateWithParameter:obj];
        if( [value respondsToSelector:@selector(transformToNSValue)] ) value = [value transformToNSValue];
        [obj setValue:value forKeyPath:propertyName]; // Will throw exception if property doesn't exist
    } @catch (NSException* e) {
        ISSLogDebug(@"Unable to set value for property %@ - %@", _name, e);
    }
}


#pragma mark - Public interface

- (void) setValue:(id)value onTarget:(id)obj withPrefixKeyPath:(NSString*)prefixKeyPath {
    if( value && value != [NSNull null] ) {
        if( _propertySetterBlock ) {
            [self setValue:value onTarget:obj andParameters:nil withPrefixKeyPath:prefixKeyPath];
        } else {
            [self setValueUsingKVC:value onTarget:obj withPrefixKeyPath:prefixKeyPath];
        }
    }
}

- (void) setValue:(id)value onTarget:(id)obj andParameters:(NSArray*)params withPrefixKeyPath:(NSString*)prefixKeyPath {
    obj = [self targetObjectForObject:obj andPrefixKeyPath:prefixKeyPath];
    if( [value isKindOfClass:ISSLazyValue.class] ) value = [value evaluateWithParameter:obj];
    if( value && value != [NSNull null] ) _propertySetterBlock(self, obj, value, params);
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


#pragma mark - Property definition methods


+ (NSSet*) propertyDefinitions {
    return allProperties;
}

+ (NSSet*) propertyDefinitionsForType:(ISSPropertyType)propertyType {
    return [allProperties filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary* bindings) {
        return ((ISSPropertyDefinition*)evaluatedObject).type == propertyType;
    }]];
}

+ (NSSet*) propertyDefinitionsForViewClass:(Class)viewClass {
    NSMutableSet* viewClassProperties = [[NSMutableSet alloc] init];
    for(Class clazz in classProperties.allKeys) {
        if( [viewClass isSubclassOfClass:clazz] ) {
            [viewClassProperties unionSet:classProperties[clazz]];
        }
    }
    return viewClassProperties;
}

+ (NSString*) canonicalTypeForViewClass:(Class)viewClass {
    NSString* type = classesToTypeNames[viewClass];
    if( type ) return type;
    else { // Custom view class or "unsupported" UIKit view class
        Class superClass = [viewClass superclass];
        if( superClass && superClass != NSObject.class ) return [self canonicalTypeForViewClass:superClass];
        else return nil;
    }
}

+ (Class) canonicalTypeClassForViewClass:(Class)viewClass {
    if( classesToTypeNames[viewClass] ) return viewClass;
    else { // Custom view class or "unsupported" UIKit view class
        Class superClass = [viewClass superclass];
        if( superClass && superClass != NSObject.class ) return [self canonicalTypeClassForViewClass:superClass];
        else return nil;
    }
}

+ (Class) canonicalTypeClassForType:(NSString*)type {
    return typeNamesToClasses[[type lowercaseString]];
}

#if DEBUG == 1
+ (NSString*) propertyDescriptionsForMarkdown {
    NSMutableString* string = [NSMutableString string];

    NSMutableArray* classes = [[NSMutableArray alloc] init];
    for(Class clazz in classProperties.allKeys) {
        if( clazz != UIView.class ) [classes addObject:clazz];
    }
    [classes sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 description] compare:[obj2 description]];
    }];
    [classes insertObject:[UIView class] atIndex:0];

    for(Class clazz in classes) {
        [string appendFormat:@"\n###%@ \n", [clazz description]];

        NSArray* properties = [classProperties[clazz] allObjects];

        [string appendString:@"Class | Type | Enum values | Parameter values \n"];
        [string appendString:@"--- | --- | --- | ---\n"];

        properties = [properties sortedArrayUsingSelector:@selector(compareByName:)];
        for(ISSPropertyDefinition* def in properties) {
            [string appendFormat:@"%@ | [`%@`](#%@) | %@ | %@\n", def.name, def.typeDescription, def.typeDescription,
                            def.enumValues.count ? [def.enumValues.allKeys componentsJoinedByString:@", "] : @"",
                            def.parameterEnumValues.count ? [def.parameterEnumValues.allKeys componentsJoinedByString:@", "] : @""];
        }
    }
    return string;
}
#endif

#pragma mark - Class initialization - setup of property definitions


+ (void) initialize {
    validPrefixKeyPaths = [NSSet setWithArray:@[S(imageView), S(contentView), S(backgroundView), S(selectedBackgroundView),
                S(multipleSelectionBackgroundView), S(titleLabel), S(textLabel), S(detailTextLabel), S(inputView), S(inputAccessoryView),
                S(tableHeaderView), S(tableFooterView), S(backgroundView)]];

    NSDictionary* controlStateParametersValues = @{@"normal" : @(UIControlStateNormal), @"normalHighlighted" : @(UIControlStateNormal | UIControlStateHighlighted),
            @"highlighted" : @(UIControlStateNormal | UIControlStateHighlighted),
            @"selected" : @(UIControlStateSelected), @"selectedHighlighted" : @(UIControlStateSelected | UIControlStateHighlighted), @"disabled" : @(UIControlStateDisabled)};

    NSDictionary* barMetricsParameters = @{@"metricsDefault" : @(UIBarMetricsDefault), @"metricsLandscapePhone" : @(UIBarMetricsLandscapePhone),
                @"metricsLandscapePhonePrompt" : @(UIBarMetricsLandscapePhonePrompt), @"metricsDefaultPrompt" : @(UIBarMetricsDefaultPrompt)};

    NSMutableDictionary* barMetricsAndControlStateParameters = [NSMutableDictionary dictionaryWithDictionary:barMetricsParameters];
    [barMetricsAndControlStateParameters addEntriesFromDictionary:controlStateParametersValues];

    NSMutableDictionary* barMetricsSegmentAndControlStateParameters = [NSMutableDictionary dictionaryWithDictionary:
            @{@"segmentAny" : @(UISegmentedControlSegmentAny), @"segmentLeft" : @(UISegmentedControlSegmentLeft), @"segmentCenter" : @(UISegmentedControlSegmentCenter),
              @"segmentRight" : @(UISegmentedControlSegmentRight), @"segmentAlone" : @(UISegmentedControlSegmentAlone)
            }];
    [barMetricsSegmentAndControlStateParameters addEntriesFromDictionary:barMetricsAndControlStateParameters];

    NSDictionary* barPositionParameters = @{@"barPositionAny" : @(UIBarPositionAny), @"barPositionBottom" : @(UIBarPositionBottom),
                    @"barPositionTop" : @(UIBarPositionTop), @"barPositionTopAttached" : @(UIBarPositionTopAttached)};

    NSMutableDictionary* barMetricsPositionAndControlStateParameters = [NSMutableDictionary dictionaryWithDictionary:barMetricsAndControlStateParameters];
    [barMetricsPositionAndControlStateParameters addEntriesFromDictionary:barPositionParameters];


    // Common properties:

    ISSPropertyDefinition* backgroundImage = pp(S(backgroundImage), barMetricsPositionAndControlStateParameters, ISSPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
        UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
        UIBarPosition position = parameters.count > 0 ? (UIBarPosition)[parameters[0] unsignedIntegerValue] : UIBarPositionAny;
        UIBarMetrics metrics = parameters.count > 1 ? (UIBarMetrics)[parameters[1] integerValue] : UIBarMetricsDefault;

        if( [viewObject respondsToSelector:@selector(setBackgroundImage:forBarPosition:barMetrics:)] ) {
            [viewObject setBackgroundImage:value forBarPosition:position barMetrics:metrics];
        } else if( [viewObject respondsToSelector:@selector(setBackgroundImage:forState:barMetrics:)] ) {
            [viewObject setBackgroundImage:value forState:state barMetrics:metrics];
        } else if( [viewObject respondsToSelector:@selector(setBackgroundImage:forState:)] ) {
            [viewObject setBackgroundImage:value forState:state];
        } else if( [viewObject respondsToSelector:@selector(setBackgroundImage:forToolbarPosition:barMetrics:)] ) {
            [viewObject setBackgroundImage:value forToolbarPosition:position barMetrics:metrics];
        } else if( [viewObject respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)] ) {
            [viewObject setBackgroundImage:value forBarMetrics:metrics];
        } else if( [viewObject respondsToSelector:@selector(setBackgroundImage:)] ) {
            [viewObject setBackgroundImage:value];
        }
    });

    ISSPropertyDefinition* image = pp(S(image), controlStateParametersValues, ISSPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
        UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
        if( [viewObject respondsToSelector:@selector(setImage:forState:)] ) {
            [viewObject setImage:value forState:state];
        } if( [viewObject respondsToSelector:@selector(setImage:)] ) {
            [viewObject setImage:value];
        }
    });

    ISSPropertyDefinition* shadowImage = pp(S(shadowImage), barPositionParameters, ISSPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
        if( [viewObject respondsToSelector:@selector(setShadowImage:forToolbarPosition:)] ) {
            UIBarPosition position = parameters.count > 0 ? (UIBarPosition) [parameters[0] unsignedIntegerValue] : UIBarPositionAny;
            [viewObject setShadowImage:value forToolbarPosition:position];
        } else if( [viewObject respondsToSelector:@selector(setShadowImage:)] ) {
            [viewObject setShadowImage:value];
        }
    });

    ISSPropertyDefinition* title = pp(S(title), controlStateParametersValues, ISSPropertyTypeString, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
        UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
        if( [viewObject respondsToSelector:@selector(setBackgroundImage:forState:)] ) {
            [viewObject setTitle:value forState:state];
        } else if( [viewObject respondsToSelector:@selector(setTitle:)] ) {
            [viewObject setTitle:value];
        }
    });

    ISSPropertyDefinition* font = pp(S(font), controlStateParametersValues, ISSPropertyTypeFont, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
        if( [viewObject respondsToSelector:@selector(setFont:)] ) {
            [viewObject setFont:value];
        } else {
            setTitleTextAttributes(viewObject, value, parameters, UITextAttributeFont);
        }
    });

    ISSPropertyDefinition* textColor = pp(S(textColor), controlStateParametersValues, ISSPropertyTypeColor, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
        if( [viewObject respondsToSelector:@selector(setTextColor:)] ) {
            [viewObject setTextColor:value];
        } else {
            setTitleTextAttributes(viewObject, value, parameters, UITextAttributeTextColor);
        }
    });

    ISSPropertyDefinition* shadowColor = pp(S(shadowColor), controlStateParametersValues, ISSPropertyTypeColor, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
        if( [viewObject respondsToSelector:@selector(setShadowColor:)] ) {
            [viewObject setShadowColor:value];
        } else {
            setTitleTextAttributes(viewObject, value, parameters, UITextAttributeTextShadowColor);
        }
    });

    ISSPropertyDefinition* shadowOffset = pp(S(shadowOffset), controlStateParametersValues, ISSPropertyTypeOffset, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
        if( [viewObject respondsToSelector:@selector(setShadowOffset:)] ) {
            [viewObject setShadowOffset:[value CGSizeValue]];
        } else {
            setTitleTextAttributes(viewObject, value, parameters, UITextAttributeTextShadowOffset);
        }
    });

    ISSPropertyDefinition* barTintColor = p(S(barTintColor), ISSPropertyTypeColor);

    ISSPropertyDefinition* barStyle = pe(S(barStyle), @{@"default" : @(UIBarStyleDefault), @"black" : @(UIBarStyleBlack), @"blackOpaque" : @(UIBarStyleBlackOpaque), @"blackTranslucent" : @(UIBarStyleBlackTranslucent)});

    ISSPropertyDefinition* translucent = p(@"translucent", ISSPropertyTypeBool);

    ISSPropertyDefinition* titlePositionAdjustment = pp(S(titlePositionAdjustment), barMetricsParameters, ISSPropertyTypeOffset, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
        if( [viewObject respondsToSelector:@selector(setTitlePositionAdjustment:forBarMetrics:)] ) {
            UIBarMetrics metrics = parameters.count > 0 ? (UIBarMetrics) [parameters[0] integerValue] : UIBarMetricsDefault;
            [viewObject setTitlePositionAdjustment:[value UIOffsetValue] forBarMetrics:metrics];
        } else if( [viewObject respondsToSelector:@selector(setTitlePositionAdjustment:)] ) {
            [viewObject setTitlePositionAdjustment:[value UIOffsetValue]];
        }
    });

    ISSPropertyDefinition* allowsSelection = p(S(allowsSelection), ISSPropertyTypeBool);

    ISSPropertyDefinition* allowsMultipleSelection = p(S(allowsMultipleSelection), ISSPropertyTypeBool);


    NSSet* viewProperties = [NSSet setWithArray:@[
            p(S(alpha), ISSPropertyTypeNumber),
            p(S(autoresizesSubviews), ISSPropertyTypeBool),
            peo(S(autoresizingMask), @{ @"none" : @(UIViewAutoresizingNone), @"width" : @(UIViewAutoresizingFlexibleWidth), @"height" : @(UIViewAutoresizingFlexibleHeight),
                                    @"bottom" : @(UIViewAutoresizingFlexibleBottomMargin), @"top" : @(UIViewAutoresizingFlexibleTopMargin),
                                    @"left" : @(UIViewAutoresizingFlexibleLeftMargin), @"right" : @(UIViewAutoresizingFlexibleRightMargin)}
            ),
            p(S(backgroundColor), ISSPropertyTypeColor),
            ps(S(bounds), ISSPropertyTypeRect, ^(ISSPropertyDefinition* property, id viewObject, id value, NSArray* parameters) {
                if( [viewObject isKindOfClass:UIView.class] ) {
                    UIView* v = viewObject;
                    v.bounds = [value rectForView:v];
                }
            }),
            ps(S(center), ISSPropertyTypePoint, ^(ISSPropertyDefinition* property, id viewObject, id value, NSArray* parameters) {
                if( [viewObject isKindOfClass:UIView.class] ) {
                    UIView* v = viewObject;
                    // Handle case when attempting to set frame on transformed view
                    CGAffineTransform t = v.transform;
                    v.transform = CGAffineTransformIdentity;
                    v.center = [value pointForView:v];
                    v.transform = t;
                }
            }),
            p(S(clearsContextBeforeDrawing), ISSPropertyTypeBool),
            p(S(clipsToBounds), ISSPropertyTypeBool),
            pe(S(contentMode), @{@"scaleToFill" : @(UIViewContentModeScaleToFill), @"scaleAspectFit" : @(UIViewContentModeScaleAspectFit),
                        @"scaleAspectFill" : @(UIViewContentModeScaleAspectFill), @"redraw" : @(UIViewContentModeRedraw), @"center" : @(UIViewContentModeCenter), @"top" : @(UIViewContentModeTop),
                        @"bottom" : @(UIViewContentModeBottom), @"left" : @(UIViewContentModeLeft), @"right" : @(UIViewContentModeRight), @"topLeft" : @(UIViewContentModeTopLeft),
                        @"topRight" : @(UIViewContentModeTopRight), @"bottomLeft" : @(UIViewContentModeBottomLeft), @"bottomRight" : @(UIViewContentModeBottomRight)}
            ),
            p(S(contentScaleFactor), ISSPropertyTypeNumber),
            p(@"exclusiveTouch", ISSPropertyTypeBool),
            ps(S(frame), ISSPropertyTypeRect, ^(ISSPropertyDefinition* property, id viewObject, id value, NSArray* parameters) {
                if( [viewObject isKindOfClass:UIView.class] ) {
                    UIView* v = viewObject;
                    // Handle case when attempting to set frame on transformed view
                    CGAffineTransform t = v.transform;
                    v.transform = CGAffineTransformIdentity;
                    v.frame = [value rectForView:v];
                    v.transform = t;
                }
            }),
            p(@"hidden", ISSPropertyTypeBool),
            pa(@"layer.anchorPoint", @[@"anchorPoint"], ISSPropertyTypePoint),
            pa(@"layer.cornerRadius", @[@"cornerradius"], ISSPropertyTypeNumber),
            pa(@"layer.borderColor", @[@"bordercolor"], ISSPropertyTypeCGColor),
            pa(@"layer.borderWidth", @[@"borderwidth"], ISSPropertyTypeNumber),
            p(@"multipleTouchEnabled", ISSPropertyTypeBool),
            p(@"opaque", ISSPropertyTypeBool),
            p(S(tintColor), ISSPropertyTypeColor),
            pe(S(tintAdjustmentMode), @{@"automatic" : @(UIViewTintAdjustmentModeAutomatic), @"normal" : @(UIViewTintAdjustmentModeNormal), @"dimmed" : @(UIViewTintAdjustmentModeDimmed)}),
            p(S(transform), ISSPropertyTypeTransform),
            p(@"userInteractionEnabled", ISSPropertyTypeBool),
    ]];
    allProperties = viewProperties;


    NSSet* controlProperties = [NSSet setWithArray:@[
            p(@"enabled", ISSPropertyTypeBool),
            p(@"highlighted", ISSPropertyTypeBool),
            p(@"selected", ISSPropertyTypeBool),
            pe(S(contentVerticalAlignment), @{@"center" : @(UIControlContentVerticalAlignmentCenter), @"top" : @(UIControlContentVerticalAlignmentTop),
                    @"bottom" : @(UIControlContentVerticalAlignmentBottom), @"fill" : @(UIControlContentVerticalAlignmentFill)}),
            pe(S(contentHorizontalAlignment), @{@"center" : @(UIControlContentHorizontalAlignmentCenter), @"left" : @(UIControlContentHorizontalAlignmentLeft),
                    @"right" : @(UIControlContentHorizontalAlignmentRight), @"fill" : @(UIControlContentHorizontalAlignmentFill)})
    ]];
    allProperties = [allProperties setByAddingObjectsFromSet:controlProperties];


    NSSet* scrollViewProperties = [NSSet setWithArray:@[
            p(S(contentOffset), ISSPropertyTypePoint),
            p(S(contentSize), ISSPropertyTypeSize),
            p(S(contentInset), ISSPropertyTypeEdgeInsets),
            p(@"directionalLockEnabled", ISSPropertyTypeBool),
            p(S(bounces), ISSPropertyTypeBool),
            p(S(alwaysBounceVertical), ISSPropertyTypeBool),
            p(S(alwaysBounceHorizontal), ISSPropertyTypeBool),
            p(@"pagingEnabled", ISSPropertyTypeBool),
            p(@"scrollEnabled", ISSPropertyTypeBool),
            p(S(showsHorizontalScrollIndicator), ISSPropertyTypeBool),
            p(S(showsVerticalScrollIndicator), ISSPropertyTypeBool),
            p(S(scrollIndicatorInsets), ISSPropertyTypeEdgeInsets),
            pe(S(indicatorStyle), @{@"default" : @(UIScrollViewIndicatorStyleDefault), @"black" : @(UIScrollViewIndicatorStyleBlack), @"white" : @(UIScrollViewIndicatorStyleWhite)}),
            pe(S(decelerationRate), @{@"normal" : @(UIScrollViewDecelerationRateNormal), @"fast" : @(UIScrollViewDecelerationRateFast)}),
            p(S(delaysContentTouches), ISSPropertyTypeBool),
            p(S(canCancelContentTouches), ISSPropertyTypeBool),
            p(S(minimumZoomScale), ISSPropertyTypeNumber),
            p(S(maximumZoomScale), ISSPropertyTypeNumber),
            p(S(bouncesZoom), ISSPropertyTypeBool),
            p(S(scrollsToTop), ISSPropertyTypeBool),
            pe(S(keyboardDismissMode), @{@"none" : @(UIScrollViewKeyboardDismissModeNone), @"onDrag" : @(UIScrollViewKeyboardDismissModeOnDrag), @"interactive" : @(UIScrollViewKeyboardDismissModeInteractive)})
    ]];
    allProperties = [allProperties setByAddingObjectsFromSet:scrollViewProperties];

    NSSet* tableViewProperties = [NSSet setWithArray:@[
            p(S(rowHeight), ISSPropertyTypeNumber),
            p(S(sectionHeaderHeight), ISSPropertyTypeNumber),
            p(S(sectionFooterHeight), ISSPropertyTypeNumber),
            p(S(estimatedRowHeight), ISSPropertyTypeNumber),
            p(S(estimatedSectionHeaderHeight), ISSPropertyTypeNumber),
            p(S(estimatedSectionFooterHeight), ISSPropertyTypeNumber),
            p(S(separatorInset), ISSPropertyTypeEdgeInsets),
            allowsSelection,
            p(S(allowsSelectionDuringEditing), ISSPropertyTypeBool),
            allowsMultipleSelection,
            p(S(allowsMultipleSelectionDuringEditing), ISSPropertyTypeBool),
            p(S(sectionIndexMinimumDisplayRowCount), ISSPropertyTypeNumber),
            p(S(sectionIndexColor), ISSPropertyTypeColor),
            p(S(sectionIndexBackgroundColor), ISSPropertyTypeColor),
            p(S(sectionIndexTrackingBackgroundColor), ISSPropertyTypeColor),
            pe(S(separatorStyle), @{@"none" : @(UITableViewCellSeparatorStyleNone), @"singleLine" : @(UITableViewCellSeparatorStyleSingleLine), @"singleLineEtched" : @(UITableViewCellSeparatorStyleSingleLineEtched)}),
            p(S(separatorColor), ISSPropertyTypeColor)
    ]];
    allProperties = [allProperties setByAddingObjectsFromSet:tableViewProperties];


    NSDictionary* dataDetectorTypesValues = @{@"all" : @(UIDataDetectorTypeAll), @"none" : @(UIDataDetectorTypeNone), @"address" : @(UIDataDetectorTypeAddress),
                        @"calendarEvent" : @(UIDataDetectorTypeCalendarEvent), @"link" : @(UIDataDetectorTypeLink), @"phoneNumber" : @(UIDataDetectorTypePhoneNumber)};

    NSSet* webViewProperties = [NSSet setWithArray:@[
            p(S(scalesPageToFit), ISSPropertyTypeBool),
            pe(S(dataDetectorTypes), dataDetectorTypesValues),
            p(S(allowsInlineMediaPlayback), ISSPropertyTypeBool),
            p(S(mediaPlaybackRequiresUserAction), ISSPropertyTypeBool),
            p(S(mediaPlaybackAllowsAirPlay), ISSPropertyTypeBool),
            p(S(suppressesIncrementalRendering), ISSPropertyTypeBool),
            p(S(keyboardDisplayRequiresUserAction), ISSPropertyTypeBool),
            pe(S(paginationMode), @{@"unpaginated" : @(UIWebPaginationModeUnpaginated), @"lefttoright" : @(UIWebPaginationModeLeftToRight),
                    @"toptobottom" : @(UIWebPaginationModeTopToBottom), @"bottomtotop" : @(UIWebPaginationModeBottomToTop), @"righttoleft" : @(UIWebPaginationModeRightToLeft)}),
            pe(S(paginationBreakingMode), @{@"page" : @(UIWebPaginationBreakingModePage), @"column" : @(UIWebPaginationBreakingModeColumn)}),
            p(S(pageLength), ISSPropertyTypeNumber),
            p(S(gapBetweenPages), ISSPropertyTypeNumber),
    ]];
    allProperties = [allProperties setByAddingObjectsFromSet:webViewProperties];


    NSSet* collectionViewProperties = [NSSet setWithArray:@[
            allowsSelection,
            allowsMultipleSelection
    ]];
    allProperties = [allProperties setByAddingObjectsFromSet:collectionViewProperties];


    NSSet* activityIndicatorProperties = [NSSet setWithArray:@[
            pe(S(activityIndicatorViewStyle), @{@"gray" : @(UIActivityIndicatorViewStyleGray), @"white" : @(UIActivityIndicatorViewStyleWhite), @"whiteLarge" : @(UIActivityIndicatorViewStyleWhiteLarge)}),
            p(S(color), ISSPropertyTypeColor),
            p(S(hidesWhenStopped), ISSPropertyTypeBool)
    ]];
    allProperties = [allProperties setByAddingObjectsFromSet:activityIndicatorProperties];


    NSSet* buttonProperties = [NSSet setWithArray:@[
            p(S(showsTouchWhenHighlighted), ISSPropertyTypeBool),
            p(S(adjustsImageWhenHighlighted), ISSPropertyTypeBool),
            p(S(adjustsImageWhenDisabled), ISSPropertyTypeBool),
            p(S(contentEdgeInsets), ISSPropertyTypeEdgeInsets),
            p(S(titleEdgeInsets), ISSPropertyTypeEdgeInsets),
            p(S(imageEdgeInsets), ISSPropertyTypeEdgeInsets),
            p(S(reversesTitleShadowWhenHighlighted), ISSPropertyTypeBool),
            title,
            pp(@"titleColor", controlStateParametersValues, ISSPropertyTypeColor, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setTitleColor:forState:)] ) [viewObject setTitleColor:value forState:state];
            }),
            pp(@"titleShadowColor", controlStateParametersValues, ISSPropertyTypeColor, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setTitleShadowColor:forState:)] ) [viewObject setTitleShadowColor:value forState:state];
            }),
            image,
            backgroundImage
    ]];
    allProperties = [allProperties setByAddingObjectsFromSet:buttonProperties];


    NSSet* textProperties = [NSSet setWithArray:@[
            font,
            textColor,
            pea(S(textAlignment), @[@"textalign"], @{@"left" : @(NSTextAlignmentLeft), @"center" : @(NSTextAlignmentCenter), @"right" : @(NSTextAlignmentRight)})
    ]];

    NSSet* resizableTextProperties = [NSSet setWithArray:@[
            p(S(adjustsFontSizeToFitWidth), ISSPropertyTypeBool),
            p(S(minimumFontSize), ISSPropertyTypeNumber),
            p(S(minimumScaleFactor), ISSPropertyTypeNumber)
    ]];

    NSSet* labelProperties = [NSSet setWithArray:@[
            pe(S(baselineAdjustment), @{@"none" : @(UIBaselineAdjustmentNone), @"alignBaselines" : @(UIBaselineAdjustmentAlignBaselines),
                    @"alignCenters" : @(UIBaselineAdjustmentAlignCenters)}
            ),
            pe(S(lineBreakMode), @{@"wordWrap" : @(NSLineBreakByWordWrapping), @"charWrap" : @(NSLineBreakByCharWrapping),
                    @"clip" : @(NSLineBreakByClipping), @"truncateHead" : @(NSLineBreakByTruncatingHead), @"truncateTail" : @(NSLineBreakByTruncatingTail),
                    @"truncateMiddle" : @(NSLineBreakByTruncatingMiddle)}
            ),
            p(S(numberOfLines), ISSPropertyTypeNumber),
            p(S(preferredMaxLayoutWidth), ISSPropertyTypeNumber),
            shadowOffset,
            p(S(highlightedTextColor), ISSPropertyTypeColor),
            shadowColor,
            p(S(text), ISSPropertyTypeString)
    ]];
    labelProperties = [labelProperties setByAddingObjectsFromSet:textProperties];
    labelProperties = [labelProperties setByAddingObjectsFromSet:resizableTextProperties];
    allProperties = [allProperties setByAddingObjectsFromSet:labelProperties];


    NSSet* progressViewProperties = [NSSet setWithArray:@[
            p(S(progressTintColor), ISSPropertyTypeColor),
            p(S(progressImage), ISSPropertyTypeImage),
            pe(S(progressViewStyle), @{@"default" : @(UIProgressViewStyleDefault), @"bar" : @(UIProgressViewStyleBar)}),
            p(S(trackTintColor), ISSPropertyTypeColor),
            p(S(trackImage), ISSPropertyTypeImage),
    ]];
    allProperties = [allProperties setByAddingObjectsFromSet:progressViewProperties];


    NSSet* minimalTextInputProperties = [NSSet setWithArray:@[
            p(S(autocapitalizationType), ISSPropertyTypeBool),
            pe(S(autocorrectionType), @{@"default" : @(UITextAutocorrectionTypeDefault), @"no" : @(UITextAutocorrectionTypeNo), @"yes" : @(UITextAutocorrectionTypeYes)}),
            pe(S(spellCheckingType), @{@"default" : @(UITextSpellCheckingTypeDefault), @"no" : @(UITextSpellCheckingTypeNo), @"yes" : @(UITextSpellCheckingTypeYes)}),
            pe(S(keyboardType), @{@"default" : @(UIKeyboardTypeDefault), @"alphabet" : @(UIKeyboardTypeAlphabet), @"asciiCapable" : @(UIKeyboardTypeASCIICapable),
                    @"decimalPad" : @(UIKeyboardTypeDecimalPad), @"emailAddress" : @(UIKeyboardTypeEmailAddress), @"namePhonePad" : @(UIKeyboardTypeNamePhonePad),
                    @"numberPad" : @(UIKeyboardTypeNumberPad), @"numbersAndPunctuation" : @(UIKeyboardTypeNumbersAndPunctuation), @"phonePad" : @(UIKeyboardTypePhonePad),
                    @"twitter" : @(UIKeyboardTypeTwitter), @"URL" : @(UIKeyboardTypeURL), @"webSearch" : @(UIKeyboardTypeWebSearch)})
            ]];

    NSSet* textInputProperties = [NSSet setWithArray:@[
            p(S(enablesReturnKeyAutomatically), ISSPropertyTypeBool),
            pe(S(keyboardAppearance), @{@"default" : @(UIKeyboardAppearanceDefault), @"alert" : @(UIKeyboardAppearanceAlert),
                    @"dark" : @(UIKeyboardAppearanceDark), @"light" : @(UIKeyboardAppearanceLight)}),

            pe(S(returnKeyType), @{@"default" : @(UIReturnKeyDefault), @"go" : @(UIReturnKeyGo), @"google" : @(UIReturnKeyGoogle), @"join" : @(UIReturnKeyJoin),
                                                    @"next" : @(UIReturnKeyNext), @"route" : @(UIReturnKeyRoute), @"search" : @(UIReturnKeySearch), @"send" : @(UIReturnKeySend),
                                                    @"yahoo" : @(UIReturnKeyYahoo), @"done" : @(UIReturnKeyDone), @"emergencyCall" : @(UIReturnKeyEmergencyCall)}),
            p(@"secureTextEntry", ISSPropertyTypeBool),
            p(S(clearsOnInsertion), ISSPropertyTypeBool),
            p(S(placeholder), ISSPropertyTypeString),
            p(S(text), ISSPropertyTypeString)
        ]];
    textInputProperties = [textInputProperties setByAddingObjectsFromSet:minimalTextInputProperties];
    allProperties = [allProperties setByAddingObjectsFromSet:textInputProperties];

    NSSet* textFieldProperties = [NSSet setWithArray:@[
            p(S(clearsOnBeginEditing), ISSPropertyTypeBool),
            pe(S(borderStyle), @{@"none" : @(UITextBorderStyleNone), @"bezel" : @(UITextBorderStyleBezel), @"line" : @(UITextBorderStyleLine), @"roundedRect" : @(UITextBorderStyleRoundedRect)}),
            p(S(background), ISSPropertyTypeImage),
            p(S(disabledBackground), ISSPropertyTypeImage)
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:textFieldProperties];

    textFieldProperties = [textFieldProperties setByAddingObjectsFromSet:textProperties];
    textFieldProperties = [textFieldProperties setByAddingObjectsFromSet:textInputProperties];
    textFieldProperties = [textFieldProperties setByAddingObjectsFromSet:resizableTextProperties];


    NSSet* textViewProperties = [NSSet setWithArray:@[
            p(S(allowsEditingTextAttributes), ISSPropertyTypeBool),
            peo(S(dataDetectorTypes), dataDetectorTypesValues),
            p(@"editable", ISSPropertyTypeBool),
            p(@"selectable", ISSPropertyTypeBool),
            p(S(textContainerInset), ISSPropertyTypeEdgeInsets)
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:textViewProperties];

    textViewProperties = [textViewProperties setByAddingObjectsFromSet:textProperties];
    textViewProperties = [textViewProperties setByAddingObjectsFromSet:textInputProperties];


    NSSet*imageViewProperties = [NSSet setWithArray:@[
            image,
            p(S(highlightedImage), ISSPropertyTypeImage)
        ]];
    allProperties = [allProperties setByAddingObjectsFromSet:imageViewProperties];


    NSSet* switchProperties = [NSSet setWithArray:@[
            p(S(onTintColor), ISSPropertyTypeColor),
            p(S(thumbTintColor), ISSPropertyTypeColor),
            p(S(onImage), ISSPropertyTypeImage),
            p(S(offImage), ISSPropertyTypeImage)
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:switchProperties];


    NSSet* sliderProperties = [NSSet setWithArray:@[
            p(S(minimumValueImage), ISSPropertyTypeImage),
            p(S(maximumValueImage), ISSPropertyTypeImage),
            p(S(minimumTrackTintColor), ISSPropertyTypeColor),
            p(S(maximumTrackTintColor), ISSPropertyTypeColor),
            p(S(thumbTintColor), ISSPropertyTypeColor),
            pp(@"maximumTrackImage", controlStateParametersValues, ISSPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setMaximumTrackImage:forState:)] ) [viewObject setMaximumTrackImage:value forState:state];
            }),
            pp(@"minimumTrackImage", controlStateParametersValues, ISSPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setMinimumTrackImage:forState:)] ) [viewObject setMinimumTrackImage:value forState:state];
            }),
            pp(@"thumbImage", controlStateParametersValues, ISSPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setThumbImage:forState:)] ) [viewObject setThumbImage:value forState:state];
            }),
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:sliderProperties];


    NSSet* stepperProperties = [NSSet setWithArray:@[
            p(@"continuous", ISSPropertyTypeBool),
            p(S(autorepeat), ISSPropertyTypeBool),
            p(S(wraps), ISSPropertyTypeBool),
            p(S(minimumValue), ISSPropertyTypeNumber),
            p(S(maximumValue), ISSPropertyTypeNumber),
            p(S(stepValue), ISSPropertyTypeNumber),
            backgroundImage,
            pp(@"decrementImage", controlStateParametersValues, ISSPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setDecrementImage:forState:)] ) [viewObject setDecrementImage:value forState:state];
            }),
            pp(@"incrementImage", controlStateParametersValues, ISSPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setIncrementImage:forState:)] ) [viewObject setIncrementImage:value forState:state];
            }),
            pp(@"dividerImage", controlStateParametersValues, ISSPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                if( parameters.count > 1 && [viewObject respondsToSelector:@selector(setDividerImage:forLeftSegmentState:rightSegmentState:)] ) {
                    [viewObject setDividerImage:value forLeftSegmentState:(UIControlState)[parameters[0] unsignedIntegerValue] rightSegmentState:(UIControlState)[parameters[1] unsignedIntegerValue]];
                }
            })
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:stepperProperties];


    NSSet* statefulTitleTextAttributes = [NSSet setWithArray:@[
            font,
            textColor,
            shadowColor,
            shadowOffset
        ]];
    allProperties = [allProperties setByAddingObjectsFromSet:statefulTitleTextAttributes];

    NSSet* segmentedControlProperties = [NSSet setWithArray:@[
            p(S(apportionsSegmentWidthsByContent), ISSPropertyTypeBool),
            p(@"momentary", ISSPropertyTypeBool),
            backgroundImage,
            pp(@"contentPositionAdjustment", barMetricsSegmentAndControlStateParameters, ISSPropertyTypeOffset, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                if( parameters.count > 0 && [viewObject respondsToSelector:@selector(setContentPositionAdjustment:forSegmentType:barMetrics:)] ) {
                    UISegmentedControlSegment segment = parameters.count > 0 ? (UISegmentedControlSegment)[parameters[0] integerValue] : UISegmentedControlSegmentAny;
                    UIBarMetrics metrics = parameters.count > 1 ? (UIBarMetrics)[parameters[1] integerValue] : UIBarMetricsDefault;
                    [viewObject setContentPositionAdjustment:[value UIOffsetValue] forSegmentType:segment barMetrics:metrics];
                }
            }),
            pp(@"dividerImage", barMetricsSegmentAndControlStateParameters, ISSPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                if( parameters.count > 1 && [viewObject respondsToSelector:@selector(setDividerImage:forLeftSegmentState:rightSegmentState:barMetrics:)] ) {
                    UIControlState leftState = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                    UIControlState rightState = parameters.count > 1 ? (UIControlState)[parameters[1] unsignedIntegerValue] : UIControlStateNormal;
                    UIBarMetrics metrics = parameters.count > 2 ? (UIBarMetrics)[parameters[2] integerValue] : UIBarMetricsDefault;
                    [viewObject setDividerImage:value forLeftSegmentState:leftState rightSegmentState:rightState barMetrics:metrics];
                }
            }),
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:segmentedControlProperties];
    segmentedControlProperties = [segmentedControlProperties setByAddingObjectsFromSet:statefulTitleTextAttributes];


    NSSet* barButtonProperties = [NSSet setWithArray:@[
            p(@"enabled", ISSPropertyTypeBool),
            p(S(title), ISSPropertyTypeString),
            image,
            p(S(landscapeImagePhone), ISSPropertyTypeImage),
            p(S(imageInsets), ISSPropertyTypeEdgeInsets),
            p(S(landscapeImagePhoneInsets), ISSPropertyTypeEdgeInsets),
            pe(S(style), @{@"plain" : @(UIBarButtonItemStylePlain), @"bordered" : @(UIBarButtonItemStyleBordered),
                                @"done" : @(UIBarButtonItemStyleDone)}),
            p(S(width), ISSPropertyTypeNumber),
            backgroundImage,
            pp(@"backgroundVerticalPositionAdjustment", barMetricsParameters, ISSPropertyTypeOffset, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIBarMetrics metrics = parameters.count > 0 ? (UIBarMetrics) [parameters[0] integerValue] : UIBarMetricsDefault;
                if( [viewObject respondsToSelector:@selector(setBackgroundVerticalPositionAdjustment:forBarMetrics:)] ) {
                    [viewObject setBackgroundVerticalPositionAdjustment:[value floatValue] forBarMetrics:metrics];
                }
            }),
            titlePositionAdjustment,
            pp(@"backButtonBackgroundImage", barMetricsAndControlStateParameters, ISSPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState state = parameters.count > 0 ? (UIControlState) [parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                UIBarMetrics metrics = parameters.count > 1 ? (UIBarMetrics) [parameters[1] integerValue] : UIBarMetricsDefault;
                if( [viewObject respondsToSelector:@selector(setBackButtonBackgroundImage:forState:barMetrics:)] ) {
                    [viewObject setBackButtonBackgroundImage:value forState:state barMetrics:metrics];
                }
            }),
            pp(@"backButtonBackgroundVerticalPositionAdjustment", barMetricsParameters, ISSPropertyTypeOffset, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIBarMetrics metrics = parameters.count > 0 ? (UIBarMetrics) [parameters[0] integerValue] : UIBarMetricsDefault;
                if( [viewObject respondsToSelector:@selector(setBackButtonBackgroundVerticalPositionAdjustment:forBarMetrics:)] ) {
                    [viewObject setBackButtonBackgroundVerticalPositionAdjustment:[value floatValue] forBarMetrics:metrics];
                }
            }),
            pp(@"backButtonTitlePositionAdjustment", barMetricsParameters, ISSPropertyTypeOffset, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIBarMetrics metrics = parameters.count > 0 ? (UIBarMetrics) [parameters[0] integerValue] : UIBarMetricsDefault;
                if( [viewObject respondsToSelector:@selector(setBackButtonTitlePositionAdjustment:forBarMetrics:)] ) {
                    [viewObject setBackButtonTitlePositionAdjustment:[value UIOffsetValue] forBarMetrics:metrics];
                }
            }),
    ]];

    allProperties = [allProperties setByAddingObjectsFromSet:barButtonProperties];
    barButtonProperties = [barButtonProperties setByAddingObjectsFromSet:statefulTitleTextAttributes];


    NSDictionary* accessoryTypes = @{@"none" : @(UITableViewCellAccessoryNone), @"checkmark" : @(UITableViewCellAccessoryCheckmark), @"detailButton" : @(UITableViewCellAccessoryDetailButton),
                        @"disclosureButton" : @(UITableViewCellAccessoryDetailDisclosureButton), @"disclosureIndicator" : @(UITableViewCellAccessoryDisclosureIndicator)};

    NSSet* tableViewCellProperties = [NSSet setWithArray:@[
            pe(S(selectionStyle), @{@"none" : @(UITableViewCellSelectionStyleNone), @"default" : @(UITableViewCellSelectionStyleDefault), @"blue" : @(UITableViewCellSelectionStyleBlue), @"gray" : @(UITableViewCellSelectionStyleGray)}),
            p(@"selected", ISSPropertyTypeBool),
            p(@"highlighted", ISSPropertyTypeBool),
            pe(S(selectionStyle), @{@"none" : @(UITableViewCellEditingStyleNone), @"delete" : @(UITableViewCellEditingStyleDelete), @"insert" : @(UITableViewCellEditingStyleInsert)}),
            p(S(showsReorderControl), ISSPropertyTypeBool),
            p(S(shouldIndentWhileEditing), ISSPropertyTypeBool),
            pe(S(accessoryType), accessoryTypes),
            pe(S(editingAccessoryType), accessoryTypes),
            p(S(indentationLevel), ISSPropertyTypeNumber),
            p(S(indentationWidth), ISSPropertyTypeNumber),
            p(S(separatorInset), ISSPropertyTypeEdgeInsets),
            p(@"editing", ISSPropertyTypeBool)
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:tableViewCellProperties];


    NSSet* toolbarProperties = [NSSet setWithArray:@[
            barStyle,
            translucent,
            barTintColor,
            backgroundImage,
            shadowImage
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:toolbarProperties];


    NSSet* navigationBarProperties = [NSSet setWithArray:@[
            barStyle,
            translucent,
            barTintColor,
            backgroundImage,
            shadowImage,
            p(S(backIndicatorImage), ISSPropertyTypeImage),
            p(S(backIndicatorTransitionMaskImage), ISSPropertyTypeImage)
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:navigationBarProperties];
    navigationBarProperties = [navigationBarProperties setByAddingObjectsFromSet:statefulTitleTextAttributes];


    NSDictionary* searchBarIconParameters = @{@"iconBookmark" : @(UISearchBarIconBookmark), @"iconClear" : @(UISearchBarIconClear),
                    @"iconResultsList" : @(UISearchBarIconResultsList), @"iconSearch" : @(UISearchBarIconSearch)};
    NSMutableDictionary* statefulSearchBarIconParameters = [NSMutableDictionary dictionaryWithDictionary:searchBarIconParameters];
    [statefulSearchBarIconParameters addEntriesFromDictionary:controlStateParametersValues];

    NSSet* searchBarProperties = [NSSet setWithArray:@[
            barStyle,
            p(S(text), ISSPropertyTypeString),
            p(S(prompt), ISSPropertyTypeString),
            p(S(placeholder), ISSPropertyTypeString),
            p(S(showsBookmarkButton), ISSPropertyTypeBool),
            p(S(showsCancelButton), ISSPropertyTypeBool),
            p(S(showsSearchResultsButton), ISSPropertyTypeBool),
            p(@"searchResultsButtonSelected", ISSPropertyTypeBool),
            barTintColor,
            pe(S(searchBarStyle), @{@"default" : @(UISearchBarStyleDefault), @"minimal" : @(UISearchBarStyleMinimal), @"prominent" : @(UISearchBarStyleProminent)}),
            translucent,
            p(S(showsScopeBar), ISSPropertyTypeBool),
            p(S(scopeBarBackgroundImage), ISSPropertyTypeImage),
            backgroundImage,
            pp(@"searchFieldBackgroundImage", controlStateParametersValues, ISSPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setSearchFieldBackgroundImage:forState:)] ) [viewObject setSearchFieldBackgroundImage:value forState:state];
            }),
            pp(@"imageForSearchBarIcon", statefulSearchBarIconParameters, ISSPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UISearchBarIcon icon = parameters.count > 0 ? (UISearchBarIcon)[parameters[0] integerValue] : UISearchBarIconSearch;
                UIControlState state = parameters.count > 1 ? (UIControlState)[parameters[1] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setImage:forSearchBarIcon:state:)] ) [viewObject setImage:value forSearchBarIcon:icon state:state];
            }),
            pp(@"scopeBarButtonBackgroundImage", controlStateParametersValues, ISSPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setScopeBarButtonBackgroundImage:forState:)] ) [viewObject setScopeBarButtonBackgroundImage:value forState:state];
            }),
            pp(@"scopeBarButtonDividerImage", controlStateParametersValues, ISSPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState leftState = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                UIControlState rightState = parameters.count > 1 ? (UIControlState)[parameters[1] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setScopeBarButtonDividerImage:forLeftSegmentState:rightSegmentState:)] ) {
                    [viewObject setScopeBarButtonDividerImage:value forLeftSegmentState:leftState rightSegmentState:rightState];
                }
            }),
            pp(@"scopeBarButtonTitleFont", controlStateParametersValues, ISSPropertyTypeFont, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                setTitleTextAttributes(viewObject, value, parameters, UITextAttributeFont);
            }),
            pp(@"scopeBarButtonTitleTextColor", controlStateParametersValues, ISSPropertyTypeColor, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                setTitleTextAttributes(viewObject, value, parameters, UITextAttributeTextColor);
            }),
            pp(@"scopeBarButtonTitleShadowColor", controlStateParametersValues, ISSPropertyTypeColor, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                setTitleTextAttributes(viewObject, value, parameters, UITextAttributeTextShadowColor);
            }),
            pp(@"scopeBarButtonTitleShadowOffset", controlStateParametersValues, ISSPropertyTypeOffset, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                setTitleTextAttributes(viewObject, value, parameters, UITextAttributeTextShadowOffset);
            }),
            p(S(searchFieldBackgroundPositionAdjustment), ISSPropertyTypeOffset),
            p(S(searchTextPositionAdjustment), ISSPropertyTypeOffset),
            pp(@"positionAdjustmentForSearchBarIcon", searchBarIconParameters, ISSPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UISearchBarIcon icon = parameters.count > 0 ? (UISearchBarIcon)[parameters[0] integerValue] : UISearchBarIconSearch;
                if( [viewObject respondsToSelector:@selector(setPositionAdjustment:forSearchBarIcon:)] ) [viewObject setPositionAdjustment:[value UIOffsetValue] forSearchBarIcon:icon];
            })
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:searchBarProperties];
    searchBarProperties = [searchBarProperties setByAddingObjectsFromSet:minimalTextInputProperties];


    NSSet* tabBarProperties = [NSSet setWithArray:@[
            barTintColor,
            p(S(selectedImageTintColor), ISSPropertyTypeColor),
            backgroundImage,
            p(S(selectionIndicatorImage), ISSPropertyTypeImage),
            shadowImage,
            pe(S(itemPositioning), @{@"automatic" : @(UITabBarItemPositioningAutomatic), @"centered" : @(UITabBarItemPositioningCentered), @"fill" : @(UITabBarItemPositioningFill)}),
            p(S(itemWidth), ISSPropertyTypeNumber),
            p(S(itemSpacing), ISSPropertyTypeNumber),
            barStyle,
            translucent
        ]];

    NSSet* tabBarItemProperties = [NSSet setWithArray:@[
            p(S(selectedImage), ISSPropertyTypeImage),
            titlePositionAdjustment,
    ]];



    #define resistanceIsFutile (id <NSCopying>)
    classProperties = @{
            resistanceIsFutile UIView.class : viewProperties,
            resistanceIsFutile UIImageView.class : imageViewProperties,
            resistanceIsFutile UIScrollView.class : scrollViewProperties,
            resistanceIsFutile UITableView.class : tableViewProperties,
            resistanceIsFutile UIWebView.class : webViewProperties,
            resistanceIsFutile UITableViewCell.class : tableViewCellProperties,
            resistanceIsFutile UICollectionView.class : collectionViewProperties,

            resistanceIsFutile UINavigationBar.class : navigationBarProperties,
            resistanceIsFutile UISearchBar.class : searchBarProperties,
            resistanceIsFutile UIToolbar.class : toolbarProperties,
            resistanceIsFutile UIBarButtonItem.class : barButtonProperties,

            resistanceIsFutile UITabBar.class : tabBarProperties,
            resistanceIsFutile UITabBarItem.class : tabBarItemProperties,

            resistanceIsFutile UIControl.class : controlProperties,
            resistanceIsFutile UIActivityIndicatorView.class : activityIndicatorProperties,
            resistanceIsFutile UIButton.class : buttonProperties,
            resistanceIsFutile UILabel.class : labelProperties,
            resistanceIsFutile UIProgressView.class : progressViewProperties,
            resistanceIsFutile UISegmentedControl.class : segmentedControlProperties,
            resistanceIsFutile UISlider.class : sliderProperties,
            resistanceIsFutile UIStepper.class : stepperProperties,
            resistanceIsFutile UISwitch.class : switchProperties,
            resistanceIsFutile UITextField.class : textFieldProperties,
            resistanceIsFutile UITextView.class : textViewProperties
    };

    NSMutableDictionary* _classesToNames = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* _typeNamesToClasses = [[NSMutableDictionary alloc] init];
    for(Class clazz in classProperties.allKeys) {
        NSString* typeName = [[clazz description] lowercaseString];
        _classesToNames[resistanceIsFutile clazz] = typeName;
        _typeNamesToClasses[typeName] = clazz;
    }
    _classesToNames[resistanceIsFutile UIWindow.class] = @"uiwindow";
    _typeNamesToClasses[@"uiwindow"] = UIWindow.class;
    classesToTypeNames = [NSDictionary dictionaryWithDictionary:_classesToNames];
    typeNamesToClasses = [NSDictionary dictionaryWithDictionary:_typeNamesToClasses];
}



@end