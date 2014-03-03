//
//  ISSPropertyDefinition.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSStyleSheetParser.h"

#import "ISSPropertyDefinition.h"
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


#define S(selName) NSStringFromSelector(@selector(selName))


static NSDictionary* classProperties;
static NSDictionary* classesToNames;
static NSSet* allProperties;
static NSSet* validPrefixKeyPaths;



@interface ISSPropertyDefinition ()

@property (nonatomic, strong) NSDictionary* enumValues;
@property (nonatomic, copy) PropertySetterBlock propertySetterBlock;

- (id) initWithName:(NSString *)name type:(ISStyleSheetPropertyType)type;
- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISStyleSheetPropertyType)type;
- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISStyleSheetPropertyType)type enumBlock:(NSDictionary*)enumValues enumBitMaskType:(BOOL)enumBitMaskType;
- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISStyleSheetPropertyType)type enumValues:(NSDictionary*)enumValues
          enumBitMaskType:(BOOL)enumBitMaskType setterBlock:(void (^)(ISSPropertyDefinition*, id, id, NSArray*))setterBlock parameterEnumValues:(NSDictionary*)parameterEnumValues;

@end



static ISSPropertyDefinition* p(NSString* name, ISStyleSheetPropertyType type) {
    return [[ISSPropertyDefinition alloc] initWithName:name type:type];
}

static ISSPropertyDefinition* ps(NSString* name, ISStyleSheetPropertyType type, PropertySetterBlock setterBlock) {
    return [[ISSPropertyDefinition alloc] initWithName:name aliases:nil type:type enumValues:nil
                                          enumBitMaskType:NO setterBlock:setterBlock parameterEnumValues:nil];
}

static ISSPropertyDefinition* pa(NSString* name, NSArray* aliases, ISStyleSheetPropertyType type) {
    return [[ISSPropertyDefinition alloc] initWithName:name aliases:aliases type:type];
}

static ISSPropertyDefinition* pe(NSString* name, NSDictionary* enumValues) {
    return [[ISSPropertyDefinition alloc] initWithName:name aliases:nil type:ISStyleSheetPropertyTypeEnumType enumBlock:enumValues enumBitMaskType:NO];
}

static ISSPropertyDefinition* peo(NSString* name, NSDictionary* enumValues) {
    return [[ISSPropertyDefinition alloc] initWithName:name aliases:nil type:ISStyleSheetPropertyTypeEnumType enumValues:enumValues
                                      enumBitMaskType:YES setterBlock:nil parameterEnumValues:nil];
}

static ISSPropertyDefinition* pp(NSString* name, NSDictionary* paramValues, ISStyleSheetPropertyType type, PropertySetterBlock setterBlock) {
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

- (id) initWithName:(NSString *)name type:(ISStyleSheetPropertyType)type {
    return [self initWithName:name aliases:@[] type:type];
}

- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISStyleSheetPropertyType)type {
    return [self initWithName:name aliases:aliases type:type enumBlock:nil enumBitMaskType:NO];
}

- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISStyleSheetPropertyType)type enumBlock:(NSDictionary*)enumValues enumBitMaskType:(BOOL)enumBitMaskType {
    return [self initWithName:name aliases:aliases type:type enumValues:enumValues enumBitMaskType:enumBitMaskType setterBlock:nil parameterEnumValues:nil];
}

- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISStyleSheetPropertyType)type enumValues:(NSDictionary*)enumValues
          enumBitMaskType:(BOOL)enumBitMaskType setterBlock:(void (^)(ISSPropertyDefinition*, id, id, NSArray*))setterBlock parameterEnumValues:(NSDictionary*)parameterEnumValues {
    if (self = [super init]) {
        _name = name;

        _allNames = @[name];
        if( aliases ) _allNames = [_allNames arrayByAddingObjectsFromArray:aliases];

        _type = type;
        _enumValues = [enumValues dictionaryWithLowerCaseKeys];
        _enumBitMaskType = enumBitMaskType;

        _propertySetterBlock = setterBlock;
        _parameterEnumValues = [parameterEnumValues dictionaryWithLowerCaseKeys];
    }
    return self;
}

- (id) targetObjectForObject:(id)obj andPrefixKeyPath:(NSString*)prefixKeyPath {
    if( prefixKeyPath ) {
        // First, check if prefix key path is a valid selector
        if( [obj respondsToSelector:NSSelectorFromString(prefixKeyPath)] ) {
            return [obj valueForKeyPath:prefixKeyPath];
        } else {
            // Then attempt to match prefix key path against known prefix key paths, and make sure correct name is used
            for(NSString* validPrefix in validPrefixKeyPaths) {
                if( [validPrefix isEqualIgnoreCase:prefixKeyPath] && [obj respondsToSelector:NSSelectorFromString(validPrefix)] ) {
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
            if( ![prefixKeyPath hasData] ) prefixKeyPath = dotSeparatedComponents[0];
            propertyName = dotSeparatedComponents[1];
        }

        obj = [self targetObjectForObject:obj andPrefixKeyPath:prefixKeyPath];

        if( [obj respondsToSelector:NSSelectorFromString(propertyName)] ) {
            if( [value isKindOfClass:ISSLazyValue.class] ) value = [value evaluateWithViewObject:obj];
            if( [value respondsToSelector:@selector(transformToNSValue)] ) value = [value transformToNSValue];
            [obj setValue:value forKeyPath:propertyName];
        } else {
            ISSLogDebug(@"Property %@ not found in %@", _name, obj);
        }
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
    if( [value isKindOfClass:ISSLazyValue.class] ) value = [value evaluateWithViewObject:obj];
    if( value && value != [NSNull null] ) _propertySetterBlock(self, obj, value, params);
}

- (BOOL) isParameterizedProperty {
    return _parameterEnumValues != nil;
}

- (NSString*) displayDescription {
    return self.name;
}

- (NSString*) typeDescription {
    switch(self.type) {
        case ISStyleSheetPropertyTypeBool : return @"Boolean";
        case ISStyleSheetPropertyTypeNumber : return @"Number";
        case ISStyleSheetPropertyTypeOffset : return @"UIOffset";
        case ISStyleSheetPropertyTypeRect : return @"CGRect";
        case ISStyleSheetPropertyTypeSize : return @"CGSize";
        case ISStyleSheetPropertyTypePoint : return @"CGPoint";
        case ISStyleSheetPropertyTypeEdgeInsets : return @"UIEdgeInsets";
        case ISStyleSheetPropertyTypeColor : return @"UIColor";
        case ISStyleSheetPropertyTypeCGColor : return @"CGColor";
        case ISStyleSheetPropertyTypeTransform : return @"CGAffineTransform";
        case ISStyleSheetPropertyTypeFont : return @"UIFont";
        case ISStyleSheetPropertyTypeImage : return @"UIImage";
        case ISStyleSheetPropertyTypeEnumType : return @"Enum";
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
    return [object isKindOfClass:[ISSPropertyDefinition class]] &&
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

+ (NSSet*) propertyDefinitionsForType:(ISStyleSheetPropertyType)propertyType {
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

+ (NSString*) typeForViewClass:(Class)viewClass {
    for(Class clazz in classesToNames.allKeys) {
        if( [viewClass isSubclassOfClass:clazz] ) {
            return classesToNames[clazz];
        }
    }
    return @"uiview"; // Default type
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

    ISSPropertyDefinition* backgroundImage = pp(S(backgroundImage), barMetricsPositionAndControlStateParameters, ISStyleSheetPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
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

    ISSPropertyDefinition* image = pp(S(image), controlStateParametersValues, ISStyleSheetPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
        UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
        if( [viewObject respondsToSelector:@selector(setImage:forState:)] ) {
            [viewObject setImage:value forState:state];
        } if( [viewObject respondsToSelector:@selector(setImage:)] ) {
            [viewObject setImage:value];
        }
    });

    ISSPropertyDefinition* shadowImage = pp(S(shadowImage), barPositionParameters, ISStyleSheetPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
        if( [viewObject respondsToSelector:@selector(setShadowImage:forToolbarPosition:)] ) {
            UIBarPosition position = parameters.count > 0 ? (UIBarPosition) [parameters[0] unsignedIntegerValue] : UIBarPositionAny;
            [viewObject setShadowImage:value forToolbarPosition:position];
        } else if( [viewObject respondsToSelector:@selector(setShadowImage:)] ) {
            [viewObject setShadowImage:value];
        }
    });

    ISSPropertyDefinition* title = pp(S(title), controlStateParametersValues, ISStyleSheetPropertyTypeString, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
        UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
        if( [viewObject respondsToSelector:@selector(setBackgroundImage:forState:)] ) {
            [viewObject setTitle:value forState:state];
        } else if( [viewObject respondsToSelector:@selector(setTitle:)] ) {
            [viewObject setTitle:value];
        }
    });

    ISSPropertyDefinition* font = pp(S(font), controlStateParametersValues, ISStyleSheetPropertyTypeFont, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
        if( [viewObject respondsToSelector:@selector(setFont:)] ) {
            [viewObject setFont:value];
        } else {
            setTitleTextAttributes(viewObject, value, parameters, UITextAttributeFont);
        }
    });

    ISSPropertyDefinition* textColor = pp(S(textColor), controlStateParametersValues, ISStyleSheetPropertyTypeColor, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
        if( [viewObject respondsToSelector:@selector(setTextColor:)] ) {
            [viewObject setTextColor:value];
        } else {
            setTitleTextAttributes(viewObject, value, parameters, UITextAttributeTextColor);
        }
    });

    ISSPropertyDefinition* shadowColor = pp(S(shadowColor), controlStateParametersValues, ISStyleSheetPropertyTypeColor, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
        if( [viewObject respondsToSelector:@selector(setShadowColor:)] ) {
            [viewObject setShadowColor:value];
        } else {
            setTitleTextAttributes(viewObject, value, parameters, UITextAttributeTextShadowColor);
        }
    });

    ISSPropertyDefinition* shadowOffset = pp(S(shadowOffset), controlStateParametersValues, ISStyleSheetPropertyTypeOffset, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
        if( [viewObject respondsToSelector:@selector(setShadowOffset:)] ) {
            [viewObject setShadowOffset:[value CGSizeValue]];
        } else {
            setTitleTextAttributes(viewObject, value, parameters, UITextAttributeTextShadowOffset);
        }
    });

    ISSPropertyDefinition* barTintColor = p(S(barTintColor), ISStyleSheetPropertyTypeColor);

    ISSPropertyDefinition* barStyle = pe(S(barStyle), @{@"default" : @(UIBarStyleDefault), @"black" : @(UIBarStyleBlack), @"blackOpaque" : @(UIBarStyleBlackOpaque), @"blackTranslucent" : @(UIBarStyleBlackTranslucent)});

    ISSPropertyDefinition* translucent = p(@"translucent", ISStyleSheetPropertyTypeBool);

    ISSPropertyDefinition* titlePositionAdjustment = pp(S(titlePositionAdjustment), barMetricsParameters, ISStyleSheetPropertyTypeOffset, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
        if( [viewObject respondsToSelector:@selector(setTitlePositionAdjustment:forBarMetrics:)] ) {
            UIBarMetrics metrics = parameters.count > 0 ? (UIBarMetrics) [parameters[0] integerValue] : UIBarMetricsDefault;
            [viewObject setTitlePositionAdjustment:[value UIOffsetValue] forBarMetrics:metrics];
        } else if( [viewObject respondsToSelector:@selector(setTitlePositionAdjustment:)] ) {
            [viewObject setTitlePositionAdjustment:[value UIOffsetValue]];
        }
    });

    ISSPropertyDefinition* allowsSelection = p(S(allowsSelection), ISStyleSheetPropertyTypeBool);

    ISSPropertyDefinition* allowsMultipleSelection = p(S(allowsMultipleSelection), ISStyleSheetPropertyTypeBool);


    NSSet* viewProperties = [NSSet setWithArray:@[
            p(S(alpha), ISStyleSheetPropertyTypeNumber),
            p(S(autoresizesSubviews), ISStyleSheetPropertyTypeBool),
            peo(S(autoresizingMask), @{ @"none" : @(UIViewAutoresizingNone), @"width" : @(UIViewAutoresizingFlexibleWidth), @"height" : @(UIViewAutoresizingFlexibleHeight),
                                    @"bottom" : @(UIViewAutoresizingFlexibleBottomMargin), @"top" : @(UIViewAutoresizingFlexibleTopMargin),
                                    @"left" : @(UIViewAutoresizingFlexibleLeftMargin), @"right" : @(UIViewAutoresizingFlexibleRightMargin)}
            ),
            p(S(backgroundColor), ISStyleSheetPropertyTypeColor),
            ps(S(bounds), ISStyleSheetPropertyTypeRect, ^(ISSPropertyDefinition* property, id viewObject, id value, NSArray* parameters) {
                if( [viewObject isKindOfClass:UIView.class] ) {
                    UIView* v = viewObject;
                    v.bounds = [value rectForView:v];
                }
            }),
            ps(S(center), ISStyleSheetPropertyTypePoint, ^(ISSPropertyDefinition* property, id viewObject, id value, NSArray* parameters) {
                if( [viewObject isKindOfClass:UIView.class] ) {
                    UIView* v = viewObject;
                    v.center = [value pointForView:v];
                }
            }),
            p(S(clearsContextBeforeDrawing), ISStyleSheetPropertyTypeBool),
            p(S(clipsToBounds), ISStyleSheetPropertyTypeBool),
            pe(S(contentMode), @{@"scaleToFill" : @(UIViewContentModeScaleToFill), @"scaleAspectFit" : @(UIViewContentModeScaleAspectFit),
                        @"scaleAspectFill" : @(UIViewContentModeScaleAspectFill), @"redraw" : @(UIViewContentModeRedraw), @"center" : @(UIViewContentModeCenter), @"top" : @(UIViewContentModeTop),
                        @"bottom" : @(UIViewContentModeBottom), @"left" : @(UIViewContentModeLeft), @"right" : @(UIViewContentModeRight), @"topLeft" : @(UIViewContentModeTopLeft),
                        @"topRight" : @(UIViewContentModeTopRight), @"bottomLeft" : @(UIViewContentModeBottomLeft), @"bottomRight" : @(UIViewContentModeBottomRight)}
            ),
            p(S(contentScaleFactor), ISStyleSheetPropertyTypeNumber),
            p(@"exclusiveTouch", ISStyleSheetPropertyTypeBool),
            ps(S(frame), ISStyleSheetPropertyTypeRect, ^(ISSPropertyDefinition* property, id viewObject, id value, NSArray* parameters) {
                if( [viewObject isKindOfClass:UIView.class] ) {
                    UIView* v = viewObject;
                    // Handle case when attempting to set frame on transformed view
                    CGAffineTransform t = v.transform;
                    v.transform = CGAffineTransformIdentity;
                    v.frame = [value rectForView:v];
                    v.transform = t;
                }
            }),
            p(@"hidden", ISStyleSheetPropertyTypeBool),
            pa(@"layer.anchorPoint", @[@"anchorPoint", @"anchor-point"], ISStyleSheetPropertyTypePoint),
            pa(@"layer.cornerRadius", @[@"cornerradius", @"corner-radius"], ISStyleSheetPropertyTypeNumber),
            pa(@"layer.borderColor", @[@"bordercolor", @"border-color"], ISStyleSheetPropertyTypeCGColor),
            pa(@"layer.borderWidth", @[@"borderwidth", @"border-width"], ISStyleSheetPropertyTypeNumber),
            p(@"multipleTouchEnabled", ISStyleSheetPropertyTypeBool),
            p(@"opaque", ISStyleSheetPropertyTypeBool),
            p(S(tintColor), ISStyleSheetPropertyTypeColor),
            pe(S(tintAdjustmentMode), @{@"automatic" : @(UIViewTintAdjustmentModeAutomatic), @"normal" : @(UIViewTintAdjustmentModeNormal), @"dimmed" : @(UIViewTintAdjustmentModeDimmed)}),
            p(S(transform), ISStyleSheetPropertyTypeTransform),
            p(@"userInteractionEnabled", ISStyleSheetPropertyTypeBool),
    ]];
    allProperties = viewProperties;


    NSSet* controlProperties = [NSSet setWithArray:@[
            p(@"enabled", ISStyleSheetPropertyTypeBool),
            p(@"highlighted", ISStyleSheetPropertyTypeBool),
            p(@"selected", ISStyleSheetPropertyTypeBool),
            pe(S(contentVerticalAlignment), @{@"center" : @(UIControlContentVerticalAlignmentCenter), @"top" : @(UIControlContentVerticalAlignmentTop),
                    @"bottom" : @(UIControlContentVerticalAlignmentBottom), @"fill" : @(UIControlContentVerticalAlignmentFill)}),
            pe(S(contentHorizontalAlignment), @{@"center" : @(UIControlContentHorizontalAlignmentCenter), @"left" : @(UIControlContentHorizontalAlignmentLeft),
                    @"right" : @(UIControlContentHorizontalAlignmentRight), @"fill" : @(UIControlContentHorizontalAlignmentFill)})
    ]];
    allProperties = [allProperties setByAddingObjectsFromSet:controlProperties];


    NSSet* scrollViewProperties = [NSSet setWithArray:@[
            p(S(contentOffset), ISStyleSheetPropertyTypePoint),
            p(S(contentSize), ISStyleSheetPropertyTypeSize),
            p(S(contentInset), ISStyleSheetPropertyTypeEdgeInsets),
            p(@"directionalLockEnabled", ISStyleSheetPropertyTypeBool),
            p(S(bounces), ISStyleSheetPropertyTypeBool),
            p(S(alwaysBounceVertical), ISStyleSheetPropertyTypeBool),
            p(S(alwaysBounceHorizontal), ISStyleSheetPropertyTypeBool),
            p(@"pagingEnabled", ISStyleSheetPropertyTypeBool),
            p(@"scrollEnabled", ISStyleSheetPropertyTypeBool),
            p(S(showsHorizontalScrollIndicator), ISStyleSheetPropertyTypeBool),
            p(S(showsVerticalScrollIndicator), ISStyleSheetPropertyTypeBool),
            p(S(scrollIndicatorInsets), ISStyleSheetPropertyTypeEdgeInsets),
            pe(S(indicatorStyle), @{@"default" : @(UIScrollViewIndicatorStyleDefault), @"black" : @(UIScrollViewIndicatorStyleBlack), @"white" : @(UIScrollViewIndicatorStyleWhite)}),
            pe(S(decelerationRate), @{@"normal" : @(UIScrollViewDecelerationRateNormal), @"fast" : @(UIScrollViewDecelerationRateFast)}),
            p(S(delaysContentTouches), ISStyleSheetPropertyTypeBool),
            p(S(canCancelContentTouches), ISStyleSheetPropertyTypeBool),
            p(S(minimumZoomScale), ISStyleSheetPropertyTypeNumber),
            p(S(maximumZoomScale), ISStyleSheetPropertyTypeNumber),
            p(S(bouncesZoom), ISStyleSheetPropertyTypeBool),
            p(S(scrollsToTop), ISStyleSheetPropertyTypeBool),
            pe(S(keyboardDismissMode), @{@"none" : @(UIScrollViewKeyboardDismissModeNone), @"onDrag" : @(UIScrollViewKeyboardDismissModeOnDrag), @"interactive" : @(UIScrollViewKeyboardDismissModeInteractive)})
    ]];
    allProperties = [allProperties setByAddingObjectsFromSet:scrollViewProperties];

    NSSet* tableViewProperties = [NSSet setWithArray:@[
            p(S(rowHeight), ISStyleSheetPropertyTypeNumber),
            p(S(sectionHeaderHeight), ISStyleSheetPropertyTypeNumber),
            p(S(sectionFooterHeight), ISStyleSheetPropertyTypeNumber),
            p(S(estimatedRowHeight), ISStyleSheetPropertyTypeNumber),
            p(S(estimatedSectionHeaderHeight), ISStyleSheetPropertyTypeNumber),
            p(S(estimatedSectionFooterHeight), ISStyleSheetPropertyTypeNumber),
            p(S(separatorInset), ISStyleSheetPropertyTypeEdgeInsets),
            allowsSelection,
            p(S(allowsSelectionDuringEditing), ISStyleSheetPropertyTypeBool),
            allowsMultipleSelection,
            p(S(allowsMultipleSelectionDuringEditing), ISStyleSheetPropertyTypeBool),
            p(S(sectionIndexMinimumDisplayRowCount), ISStyleSheetPropertyTypeNumber),
            p(S(sectionIndexColor), ISStyleSheetPropertyTypeColor),
            p(S(sectionIndexBackgroundColor), ISStyleSheetPropertyTypeColor),
            p(S(sectionIndexTrackingBackgroundColor), ISStyleSheetPropertyTypeColor),
            pe(S(separatorStyle), @{@"none" : @(UITableViewCellSeparatorStyleNone), @"singleLine" : @(UITableViewCellSeparatorStyleSingleLine), @"singleLineEtched" : @(UITableViewCellSeparatorStyleSingleLineEtched)}),
            p(S(separatorColor), ISStyleSheetPropertyTypeColor)
    ]];
    allProperties = [allProperties setByAddingObjectsFromSet:tableViewProperties];


    NSDictionary* dataDetectorTypesValues = @{@"all" : @(UIDataDetectorTypeAll), @"none" : @(UIDataDetectorTypeNone), @"address" : @(UIDataDetectorTypeAddress),
                        @"calendarEvent" : @(UIDataDetectorTypeCalendarEvent), @"link" : @(UIDataDetectorTypeLink), @"phoneNumber" : @(UIDataDetectorTypePhoneNumber)};

    NSSet* webViewProperties = [NSSet setWithArray:@[
            p(S(scalesPageToFit), ISStyleSheetPropertyTypeBool),
            pe(S(dataDetectorTypes), dataDetectorTypesValues),
            p(S(allowsInlineMediaPlayback), ISStyleSheetPropertyTypeBool),
            p(S(mediaPlaybackRequiresUserAction), ISStyleSheetPropertyTypeBool),
            p(S(mediaPlaybackAllowsAirPlay), ISStyleSheetPropertyTypeBool),
            p(S(suppressesIncrementalRendering), ISStyleSheetPropertyTypeBool),
            p(S(keyboardDisplayRequiresUserAction), ISStyleSheetPropertyTypeBool),
            pe(S(paginationMode), @{@"unpaginated" : @(UIWebPaginationModeUnpaginated), @"lefttoright" : @(UIWebPaginationModeLeftToRight),
                    @"toptobottom" : @(UIWebPaginationModeTopToBottom), @"bottomtotop" : @(UIWebPaginationModeBottomToTop), @"righttoleft" : @(UIWebPaginationModeRightToLeft)}),
            pe(S(paginationBreakingMode), @{@"page" : @(UIWebPaginationBreakingModePage), @"column" : @(UIWebPaginationBreakingModeColumn)}),
            p(S(pageLength), ISStyleSheetPropertyTypeNumber),
            p(S(gapBetweenPages), ISStyleSheetPropertyTypeNumber),
    ]];
    allProperties = [allProperties setByAddingObjectsFromSet:webViewProperties];


    NSSet* collectionViewProperties = [NSSet setWithArray:@[
            allowsSelection,
            allowsMultipleSelection
    ]];
    allProperties = [allProperties setByAddingObjectsFromSet:collectionViewProperties];


    NSSet* activityIndicatorProperties = [NSSet setWithArray:@[
            pe(S(activityIndicatorViewStyle), @{@"gray" : @(UIActivityIndicatorViewStyleGray), @"white" : @(UIActivityIndicatorViewStyleWhite), @"whiteLarge" : @(UIActivityIndicatorViewStyleWhiteLarge)}),
            p(S(color), ISStyleSheetPropertyTypeColor),
            p(S(hidesWhenStopped), ISStyleSheetPropertyTypeBool)
    ]];
    allProperties = [allProperties setByAddingObjectsFromSet:activityIndicatorProperties];


    NSSet* buttonProperties = [NSSet setWithArray:@[
            p(S(showsTouchWhenHighlighted), ISStyleSheetPropertyTypeBool),
            p(S(adjustsImageWhenHighlighted), ISStyleSheetPropertyTypeBool),
            p(S(adjustsImageWhenDisabled), ISStyleSheetPropertyTypeBool),
            p(S(contentEdgeInsets), ISStyleSheetPropertyTypeEdgeInsets),
            p(S(titleEdgeInsets), ISStyleSheetPropertyTypeEdgeInsets),
            p(S(imageEdgeInsets), ISStyleSheetPropertyTypeEdgeInsets),
            p(S(reversesTitleShadowWhenHighlighted), ISStyleSheetPropertyTypeBool),
            title,
            pp(@"titleColor", controlStateParametersValues, ISStyleSheetPropertyTypeColor, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                [viewObject setTitleColor:value forState:state];
            }),
            pp(@"titleShadowColor", controlStateParametersValues, ISStyleSheetPropertyTypeColor, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                [viewObject setTitleShadowColor:value forState:state];
            }),
            image,
            backgroundImage
    ]];
    allProperties = [allProperties setByAddingObjectsFromSet:buttonProperties];


    NSSet* textProperties = [NSSet setWithArray:@[
            font,
            textColor,
            pe(S(textAlignment), @{@"left" : @(NSTextAlignmentLeft), @"center" : @(NSTextAlignmentCenter), @"right" : @(NSTextAlignmentRight)})
    ]];

    NSSet* resizableTextProperties = [NSSet setWithArray:@[
            p(S(adjustsFontSizeToFitWidth), ISStyleSheetPropertyTypeBool),
            p(S(minimumFontSize), ISStyleSheetPropertyTypeNumber),
            p(S(minimumScaleFactor), ISStyleSheetPropertyTypeNumber)
    ]];

    NSSet* labelProperties = [NSSet setWithArray:@[
            pe(S(baselineAdjustment), @{@"none" : @(UIBaselineAdjustmentNone), @"alignBaselines" : @(UIBaselineAdjustmentAlignBaselines),
                    @"alignCenters" : @(UIBaselineAdjustmentAlignCenters)}
            ),
            pe(S(lineBreakMode), @{@"wordWrap" : @(NSLineBreakByWordWrapping), @"charWrap" : @(NSLineBreakByCharWrapping),
                    @"clip" : @(NSLineBreakByClipping), @"truncateHead" : @(NSLineBreakByTruncatingHead), @"truncateTail" : @(NSLineBreakByTruncatingTail),
                    @"truncateMiddle" : @(NSLineBreakByTruncatingMiddle)}
            ),
            p(S(numberOfLines), ISStyleSheetPropertyTypeNumber),
            p(S(preferredMaxLayoutWidth), ISStyleSheetPropertyTypeNumber),
            shadowOffset,
            p(S(highlightedTextColor), ISStyleSheetPropertyTypeColor),
            shadowColor,
            p(S(text), ISStyleSheetPropertyTypeString)
    ]];
    labelProperties = [labelProperties setByAddingObjectsFromSet:textProperties];
    labelProperties = [labelProperties setByAddingObjectsFromSet:resizableTextProperties];
    allProperties = [allProperties setByAddingObjectsFromSet:labelProperties];


    NSSet* progressViewProperties = [NSSet setWithArray:@[
            p(S(progressTintColor), ISStyleSheetPropertyTypeColor),
            p(S(progressImage), ISStyleSheetPropertyTypeImage),
            pe(S(progressViewStyle), @{@"default" : @(UIProgressViewStyleDefault), @"bar" : @(UIProgressViewStyleBar)}),
            p(S(trackTintColor), ISStyleSheetPropertyTypeColor),
            p(S(trackImage), ISStyleSheetPropertyTypeImage),
    ]];
    allProperties = [allProperties setByAddingObjectsFromSet:progressViewProperties];


    NSSet* minimalTextInputProperties = [NSSet setWithArray:@[
            p(S(autocapitalizationType), ISStyleSheetPropertyTypeBool),
            pe(S(autocorrectionType), @{@"default" : @(UITextAutocorrectionTypeDefault), @"no" : @(UITextAutocorrectionTypeNo), @"yes" : @(UITextAutocorrectionTypeYes)}),
            pe(S(spellCheckingType), @{@"default" : @(UITextSpellCheckingTypeDefault), @"no" : @(UITextSpellCheckingTypeNo), @"yes" : @(UITextSpellCheckingTypeYes)}),
            pe(S(keyboardType), @{@"default" : @(UIKeyboardTypeDefault), @"alphabet" : @(UIKeyboardTypeAlphabet), @"asciiCapable" : @(UIKeyboardTypeASCIICapable),
                    @"decimalPad" : @(UIKeyboardTypeDecimalPad), @"emailAddress" : @(UIKeyboardTypeEmailAddress), @"namePhonePad" : @(UIKeyboardTypeNamePhonePad),
                    @"numberPad" : @(UIKeyboardTypeNumberPad), @"numbersAndPunctuation" : @(UIKeyboardTypeNumbersAndPunctuation), @"phonePad" : @(UIKeyboardTypePhonePad),
                    @"twitter" : @(UIKeyboardTypeTwitter), @"URL" : @(UIKeyboardTypeURL), @"webSearch" : @(UIKeyboardTypeWebSearch)})
            ]];

    NSSet* textInputProperties = [NSSet setWithArray:@[
            p(S(enablesReturnKeyAutomatically), ISStyleSheetPropertyTypeBool),
            pe(S(keyboardAppearance), @{@"default" : @(UIKeyboardAppearanceDefault), @"alert" : @(UIKeyboardAppearanceAlert),
                    @"dark" : @(UIKeyboardAppearanceDark), @"light" : @(UIKeyboardAppearanceLight)}),

            pe(S(returnKeyType), @{@"default" : @(UIReturnKeyDefault), @"go" : @(UIReturnKeyGo), @"google" : @(UIReturnKeyGoogle), @"join" : @(UIReturnKeyJoin),
                                                    @"next" : @(UIReturnKeyNext), @"route" : @(UIReturnKeyRoute), @"search" : @(UIReturnKeySearch), @"send" : @(UIReturnKeySend),
                                                    @"yahoo" : @(UIReturnKeyYahoo), @"done" : @(UIReturnKeyDone), @"emergencyCall" : @(UIReturnKeyEmergencyCall)}),
            p(@"secureTextEntry", ISStyleSheetPropertyTypeBool),
            p(S(clearsOnInsertion), ISStyleSheetPropertyTypeBool),
            p(S(placeholder), ISStyleSheetPropertyTypeString),
            p(S(text), ISStyleSheetPropertyTypeString)
        ]];
    textInputProperties = [textInputProperties setByAddingObjectsFromSet:minimalTextInputProperties];
    allProperties = [allProperties setByAddingObjectsFromSet:textInputProperties];

    NSSet* textFieldProperties = [NSSet setWithArray:@[
            p(S(clearsOnBeginEditing), ISStyleSheetPropertyTypeBool),
            pe(S(borderStyle), @{@"none" : @(UITextBorderStyleNone), @"bezel" : @(UITextBorderStyleBezel), @"line" : @(UITextBorderStyleLine), @"roundedRect" : @(UITextBorderStyleRoundedRect)}),
            p(S(background), ISStyleSheetPropertyTypeImage),
            p(S(disabledBackground), ISStyleSheetPropertyTypeImage)
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:textFieldProperties];

    textFieldProperties = [textFieldProperties setByAddingObjectsFromSet:textProperties];
    textFieldProperties = [textFieldProperties setByAddingObjectsFromSet:textInputProperties];
    textFieldProperties = [textFieldProperties setByAddingObjectsFromSet:resizableTextProperties];


    NSSet* textViewProperties = [NSSet setWithArray:@[
            p(S(allowsEditingTextAttributes), ISStyleSheetPropertyTypeBool),
            peo(S(dataDetectorTypes), dataDetectorTypesValues),
            p(@"editable", ISStyleSheetPropertyTypeBool),
            p(@"selectable", ISStyleSheetPropertyTypeBool),
            p(S(textContainerInset), ISStyleSheetPropertyTypeEdgeInsets)
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:textViewProperties];

    textViewProperties = [textViewProperties setByAddingObjectsFromSet:textProperties];
    textViewProperties = [textViewProperties setByAddingObjectsFromSet:textInputProperties];


    NSSet*imageViewProperties = [NSSet setWithArray:@[
            image,
            p(S(highlightedImage), ISStyleSheetPropertyTypeImage)
        ]];
    allProperties = [allProperties setByAddingObjectsFromSet:imageViewProperties];


    NSSet* switchProperties = [NSSet setWithArray:@[
            p(S(onTintColor), ISStyleSheetPropertyTypeColor),
            p(S(thumbTintColor), ISStyleSheetPropertyTypeColor),
            p(S(onImage), ISStyleSheetPropertyTypeImage),
            p(S(offImage), ISStyleSheetPropertyTypeImage)
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:switchProperties];


    NSSet* sliderProperties = [NSSet setWithArray:@[
            p(S(minimumValueImage), ISStyleSheetPropertyTypeImage),
            p(S(maximumValueImage), ISStyleSheetPropertyTypeImage),
            p(S(minimumTrackTintColor), ISStyleSheetPropertyTypeColor),
            p(S(maximumTrackTintColor), ISStyleSheetPropertyTypeColor),
            p(S(thumbTintColor), ISStyleSheetPropertyTypeColor),
            pp(@"maximumTrackImage", controlStateParametersValues, ISStyleSheetPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                [viewObject setMaximumTrackImage:value forState:state];
            }),
            pp(@"minimumTrackImage", controlStateParametersValues, ISStyleSheetPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                [viewObject setMinimumTrackImage:value forState:state];
            }),
            pp(@"thumbImage", controlStateParametersValues, ISStyleSheetPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                [viewObject setThumbImage:value forState:state];
            }),
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:sliderProperties];


    NSSet* stepperProperties = [NSSet setWithArray:@[
            p(@"continuous", ISStyleSheetPropertyTypeBool),
            p(S(autorepeat), ISStyleSheetPropertyTypeBool),
            p(S(wraps), ISStyleSheetPropertyTypeBool),
            p(S(minimumValue), ISStyleSheetPropertyTypeNumber),
            p(S(maximumValue), ISStyleSheetPropertyTypeNumber),
            p(S(stepValue), ISStyleSheetPropertyTypeNumber),
            backgroundImage,
            pp(@"decrementImage", controlStateParametersValues, ISStyleSheetPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                [viewObject setDecrementImage:value forState:state];
            }),
            pp(@"incrementImage", controlStateParametersValues, ISStyleSheetPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                [viewObject setIncrementImage:value forState:state];
            }),
            pp(@"dividerImage", controlStateParametersValues, ISStyleSheetPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                if( parameters.count > 1 ) {
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
            p(S(apportionsSegmentWidthsByContent), ISStyleSheetPropertyTypeBool),
            backgroundImage,
            pp(@"contentPositionAdjustment", barMetricsSegmentAndControlStateParameters, ISStyleSheetPropertyTypeOffset, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                if( parameters.count > 0 ) {
                    UISegmentedControlSegment segment = parameters.count > 0 ? (UISegmentedControlSegment)[parameters[0] integerValue] : UISegmentedControlSegmentAny;
                    UIBarMetrics metrics = parameters.count > 1 ? (UIBarMetrics)[parameters[1] integerValue] : UIBarMetricsDefault;
                    [viewObject setContentPositionAdjustment:[value UIOffsetValue] forSegmentType:segment barMetrics:metrics];
                }
            }),
            pp(@"dividerImage", barMetricsSegmentAndControlStateParameters, ISStyleSheetPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                if( parameters.count > 1 ) {
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
            p(@"enabled", ISStyleSheetPropertyTypeBool),
            p(S(title), ISStyleSheetPropertyTypeString),
            image,
            p(S(landscapeImagePhone), ISStyleSheetPropertyTypeImage),
            p(S(imageInsets), ISStyleSheetPropertyTypeEdgeInsets),
            p(S(landscapeImagePhoneInsets), ISStyleSheetPropertyTypeEdgeInsets),
            pe(S(style), @{@"plain" : @(UIBarButtonItemStylePlain), @"bordered" : @(UIBarButtonItemStyleBordered),
                                @"done" : @(UIBarButtonItemStyleDone)}),
            p(S(width), ISStyleSheetPropertyTypeNumber),
            backgroundImage,
            pp(@"backgroundVerticalPositionAdjustment", barMetricsParameters, ISStyleSheetPropertyTypeOffset, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIBarMetrics metrics = parameters.count > 0 ? (UIBarMetrics) [parameters[0] integerValue] : UIBarMetricsDefault;
                [viewObject setBackgroundVerticalPositionAdjustment:[value floatValue] forBarMetrics:metrics];
            }),
            titlePositionAdjustment,
            pp(@"backButtonBackgroundImage", barMetricsAndControlStateParameters, ISStyleSheetPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState state = parameters.count > 0 ? (UIControlState) [parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                UIBarMetrics metrics = parameters.count > 1 ? (UIBarMetrics) [parameters[1] integerValue] : UIBarMetricsDefault;
                [viewObject setBackButtonBackgroundImage:value forState:state barMetrics:metrics];
            }),
            pp(@"backButtonBackgroundVerticalPositionAdjustment", barMetricsParameters, ISStyleSheetPropertyTypeOffset, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIBarMetrics metrics = parameters.count > 0 ? (UIBarMetrics) [parameters[0] integerValue] : UIBarMetricsDefault;
                [viewObject setBackButtonBackgroundVerticalPositionAdjustment:[value floatValue] forBarMetrics:metrics];
            }),
            pp(@"backButtonTitlePositionAdjustment", barMetricsParameters, ISStyleSheetPropertyTypeOffset, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIBarMetrics metrics = parameters.count > 0 ? (UIBarMetrics) [parameters[0] integerValue] : UIBarMetricsDefault;
                [viewObject setBackButtonTitlePositionAdjustment:[value UIOffsetValue] forBarMetrics:metrics];
            }),
    ]];

    allProperties = [allProperties setByAddingObjectsFromSet:barButtonProperties];
    barButtonProperties = [barButtonProperties setByAddingObjectsFromSet:statefulTitleTextAttributes];


    NSDictionary* accessoryTypes = @{@"none" : @(UITableViewCellAccessoryNone), @"checkmark" : @(UITableViewCellAccessoryCheckmark), @"detailButton" : @(UITableViewCellAccessoryDetailButton),
                        @"disclosureButton" : @(UITableViewCellAccessoryDetailDisclosureButton), @"disclosureIndicator" : @(UITableViewCellAccessoryDisclosureIndicator)};

    NSSet* tableViewCellProperties = [NSSet setWithArray:@[
            pe(S(selectionStyle), @{@"none" : @(UITableViewCellSelectionStyleNone), @"default" : @(UITableViewCellSelectionStyleDefault), @"blue" : @(UITableViewCellSelectionStyleBlue), @"gray" : @(UITableViewCellSelectionStyleGray)}),
            p(@"selected", ISStyleSheetPropertyTypeBool),
            p(@"highlighted", ISStyleSheetPropertyTypeBool),
            pe(S(selectionStyle), @{@"none" : @(UITableViewCellEditingStyleNone), @"delete" : @(UITableViewCellEditingStyleDelete), @"insert" : @(UITableViewCellEditingStyleInsert)}),
            p(S(showsReorderControl), ISStyleSheetPropertyTypeBool),
            p(S(shouldIndentWhileEditing), ISStyleSheetPropertyTypeBool),
            pe(S(accessoryType), accessoryTypes),
            pe(S(editingAccessoryType), accessoryTypes),
            p(S(indentationLevel), ISStyleSheetPropertyTypeNumber),
            p(S(indentationWidth), ISStyleSheetPropertyTypeNumber),
            p(S(separatorInset), ISStyleSheetPropertyTypeEdgeInsets),
            p(@"editing", ISStyleSheetPropertyTypeBool)
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
            p(S(backIndicatorImage), ISStyleSheetPropertyTypeImage),
            p(S(backIndicatorTransitionMaskImage), ISStyleSheetPropertyTypeImage)
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:navigationBarProperties];
    navigationBarProperties = [navigationBarProperties setByAddingObjectsFromSet:statefulTitleTextAttributes];


    NSDictionary* searchBarIconParameters = @{@"iconBookmark" : @(UISearchBarIconBookmark), @"iconClear" : @(UISearchBarIconClear),
                    @"iconResultsList" : @(UISearchBarIconResultsList), @"iconSearch" : @(UISearchBarIconSearch)};
    NSMutableDictionary* statefulSearchBarIconParameters = [NSMutableDictionary dictionaryWithDictionary:searchBarIconParameters];
    [statefulSearchBarIconParameters addEntriesFromDictionary:controlStateParametersValues];

    NSSet* searchBarProperties = [NSSet setWithArray:@[
            barStyle,
            p(S(text), ISStyleSheetPropertyTypeString),
            p(S(prompt), ISStyleSheetPropertyTypeString),
            p(S(placeholder), ISStyleSheetPropertyTypeString),
            p(S(showsBookmarkButton), ISStyleSheetPropertyTypeBool),
            p(S(showsCancelButton), ISStyleSheetPropertyTypeBool),
            p(S(showsSearchResultsButton), ISStyleSheetPropertyTypeBool),
            p(@"searchResultsButtonSelected", ISStyleSheetPropertyTypeBool),
            barTintColor,
            pe(S(searchBarStyle), @{@"default" : @(UISearchBarStyleDefault), @"minimal" : @(UISearchBarStyleMinimal), @"prominent" : @(UISearchBarStyleProminent)}),
            translucent,
            p(S(showsScopeBar), ISStyleSheetPropertyTypeBool),
            p(S(scopeBarBackgroundImage), ISStyleSheetPropertyTypeImage),
            backgroundImage,
            pp(@"searchFieldBackgroundImage", controlStateParametersValues, ISStyleSheetPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                [viewObject setSearchFieldBackgroundImage:value forState:state];
            }),
            pp(@"imageForSearchBarIcon", statefulSearchBarIconParameters, ISStyleSheetPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UISearchBarIcon icon = parameters.count > 0 ? (UISearchBarIcon)[parameters[0] integerValue] : UISearchBarIconSearch;
                UIControlState state = parameters.count > 1 ? (UIControlState)[parameters[1] unsignedIntegerValue] : UIControlStateNormal;
                [viewObject setImage:value forSearchBarIcon:icon state:state];
            }),
            pp(@"scopeBarButtonBackgroundImage", controlStateParametersValues, ISStyleSheetPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                [viewObject setScopeBarButtonBackgroundImage:value forState:state];
            }),
            pp(@"scopeBarButtonDividerImage", controlStateParametersValues, ISStyleSheetPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UIControlState leftState = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                UIControlState rightState = parameters.count > 1 ? (UIControlState)[parameters[1] unsignedIntegerValue] : UIControlStateNormal;
                [viewObject setScopeBarButtonDividerImage:value forLeftSegmentState:leftState rightSegmentState:rightState];
            }),
            pp(@"scopeBarButtonTitleFont", controlStateParametersValues, ISStyleSheetPropertyTypeFont, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                setTitleTextAttributes(viewObject, value, parameters, UITextAttributeFont);
            }),
            pp(@"scopeBarButtonTitleTextColor", controlStateParametersValues, ISStyleSheetPropertyTypeColor, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                setTitleTextAttributes(viewObject, value, parameters, UITextAttributeTextColor);
            }),
            pp(@"scopeBarButtonTitleShadowColor", controlStateParametersValues, ISStyleSheetPropertyTypeColor, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                setTitleTextAttributes(viewObject, value, parameters, UITextAttributeTextShadowColor);
            }),
            pp(@"scopeBarButtonTitleShadowOffset", controlStateParametersValues, ISStyleSheetPropertyTypeOffset, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                setTitleTextAttributes(viewObject, value, parameters, UITextAttributeTextShadowOffset);
            }),
            p(S(searchFieldBackgroundPositionAdjustment), ISStyleSheetPropertyTypeOffset),
            p(S(searchTextPositionAdjustment), ISStyleSheetPropertyTypeOffset),
            pp(@"positionAdjustmentForSearchBarIcon", searchBarIconParameters, ISStyleSheetPropertyTypeImage, ^(ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters) {
                UISearchBarIcon icon = parameters.count > 0 ? (UISearchBarIcon)[parameters[0] integerValue] : UISearchBarIconSearch;
                [viewObject setPositionAdjustment:[value UIOffsetValue] forSearchBarIcon:icon];
            })
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:searchBarProperties];
    searchBarProperties = [searchBarProperties setByAddingObjectsFromSet:minimalTextInputProperties];


    NSSet* tabBarProperties = [NSSet setWithArray:@[
            barTintColor,
            p(S(selectedImageTintColor), ISStyleSheetPropertyTypeColor),
            backgroundImage,
            p(S(selectionIndicatorImage), ISStyleSheetPropertyTypeImage),
            shadowImage,
            pe(S(itemPositioning), @{@"automatic" : @(UITabBarItemPositioningAutomatic), @"centered" : @(UITabBarItemPositioningCentered), @"fill" : @(UITabBarItemPositioningFill)}),
            p(S(itemWidth), ISStyleSheetPropertyTypeNumber),
            p(S(itemSpacing), ISStyleSheetPropertyTypeNumber),
            barStyle,
            translucent
        ]];

    NSSet* tabBarItemProperties = [NSSet setWithArray:@[
            p(S(selectedImage), ISStyleSheetPropertyTypeImage),
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
    for(Class clazz in classProperties.allKeys) {
        if( clazz != UIView.class ) {
            _classesToNames[resistanceIsFutile clazz] = [[clazz description] lowercaseString];
        }
    }
    _classesToNames[resistanceIsFutile UIWindow.class] = @"uiwindow";
    classesToNames = _classesToNames;
}



@end