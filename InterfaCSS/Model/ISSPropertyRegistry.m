//
//  InterfaCSS
//  ISSPropertyRegistry.m
//  
//  Created by Tobias Löfstrand on 2014-10-03.
//  Copyright (c) 2014 Leafnode AB. All rights reserved.
//

#import "ISSPropertyRegistry.h"

#import "NSString+ISSStringAdditions.h"
#import "NSObject+ISSLogSupport.h"
#import "InterfaCSS.h"
#import "NSAttributedString+ISSAdditions.h"
#import "ISSPointValue.h"
#import "ISSRectValue.h"
#import "ISSUIElementDetails.h"
#import "ISSRuntimeIntrospectionUtils.h"


#define S(selName) NSStringFromSelector(@selector(selName))
#define SLC(selName) [S(selName) lowercaseString]
#define resistanceIsFutile (id <NSCopying>)
#define SetterBlockParamList ISSPropertyDefinition* p, id viewObject, id value, NSArray* parameters


#pragma mark - Convenience/shorthand functions

static ISSPropertyDefinition* p(NSString* name, ISSPropertyType type) {
    return [[ISSPropertyDefinition alloc] initWithName:name type:type];
}

static ISSPropertyDefinition* pi(NSString* name, ISSPropertyType type) {
    return [[ISSPropertyDefinition alloc] initWithName:name type:type useIntrospection:YES];
}

static ISSPropertyDefinition* ps(NSString* name, ISSPropertyType type, ISSPropertySetterBlock setterBlock) {
    return [[ISSPropertyDefinition alloc] initWithName:name aliases:nil type:type enumValues:nil
                                          enumBitMaskType:NO setterBlock:setterBlock parameterEnumValues:nil useIntrospection:NO];
}

static ISSPropertyDefinition* pa(NSString* name, NSArray* aliases, ISSPropertyType type) {
    return [[ISSPropertyDefinition alloc] initWithName:name aliases:aliases type:type];
}

static ISSPropertyDefinition* pas(NSString* name, NSArray* aliases, ISSPropertyType type, ISSPropertySetterBlock setterBlock) {
    return [[ISSPropertyDefinition alloc] initWithName:name aliases:aliases type:type enumValues:nil
                                          enumBitMaskType:NO setterBlock:setterBlock parameterEnumValues:nil useIntrospection:NO];
}

static ISSPropertyDefinition* pe(NSString* name, NSDictionary* enumValues) {
    return [[ISSPropertyDefinition alloc] initWithName:name aliases:nil type:ISSPropertyTypeEnumType enumValues:enumValues enumBitMaskType:NO];
}

static ISSPropertyDefinition* pei(NSString* name, NSDictionary* enumValues) {
    return [[ISSPropertyDefinition alloc] initWithName:name aliases:nil type:ISSPropertyTypeEnumType enumValues:enumValues enumBitMaskType:NO setterBlock:nil parameterEnumValues:nil useIntrospection:YES];
}

static ISSPropertyDefinition* pea(NSString* name, NSArray* aliases, NSDictionary* enumValues) {
    return [[ISSPropertyDefinition alloc] initWithName:name aliases:aliases type:ISSPropertyTypeEnumType enumValues:enumValues enumBitMaskType:NO];
}

static ISSPropertyDefinition* peo(NSString* name, NSDictionary* enumValues) {
    return [[ISSPropertyDefinition alloc] initWithName:name aliases:nil type:ISSPropertyTypeEnumType enumValues:enumValues enumBitMaskType:YES setterBlock:nil parameterEnumValues:nil];
}

static ISSPropertyDefinition* peos(NSString* name, NSDictionary* enumValues, ISSPropertySetterBlock setterBlock) {
    return [[ISSPropertyDefinition alloc] initWithName:name aliases:nil type:ISSPropertyTypeEnumType enumValues:enumValues enumBitMaskType:YES setterBlock:setterBlock parameterEnumValues:nil useIntrospection:NO];
}

static ISSPropertyDefinition* pp(NSString* name, NSDictionary* paramValues, ISSPropertyType type, ISSPropertySetterBlock setterBlock) {
    return [[ISSPropertyDefinition alloc] initWithName:name aliases:nil type:type enumValues:nil
                                      enumBitMaskType:NO setterBlock:setterBlock parameterEnumValues:paramValues useIntrospection:NO];
}

static ISSPropertyDefinition* pap(NSString* name, NSArray* aliases, NSDictionary* paramValues, ISSPropertyType type, ISSPropertySetterBlock setterBlock) {
    return [[ISSPropertyDefinition alloc] initWithName:name aliases:aliases type:type enumValues:nil
                                      enumBitMaskType:NO setterBlock:setterBlock parameterEnumValues:paramValues useIntrospection:NO];
}

static BOOL setTitleTextAttributes(id viewObject, id value, NSArray* parameters, NSString* attrName) {
    UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
    NSMutableDictionary* attrs = nil;
    if( [viewObject respondsToSelector:@selector(scopeBarButtonTitleTextAttributesForState:)] ) attrs = [NSMutableDictionary dictionaryWithDictionary:[viewObject scopeBarButtonTitleTextAttributesForState:state]];
    else if( [viewObject respondsToSelector:@selector(titleTextAttributesForState:)] ) attrs = [NSMutableDictionary dictionaryWithDictionary:[viewObject titleTextAttributesForState:state]];
    else if( [viewObject respondsToSelector:@selector(titleTextAttributes)] ) attrs = [NSMutableDictionary dictionaryWithDictionary:[viewObject titleTextAttributes]];

    BOOL success = YES;
    attrs[attrName] = value;
    if( [viewObject isKindOfClass:UISearchBar.class] ) [viewObject setScopeBarButtonTitleTextAttributes:attrs forState:state];
    else if( [viewObject respondsToSelector:@selector(setTitleTextAttributes:forState:)] ) [viewObject setTitleTextAttributes:attrs forState:state];
    else if( [viewObject respondsToSelector:@selector(setTitleTextAttributes:)] ) [viewObject setTitleTextAttributes:attrs];
    else success = NO;

    return success;
}



#pragma mark - ISSPropertyRegistry


@interface ISSPropertyRegistry ()

@property (nonatomic, strong, readwrite) NSSet* propertyDefinitions;
@property (nonatomic, strong, readwrite) NSDictionary* validPrefixKeyPaths;
@property (nonatomic, strong, readwrite) NSDictionary* validPrefixKeyPathsForClass;
@property (nonatomic, strong, readwrite) NSDictionary* typePropertyDefinitions;

@property (nonatomic, strong) NSDictionary* classesToTypeNames;
@property (nonatomic, strong) NSDictionary* typeNamesToClasses;
@property (nonatomic, strong, readwrite) NSDictionary* propertyDefinitionsForClass;

@end


@implementation ISSPropertyRegistry

- (NSSet*) propertyDefinitionsForType:(ISSPropertyType)propertyType {
    return [self.propertyDefinitions filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary* bindings) {
        return ((ISSPropertyDefinition*)evaluatedObject).type == propertyType;
    }]];
}

- (NSSet*) propertyDefinitionsForViewClass:(Class)viewClass {
    NSMutableSet* viewClassProperties = [[NSMutableSet alloc] init];
    for(Class clazz in self.propertyDefinitionsForClass.allKeys) {
        if( [viewClass isSubclassOfClass:clazz] ) {
            [viewClassProperties unionSet:self.propertyDefinitionsForClass[clazz]];
        }
    }
    return viewClassProperties;
}

- (ISSPropertyDefinition*) propertyDefinitionForProperty:(NSString*)propertyName inClass:(Class)viewClass {
    NSSet* properties = [self propertyDefinitionsForViewClass:viewClass];
    for(ISSPropertyDefinition* property in properties) {
        if( [property.allNames containsObject:[propertyName lowercaseString]] ) return property;
    }
    return nil;
}

- (NSSet*) typePropertyDefinitions:(ISSPropertyType)propertyType {
    return self.typePropertyDefinitions[@(propertyType)];
}

- (NSString*) canonicalTypeForClass:(Class)clazz {
    NSString* type = self.classesToTypeNames[clazz];
    if( type ) return type;
    else { // Custom view class or "unsupported" UIKit view class
        Class superClass = [clazz superclass];
        if( superClass && superClass != NSObject.class ) return [self canonicalTypeForClass:superClass];
        else return nil;
    }
}

- (Class) canonicalTypeClassForClass:(Class)clazz {
    if( self.classesToTypeNames[clazz] ) return clazz;
    else { // Custom view class or "unsupported" UIKit view class
        Class superClass = [clazz superclass];
        if( superClass && superClass != NSObject.class ) return [self canonicalTypeClassForClass:superClass];
        else return nil;
    }
}

- (Class) canonicalTypeClassForType:(NSString*)type {
    return [self canonicalTypeClassForType:type registerIfNotFound:NO];
}

- (Class) canonicalTypeClassForType:(NSString*)type registerIfNotFound:(BOOL)registerIfNotFound {
    NSString* uiKitClassName = [type lowercaseString];
    if( ![uiKitClassName hasPrefix:@"ui"] ) {
        uiKitClassName = [@"ui" stringByAppendingString:uiKitClassName];
    }

    Class clazz = self.typeNamesToClasses[uiKitClassName];
    if( !clazz ) {
        clazz = self.typeNamesToClasses[[type lowercaseString]]; // If not UIKit class - see if it is a custom class (typeNamesToClasses always uses lowecase keys)
    }
    if( !clazz && registerIfNotFound ) {
        // If type doesn't match a registered class name, try to see if the type is a valid class...
        clazz = NSClassFromString(type);
        if( clazz ) {
            // ...and if it is - register it as a canonical type (keep case)
            [self registerCanonicalTypeClass:clazz];
        }
    }
    return clazz;
}

- (void) registerCanonicalTypeClass:(Class)clazz {
    NSString* type = [NSStringFromClass(clazz) lowercaseString];

    NSMutableDictionary* temp = [NSMutableDictionary dictionaryWithDictionary:self.typeNamesToClasses];
    temp[type] = clazz;
    self.typeNamesToClasses = [NSDictionary dictionaryWithDictionary:temp];

    temp = [NSMutableDictionary dictionaryWithDictionary:self.classesToTypeNames];
    temp[resistanceIsFutile clazz] = type;
    self.classesToTypeNames = [NSDictionary dictionaryWithDictionary:temp];

    // Reset all cached data ISSUIElementDetails, since canonical type class may have changed for some elements
    [ISSUIElementDetails resetAllCachedData];
}

- (ISSPropertyDefinition*) registerCustomProperty:(NSString*)propertyName propertyType:(ISSPropertyType)propertyType {
    ISSPropertyDefinition* propertyDefinition = [[ISSPropertyDefinition alloc] initWithName:propertyName type:propertyType];
    [self registerCustomProperty:propertyDefinition];
    return propertyDefinition;
}

- (void) registerCustomProperty:(ISSPropertyDefinition*)propertyDefinition {
    if( propertyDefinition ) {
        ISSPropertyDefinition* existingDefinition = [self.propertyDefinitions member:propertyDefinition];
        propertyDefinition.overriddenDefinition = existingDefinition;
        
        NSMutableSet* updatedPropertyDefinitions = [NSMutableSet setWithSet:self.propertyDefinitions];
        if( existingDefinition ) {
            [updatedPropertyDefinitions removeObject:existingDefinition]; // Remove any existing definition, to allow it to be replaced
        }
        [updatedPropertyDefinitions addObject:propertyDefinition];
        self.propertyDefinitions = [updatedPropertyDefinitions copy];
        
        // Update propertyDefinitionsForClass - TODO: Review storage for property defs...
        NSMutableDictionary* updatedPropertyDefinitionsForClass = [NSMutableDictionary dictionaryWithDictionary:self.propertyDefinitionsForClass];
        for(Class clazz in self.propertyDefinitionsForClass.allKeys) {
            NSSet* typeProperties = self.propertyDefinitionsForClass[clazz];
            
            if( [typeProperties containsObject:propertyDefinition] ) {
                NSMutableSet* updatedTypeProperties = [NSMutableSet setWithSet:typeProperties];
                if( existingDefinition ) {
                    [updatedTypeProperties removeObject:existingDefinition]; // Remove any existing definition, to allow it to be replaced
                }
                [updatedTypeProperties addObject:propertyDefinition];
                updatedPropertyDefinitionsForClass[resistanceIsFutile(clazz)] = [updatedTypeProperties copy];
            }
        }
        self.propertyDefinitionsForClass = [updatedPropertyDefinitionsForClass copy];
    }
}

- (void) registerValidPrefixKeyPath:(NSString*)prefix {
    if( ![prefix iss_hasData] ) return;
    NSMutableDictionary* temp = [NSMutableDictionary dictionaryWithDictionary:self.validPrefixKeyPaths];
    temp[prefix.lowercaseString] = prefix;
    self.validPrefixKeyPaths = [temp copy];

    // Reset all cached data ISSUIElementDetails, since valid prefix key paths may have changed for some elements
    [ISSUIElementDetails resetAllCachedData];
}

- (void) registerValidPrefixKeyPaths:(NSArray*)prefixes {
    NSMutableDictionary* temp = [NSMutableDictionary dictionaryWithDictionary:self.validPrefixKeyPaths];
    for(NSString* prefix in prefixes) {
        if( [prefix iss_hasData] ) temp[prefix.lowercaseString] = prefix;
    }
    self.validPrefixKeyPaths = [temp copy];

    // Reset all cached data ISSUIElementDetails, since valid prefix key paths may have changed for some elements
    [ISSUIElementDetails resetAllCachedData];
}

- (NSSet*) validPrefixKeyPathsForClass:(Class)clazz {
    NSString* className = NSStringFromClass(clazz);
    NSMutableSet* validKeyPathsForClass = self.validPrefixKeyPathsForClass[className];
    if( !validKeyPathsForClass ) {
        validKeyPathsForClass = [NSMutableSet set];
        
        for(NSString* keyPath in self.validPrefixKeyPaths.allValues) {
            NSString* validKeyPathForClass = [ISSRuntimeIntrospectionUtils validKeyPathForCaseInsensitivePath:keyPath inClass:clazz];
            if( validKeyPathForClass ) [validKeyPathsForClass addObject:validKeyPathForClass];
        }
        
        NSMutableDictionary* temp = self.validPrefixKeyPathsForClass ? [NSMutableDictionary dictionaryWithDictionary:self.validPrefixKeyPathsForClass] : [NSMutableDictionary dictionary];
        temp[className] = validKeyPathsForClass;
        self.validPrefixKeyPathsForClass = temp;
    }
    return validKeyPathsForClass;
}

#if DEBUG == 1
- (NSString*) propertyDescriptionsForMarkdown {
    NSMutableString* string = [NSMutableString string];

    NSMutableArray* classes = [[NSMutableArray alloc] init];
    for(Class clazz in self.propertyDefinitionsForClass.allKeys) {
        if( clazz != UIView.class ) [classes addObject:clazz];
    }
    [classes sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 description] compare:[obj2 description]];
    }];
    [classes insertObject:[UIView class] atIndex:0];

    for(Class clazz in classes) {
        [string appendFormat:@"\n###%@ \n", [clazz description]];

        NSArray* properties = [self.propertyDefinitionsForClass[clazz] allObjects];

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


#pragma mark - initialization - setup of property definitions

- (instancetype) init {
    if( self = [super init] ) {
        [self initializeRegistry];
    }
    return self;
}

- (void) initializeRegistry {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

    // Setup default valid nested element names (property prefix key paths)
    self.validPrefixKeyPaths = @{ SLC(layer) : S(layer), SLC(imageView) : S(imageView), SLC(contentView) : S(contentView), SLC(backgroundView) : S(backgroundView),
            SLC(selectedBackgroundView) : S(selectedBackgroundView), SLC(multipleSelectionBackgroundView) : S(multipleSelectionBackgroundView), SLC(titleLabel) : S(titleLabel),
            SLC(textLabel) : S(textLabel), SLC(detailTextLabel) : S(detailTextLabel), SLC(inputView) : S(inputView), SLC(inputAccessoryView) : S(inputAccessoryView),
            SLC(tableHeaderView) : S(tableHeaderView), SLC(tableFooterView) : S(tableFooterView), SLC(backgroundView) : S(backgroundView), SLC(customView) : S(customView)};
    

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


#pragma mark - Common properties

    ISSPropertyDefinition* backgroundImage = pp(S(backgroundImage), barMetricsPositionAndControlStateParameters, ISSPropertyTypeImage, ^(SetterBlockParamList) {
        UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
        UIBarPosition position = parameters.count > 0 ? (UIBarPosition)[parameters[0] unsignedIntegerValue] : UIBarPositionAny;
        UIBarMetrics metrics = parameters.count > 1 ? (UIBarMetrics)[parameters[1] integerValue] : UIBarMetricsDefault;

        BOOL success = YES;
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
        } else {
            success = NO;
        }
        return success;
    });

    ISSPropertyDefinition* image = pp(S(image), controlStateParametersValues, ISSPropertyTypeImage, ^(SetterBlockParamList) {
        BOOL success = YES;
        UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
        if( [viewObject respondsToSelector:@selector(setImage:forState:)] ) {
            [viewObject setImage:value forState:state];
        } else if( [viewObject respondsToSelector:@selector(setImage:)] ) {
            [viewObject setImage:value];
        } else {
            success = NO;
        }
        return success;
    });

    ISSPropertyDefinition* shadowImage = pp(S(shadowImage), barPositionParameters, ISSPropertyTypeImage, ^(SetterBlockParamList) {
        BOOL success = YES;
        if( [viewObject respondsToSelector:@selector(setShadowImage:forToolbarPosition:)] ) {
            UIBarPosition position = parameters.count > 0 ? (UIBarPosition) [parameters[0] unsignedIntegerValue] : UIBarPositionAny;
            [viewObject setShadowImage:value forToolbarPosition:position];
        } else if( [viewObject respondsToSelector:@selector(setShadowImage:)] ) {
            [viewObject setShadowImage:value];
        } else {
            success = NO;
        }
        return success;
    });

    ISSPropertyDefinition* title = pp(S(title), controlStateParametersValues, ISSPropertyTypeString, ^(SetterBlockParamList) {
        BOOL success = YES;
        UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
        if( [viewObject respondsToSelector:@selector(setTitle:forState:)] ) {
            [viewObject setTitle:value forState:state];
        } else if( [viewObject respondsToSelector:@selector(setTitle:)] ) {
            [viewObject setTitle:value];
        } else {
            success = NO;
        }
        return success;
    });

    ISSPropertyDefinition* attributedTitle = pp(S(attributedTitle), controlStateParametersValues, ISSPropertyTypeAttributedString, ^(SetterBlockParamList) {
        BOOL success = YES;
        UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
        if( [viewObject respondsToSelector:@selector(setAttributedTitle:forState:)] ) {
            [viewObject setAttributedTitle:value forState:state];
        } else if( [viewObject respondsToSelector:@selector(setAttributedTitle:)] ) {
            [viewObject setAttributedTitle:value];
        } else {
            success = NO;
        }
        return success;
    });

    ISSPropertyDefinition* text = p(S(text), ISSPropertyTypeString);
    ISSPropertyDefinition* attributedText = p(S(attributedText), ISSPropertyTypeAttributedString);
    ISSPropertyDefinition* prompt = p(S(prompt), ISSPropertyTypeString);
    ISSPropertyDefinition* placeholder = p(S(placeholder), ISSPropertyTypeString);

    ISSPropertyDefinition* font = pp(S(font), controlStateParametersValues, ISSPropertyTypeFont, ^(SetterBlockParamList) {
        if( [viewObject isKindOfClass:UIButton.class] ) {
            if( [InterfaCSS interfaCSS].preventOverwriteOfAttributedTextAttributes && [[viewObject currentAttributedTitle] iss_hasAttributes] ) {
                ISSLogTrace(@"NOT setting font for %@ - preventOverwriteOfAttributedTextAttributes is enabled", viewObject);
            } else {
                [viewObject titleLabel].font = value;
            }
        }
        else if( [viewObject respondsToSelector:@selector(setFont:)] ) {
            if( [InterfaCSS interfaCSS].preventOverwriteOfAttributedTextAttributes && [viewObject respondsToSelector:@selector(attributedText)]
                    && [[viewObject attributedText] iss_hasAttributes] ) {
                ISSLogTrace(@"NOT setting font for %@ - preventOverwriteOfAttributedTextAttributes is enabled", viewObject);
            } else {
                [viewObject setFont:value];
            }
        }
        else {
            return setTitleTextAttributes(viewObject, value, parameters, NSFontAttributeName);
        }
        
        return YES;
    });

    ISSPropertySetterBlock uiButtonTitleColorBlock = ^(SetterBlockParamList) {
        BOOL success = YES;
        if( [InterfaCSS interfaCSS].preventOverwriteOfAttributedTextAttributes && [viewObject respondsToSelector:@selector(currentAttributedTitle)] &&
                [[viewObject currentAttributedTitle] iss_hasAttributes] ) {
            ISSLogTrace(@"NOT setting titleColor for %@ - preventOverwriteOfAttributedTextAttributes is enabled", viewObject);
        } else {
            UIControlState state = parameters.count > 0 ? (UIControlState) [parameters[0] unsignedIntegerValue] : UIControlStateNormal;
            if ( [viewObject respondsToSelector:@selector(setTitleColor:forState:)] ) [viewObject setTitleColor:value forState:state];
            else success = NO;
        }
        return success;
    };
    ISSPropertyDefinition* textColor = pp(S(textColor), controlStateParametersValues, ISSPropertyTypeColor, ^(SetterBlockParamList) {
        if( [viewObject isKindOfClass:UIButton.class] ) {
            // Let textColor be titleColor for UIButton...
            return uiButtonTitleColorBlock(p, viewObject, value, parameters);
        }
        else if( [viewObject respondsToSelector:@selector(setTextColor:)] ) {
            if( [InterfaCSS interfaCSS].preventOverwriteOfAttributedTextAttributes && [viewObject respondsToSelector:@selector(attributedText)]
                                && [[viewObject attributedText] iss_hasAttributes] ) {
                ISSLogTrace(@"NOT setting textColor for %@ - preventOverwriteOfAttributedTextAttributes is enabled", viewObject);
            } else {
                [viewObject setTextColor:value];
            }
            return YES;
        }
        else {
            return setTitleTextAttributes(viewObject, value, parameters, NSForegroundColorAttributeName);
        }
    });

    ISSPropertyDefinition* shadowColor = pap(@"layer.shadowColor", @[@"shadowcolor"], controlStateParametersValues, ISSPropertyTypeColor, ^(SetterBlockParamList) {
        if( [viewObject respondsToSelector:@selector(setShadowColor:)] ) {
            [viewObject setShadowColor:value]; // UILabel
        } else if( [viewObject respondsToSelector:@selector(layer)] && [[viewObject layer] respondsToSelector:@selector(setShadowColor:)] ) {
            [[viewObject layer] setShadowColor:[value CGColor]]; // UIView
        } else {
            return setTitleTextAttributes(viewObject, value, parameters, UITextAttributeTextShadowColor);
        }
        return YES;
    });

    ISSPropertyDefinition* shadowOffset = pap(@"layer.shadowOffset", @[@"shadowoffset"], controlStateParametersValues, ISSPropertyTypeSize, ^(SetterBlockParamList) {
        if( [viewObject respondsToSelector:@selector(setShadowOffset:)] ) {
            [viewObject setShadowOffset:[value CGSizeValue]];
        } else if( [viewObject respondsToSelector:@selector(layer)] && [[viewObject layer] respondsToSelector:@selector(setShadowOffset:)] ) {
            [[viewObject layer] setShadowOffset:[value CGSizeValue]];
        } else {
            return setTitleTextAttributes(viewObject, value, parameters, UITextAttributeTextShadowOffset);
        }
        return YES;
    });

    ISSPropertyDefinition* barTintColor = p(S(barTintColor), ISSPropertyTypeColor);

    ISSPropertyDefinition* barStyle = pe(S(barStyle), @{@"default" : @(UIBarStyleDefault), @"black" : @(UIBarStyleBlack), @"blackOpaque" : @(UIBarStyleBlackOpaque), @"blackTranslucent" : @(UIBarStyleBlackTranslucent)});

    ISSPropertyDefinition* translucent = p(@"translucent", ISSPropertyTypeBool);

    ISSPropertyDefinition* titlePositionAdjustment = pp(S(titlePositionAdjustment), barMetricsParameters, ISSPropertyTypeOffset, ^(SetterBlockParamList) {
        BOOL success = YES;
        if( [viewObject respondsToSelector:@selector(setTitlePositionAdjustment:forBarMetrics:)] ) {
            UIBarMetrics metrics = parameters.count > 0 ? (UIBarMetrics) [parameters[0] integerValue] : UIBarMetricsDefault;
            [viewObject setTitlePositionAdjustment:[value UIOffsetValue] forBarMetrics:metrics];
        } else if( [viewObject respondsToSelector:@selector(setTitlePositionAdjustment:)] ) {
            [viewObject setTitlePositionAdjustment:[value UIOffsetValue]];
        } else {
            success = NO;
        }
        return success;
    });

    ISSPropertyDefinition* allowsSelection = p(S(allowsSelection), ISSPropertyTypeBool);

    ISSPropertyDefinition* allowsMultipleSelection = p(S(allowsMultipleSelection), ISSPropertyTypeBool);
    
    ISSPropertyDefinition* dividerImage = pp(@"dividerImage", controlStateParametersValues, ISSPropertyTypeImage, ^(SetterBlockParamList) {
        UIControlState leftState = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
        UIControlState rightState = parameters.count > 1 ? (UIControlState)[parameters[1] unsignedIntegerValue] : UIControlStateNormal;
        if( [viewObject respondsToSelector:@selector(setDividerImage:forLeftSegmentState:rightSegmentState:barMetrics:)] ) {
            UIBarMetrics metrics = parameters.count > 2 ? (UIBarMetrics)[parameters[2] integerValue] : UIBarMetricsDefault;
            [viewObject setDividerImage:value forLeftSegmentState:leftState rightSegmentState:rightState barMetrics:metrics];
            return YES;
        } else if( [viewObject respondsToSelector:@selector(setDividerImage:forLeftSegmentState:rightSegmentState:)] ) {
            [viewObject setDividerImage:value forLeftSegmentState:(UIControlState)[parameters[0] unsignedIntegerValue] rightSegmentState:(UIControlState)[parameters[1] unsignedIntegerValue]];
            return YES;
        }
        return NO;
    });

    
#pragma mark - Setter blocks for UIView property definitions
    
    ISSPropertySetterBlock autoresizingMaskBlock = ^(SetterBlockParamList) {
        if( [viewObject isKindOfClass:UIView.class] ) {
            UIView* v = viewObject;
            // If frame is not set - set it to parent or screen bounds before setting the autoresizing mask
            if( CGRectIsEmpty(v.frame) ) {
                if( v.superview ) v.frame = v.superview.bounds;
                else v.frame = [UIScreen mainScreen].bounds;
            }
            v.autoresizingMask = (UIViewAutoresizing)[value unsignedIntegerValue];
            return YES;
        } else {
            return NO;
        }
    };
    
    ISSPropertySetterBlock boundsBlock = ^(SetterBlockParamList) {
        if( [viewObject isKindOfClass:UIView.class] ) {
            UIView* v = viewObject;
            v.bounds = [value rectForView:v];
            return YES;
        } else {
            return NO;
        }
    };
    
    ISSPropertySetterBlock centerBlock = ^(SetterBlockParamList) { // Value is ISSPointValue
        if( [viewObject isKindOfClass:UIView.class] ) {
            UIView* v = viewObject;
            // Handle case when attempting to set center point on transformed view
            CATransform3D t3d = v.layer.transform;
            CGAffineTransform t = v.transform;
            v.transform = CGAffineTransformIdentity;
            v.layer.transform = CATransform3DIdentity;
            v.center = [value pointForView:v];
            v.transform = t;
            v.layer.transform = t3d;
            return YES;
        } else {
            return NO;
        }
    };
    
    ISSPropertySetterBlock frameBlock = ^(SetterBlockParamList) { // Value is ISSRectValue
        if( [viewObject isKindOfClass:UIView.class] ) {
            UIView* v = viewObject;
            // Handle case when attempting to set frame on transformed view
            CATransform3D t3d = v.layer.transform;
            CGAffineTransform t = v.transform;
            v.transform = CGAffineTransformIdentity;
            v.layer.transform = CATransform3DIdentity;
            v.frame = [value rectForView:v];
            v.transform = t;
            v.layer.transform = t3d;
            return YES;
        } else {
            return NO;
        }
    };
    
    ISSPropertySetterBlock anchorPointBlock = ^(SetterBlockParamList) {
        if( [viewObject isKindOfClass:UIView.class] ) {
            UIView* v = viewObject;
            // Make sure original position is maintained when adjusting anchorPoint
            CGPoint initialOrigin = v.frame.origin;
            v.layer.anchorPoint = [value point];
            CGPoint delta = CGPointMake(v.frame.origin.x - initialOrigin.x, v.frame.origin.y - initialOrigin.y);
            v.center = CGPointMake (v.center.x - delta.x, v.center.y - delta.y);
            return YES;
        } else {
            return NO;
        }
    };
    
    ISSPropertySetterBlock layoutBlock = ^(SetterBlockParamList) {
        ISSUIElementDetails* details = [[InterfaCSS sharedInstance] detailsForUIElement:viewObject];
        details.layout = value;
        return YES;
    };
    
#pragma mark - UIView

    NSSet* viewProperties = [NSSet setWithArray:@[
            p(S(alpha), ISSPropertyTypeNumber),
            p(S(autoresizesSubviews), ISSPropertyTypeBool),
            peos(S(autoresizingMask), @{ @"none" : @(UIViewAutoresizingNone), @"width" : @(UIViewAutoresizingFlexibleWidth), @"height" : @(UIViewAutoresizingFlexibleHeight),
                                    @"bottom" : @(UIViewAutoresizingFlexibleBottomMargin), @"top" : @(UIViewAutoresizingFlexibleTopMargin),
                                    @"left" : @(UIViewAutoresizingFlexibleLeftMargin), @"right" : @(UIViewAutoresizingFlexibleRightMargin)}, autoresizingMaskBlock),
            p(S(backgroundColor), ISSPropertyTypeColor),
            ps(S(bounds), ISSPropertyTypeRect, boundsBlock),
            ps(S(center), ISSPropertyTypePoint, centerBlock),
            p(S(clearsContextBeforeDrawing), ISSPropertyTypeBool),
            p(S(clipsToBounds), ISSPropertyTypeBool),
            pe(S(contentMode), @{@"scaleToFill" : @(UIViewContentModeScaleToFill), @"scaleAspectFit" : @(UIViewContentModeScaleAspectFit),
                        @"scaleAspectFill" : @(UIViewContentModeScaleAspectFill), @"redraw" : @(UIViewContentModeRedraw), @"center" : @(UIViewContentModeCenter), @"top" : @(UIViewContentModeTop),
                        @"bottom" : @(UIViewContentModeBottom), @"left" : @(UIViewContentModeLeft), @"right" : @(UIViewContentModeRight), @"topLeft" : @(UIViewContentModeTopLeft),
                        @"topRight" : @(UIViewContentModeTopRight), @"bottomLeft" : @(UIViewContentModeBottomLeft), @"bottomRight" : @(UIViewContentModeBottomRight)}
            ),
            p(S(contentScaleFactor), ISSPropertyTypeNumber),
            p(@"exclusiveTouch", ISSPropertyTypeBool),
            ps(S(frame), ISSPropertyTypeRect, frameBlock),
            p(@"hidden", ISSPropertyTypeBool),
            pas(@"layer.anchorPoint", @[@"anchorPoint"], ISSPropertyTypePoint, anchorPointBlock),
            pa(@"layer.cornerRadius", @[@"cornerradius"], ISSPropertyTypeNumber),
            pa(@"layer.borderColor", @[@"bordercolor"], ISSPropertyTypeCGColor),
            pa(@"layer.borderWidth", @[@"borderwidth"], ISSPropertyTypeNumber),
            ps(S(layout), ISSPropertyTypeLayout, layoutBlock),
            p(@"layoutMargins", ISSPropertyTypeEdgeInsets),
            p(@"multipleTouchEnabled", ISSPropertyTypeBool),
            p(@"opaque", ISSPropertyTypeBool),
            shadowOffset,
            shadowColor,
            pa(@"layer.shadowOpacity", @[@"shadowopacity"], ISSPropertyTypeNumber),
            pa(@"layer.shadowRadius", @[@"shadowradius"], ISSPropertyTypeNumber),
            p(S(tintColor), ISSPropertyTypeColor),
            pe(S(tintAdjustmentMode), @{@"automatic" : @(UIViewTintAdjustmentModeAutomatic), @"normal" : @(UIViewTintAdjustmentModeNormal), @"dimmed" : @(UIViewTintAdjustmentModeDimmed)}),
            p(S(transform), ISSPropertyTypeTransform),
            p(@"userInteractionEnabled", ISSPropertyTypeBool)
    ]];
    NSSet* allProperties = viewProperties;

    
#pragma mark - UIControl

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

    
#pragma mark - UIScrollView

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

    
#pragma mark - UITableView
    
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


#pragma mark - UIWebView
    
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

    
#pragma mark - UICollectionView

    NSSet* collectionViewProperties = [NSSet setWithArray:@[
            allowsSelection,
            allowsMultipleSelection,
            // UICollectionViewFlowLayout properties:
            pea(@"collectionViewLayout.scrollDirection", @[@"scrollDirection"], @{@"vertical" : @(UICollectionViewScrollDirectionVertical), @"horizontal" : @(UICollectionViewScrollDirectionHorizontal)}),
            pa(@"collectionViewLayout.minimumLineSpacing", @[@"minimumLineSpacing"], ISSPropertyTypeNumber),
            pa(@"collectionViewLayout.minimumInteritemSpacing", @[@"minimumInteritemSpacing"], ISSPropertyTypeNumber),
            pa(@"collectionViewLayout.itemSize", @[@"itemSize"], ISSPropertyTypeSize),
            pa(@"collectionViewLayout.estimatedItemSize", @[@"estimatedItemSize"], ISSPropertyTypeSize),
            pa(@"collectionViewLayout.sectionInset", @[@"sectionInset"], ISSPropertyTypeEdgeInsets),
            pa(@"collectionViewLayout.headerReferenceSize", @[@"headerReferenceSize"], ISSPropertyTypeSize),
            pa(@"collectionViewLayout.footerReferenceSize", @[@"footerReferenceSize"], ISSPropertyTypeSize)
    ]];
    allProperties = [allProperties setByAddingObjectsFromSet:collectionViewProperties];


#pragma mark - UIActivityIndicatiorView
    
    NSSet* activityIndicatorProperties = [NSSet setWithArray:@[
            pe(S(activityIndicatorViewStyle), @{@"gray" : @(UIActivityIndicatorViewStyleGray), @"white" : @(UIActivityIndicatorViewStyleWhite), @"whiteLarge" : @(UIActivityIndicatorViewStyleWhiteLarge)}),
            p(S(color), ISSPropertyTypeColor),
            p(S(hidesWhenStopped), ISSPropertyTypeBool)
    ]];
    allProperties = [allProperties setByAddingObjectsFromSet:activityIndicatorProperties];

    
#pragma mark - UIButton

    NSSet* buttonProperties = [NSSet setWithArray:@[
            p(S(showsTouchWhenHighlighted), ISSPropertyTypeBool),
            p(S(adjustsImageWhenHighlighted), ISSPropertyTypeBool),
            p(S(adjustsImageWhenDisabled), ISSPropertyTypeBool),
            p(S(contentEdgeInsets), ISSPropertyTypeEdgeInsets),
            p(S(titleEdgeInsets), ISSPropertyTypeEdgeInsets),
            p(S(imageEdgeInsets), ISSPropertyTypeEdgeInsets),
            p(S(reversesTitleShadowWhenHighlighted), ISSPropertyTypeBool),
            title,
            attributedTitle,
            pp(@"titleColor", controlStateParametersValues, ISSPropertyTypeColor, ^(SetterBlockParamList) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setTitleColor:forState:)] ) [viewObject setTitleColor:value forState:state];
                else return NO;
                return YES;
            }),
            pp(@"titleShadowColor", controlStateParametersValues, ISSPropertyTypeColor, ^(SetterBlockParamList) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setTitleShadowColor:forState:)] ) [viewObject setTitleShadowColor:value forState:state];
                else return NO;
                return YES;
            }),
            image,
            backgroundImage
    ]];
    allProperties = [allProperties setByAddingObjectsFromSet:buttonProperties];


#pragma mark - UILabel
    
    NSSet* textProperties = [NSSet setWithArray:@[
            font,
            textColor,
            pea(S(textAlignment), @[@"textalign"], @{@"left" : @(NSTextAlignmentLeft), @"center" : @(NSTextAlignmentCenter), @"right" : @(NSTextAlignmentRight)})
    ]];

    NSSet* resizableTextProperties = [NSSet setWithArray:@[
            p(S(adjustsFontSizeToFitWidth), ISSPropertyTypeBool),
            p(S(minimumFontSize), ISSPropertyTypeNumber)
    ]];
    

    NSSet* labelProperties = [NSSet setWithArray:@[
            pe(S(baselineAdjustment), @{@"none" : @(UIBaselineAdjustmentNone), @"alignBaselines" : @(UIBaselineAdjustmentAlignBaselines),
                    @"alignCenters" : @(UIBaselineAdjustmentAlignCenters)}
            ),
            pe(S(lineBreakMode), @{@"wordWrap" : @(NSLineBreakByWordWrapping), @"wordWrapping" : @(NSLineBreakByWordWrapping),
                    @"charWrap" : @(NSLineBreakByCharWrapping), @"charWrapping" : @(NSLineBreakByCharWrapping),
                    @"clip" : @(NSLineBreakByClipping), @"clipping" : @(NSLineBreakByClipping),
                    @"truncateHead" : @(NSLineBreakByTruncatingHead), @"truncatingHead" : @(NSLineBreakByTruncatingHead),
                    @"truncateTail" : @(NSLineBreakByTruncatingTail), @"truncatingTail" : @(NSLineBreakByTruncatingTail),
                    @"truncateMiddle" : @(NSLineBreakByTruncatingMiddle), @"truncatingMiddle" : @(NSLineBreakByTruncatingMiddle)}
            ),
            p(S(numberOfLines), ISSPropertyTypeNumber),
            p(S(preferredMaxLayoutWidth), ISSPropertyTypeNumber),
            p(S(highlightedTextColor), ISSPropertyTypeColor),
            text,
            attributedText,
            p(S(minimumScaleFactor), ISSPropertyTypeNumber)
    ]];
    labelProperties = [labelProperties setByAddingObjectsFromSet:textProperties];
    labelProperties = [labelProperties setByAddingObjectsFromSet:resizableTextProperties];
    allProperties = [allProperties setByAddingObjectsFromSet:labelProperties];

    
#pragma mark - UIProgressView

    NSSet* progressViewProperties = [NSSet setWithArray:@[
            p(S(progressTintColor), ISSPropertyTypeColor),
            p(S(progressImage), ISSPropertyTypeImage),
            pe(S(progressViewStyle), @{@"default" : @(UIProgressViewStyleDefault), @"bar" : @(UIProgressViewStyleBar)}),
            p(S(trackTintColor), ISSPropertyTypeColor),
            p(S(trackImage), ISSPropertyTypeImage),
    ]];
    allProperties = [allProperties setByAddingObjectsFromSet:progressViewProperties];

    
#pragma mark - UITextInputTraits

    NSSet* uiTextInputTraitsProperties = [NSSet setWithArray:@[
            pi(S(autocapitalizationType), ISSPropertyTypeBool),
            pei(S(autocorrectionType), @{@"default" : @(UITextAutocorrectionTypeDefault), @"no" : @(UITextAutocorrectionTypeNo), @"yes" : @(UITextAutocorrectionTypeYes)}),
            pi(S(enablesReturnKeyAutomatically), ISSPropertyTypeBool),
            pei(S(keyboardAppearance), @{@"default" : @(UIKeyboardAppearanceDefault), @"alert" : @(UIKeyboardAppearanceAlert),
                                        @"dark" : @(UIKeyboardAppearanceDark), @"light" : @(UIKeyboardAppearanceLight)}),
            pei(S(keyboardType), @{@"default" : @(UIKeyboardTypeDefault), @"alphabet" : @(UIKeyboardTypeAlphabet), @"asciiCapable" : @(UIKeyboardTypeASCIICapable),
                    @"decimalPad" : @(UIKeyboardTypeDecimalPad), @"emailAddress" : @(UIKeyboardTypeEmailAddress), @"namePhonePad" : @(UIKeyboardTypeNamePhonePad),
                    @"numberPad" : @(UIKeyboardTypeNumberPad), @"numbersAndPunctuation" : @(UIKeyboardTypeNumbersAndPunctuation), @"phonePad" : @(UIKeyboardTypePhonePad),
                    @"twitter" : @(UIKeyboardTypeTwitter), @"URL" : @(UIKeyboardTypeURL), @"webSearch" : @(UIKeyboardTypeWebSearch)}),
            pei(S(returnKeyType), @{@"default" : @(UIReturnKeyDefault), @"go" : @(UIReturnKeyGo), @"google" : @(UIReturnKeyGoogle), @"join" : @(UIReturnKeyJoin),
                                   @"next" : @(UIReturnKeyNext), @"route" : @(UIReturnKeyRoute), @"search" : @(UIReturnKeySearch), @"send" : @(UIReturnKeySend),
                                   @"yahoo" : @(UIReturnKeyYahoo), @"done" : @(UIReturnKeyDone), @"emergencyCall" : @(UIReturnKeyEmergencyCall)}),
            pi(@"secureTextEntry", ISSPropertyTypeBool),
            pei(S(spellCheckingType), @{@"default" : @(UITextSpellCheckingTypeDefault), @"no" : @(UITextSpellCheckingTypeNo), @"yes" : @(UITextSpellCheckingTypeYes)}),
            ]];

    
#pragma mark - UITextField
    
    NSSet* textInputProperties = [NSSet setWithArray:@[
            p(S(clearsOnInsertion), ISSPropertyTypeBool),
            text,
            attributedText
        ]];
    textInputProperties = [textInputProperties setByAddingObjectsFromSet:uiTextInputTraitsProperties];
    allProperties = [allProperties setByAddingObjectsFromSet:textInputProperties];

    NSSet* textFieldProperties = [NSSet setWithArray:@[
            p(S(clearsOnBeginEditing), ISSPropertyTypeBool),
            pe(S(borderStyle), @{@"none" : @(UITextBorderStyleNone), @"bezel" : @(UITextBorderStyleBezel), @"line" : @(UITextBorderStyleLine), @"roundedRect" : @(UITextBorderStyleRoundedRect)}),
            p(S(background), ISSPropertyTypeImage),
            p(S(disabledBackground), ISSPropertyTypeImage),
            placeholder
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:textFieldProperties];

    textFieldProperties = [textFieldProperties setByAddingObjectsFromSet:textProperties];
    textFieldProperties = [textFieldProperties setByAddingObjectsFromSet:textInputProperties];
    textFieldProperties = [textFieldProperties setByAddingObjectsFromSet:resizableTextProperties];

    
#pragma mark - UITextView

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

    
#pragma mark - UIImageView

    NSSet*imageViewProperties = [NSSet setWithArray:@[
            image,
            p(S(highlightedImage), ISSPropertyTypeImage)
        ]];
    allProperties = [allProperties setByAddingObjectsFromSet:imageViewProperties];

    
#pragma mark - UISwitch

    NSSet* switchProperties = [NSSet setWithArray:@[
            p(S(onTintColor), ISSPropertyTypeColor),
            p(S(thumbTintColor), ISSPropertyTypeColor),
            p(S(onImage), ISSPropertyTypeImage),
            p(S(offImage), ISSPropertyTypeImage)
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:switchProperties];

    
#pragma mark - UISlider

    NSSet* sliderProperties = [NSSet setWithArray:@[
            p(S(minimumValueImage), ISSPropertyTypeImage),
            p(S(maximumValueImage), ISSPropertyTypeImage),
            p(S(minimumTrackTintColor), ISSPropertyTypeColor),
            p(S(maximumTrackTintColor), ISSPropertyTypeColor),
            p(S(thumbTintColor), ISSPropertyTypeColor),
            pp(@"maximumTrackImage", controlStateParametersValues, ISSPropertyTypeImage, ^(SetterBlockParamList) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setMaximumTrackImage:forState:)] ) [viewObject setMaximumTrackImage:value forState:state];
                else return NO;
                return YES;
            }),
            pp(@"minimumTrackImage", controlStateParametersValues, ISSPropertyTypeImage, ^(SetterBlockParamList) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setMinimumTrackImage:forState:)] ) [viewObject setMinimumTrackImage:value forState:state];
                else return NO;
                return YES;
            }),
            pp(@"thumbImage", controlStateParametersValues, ISSPropertyTypeImage, ^(SetterBlockParamList) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setThumbImage:forState:)] ) [viewObject setThumbImage:value forState:state];
                else return NO;
                return YES;
            }),
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:sliderProperties];
    
    
#pragma mark - UIStepper

    NSSet* stepperProperties = [NSSet setWithArray:@[
            p(@"continuous", ISSPropertyTypeBool),
            p(S(autorepeat), ISSPropertyTypeBool),
            p(S(wraps), ISSPropertyTypeBool),
            p(S(minimumValue), ISSPropertyTypeNumber),
            p(S(maximumValue), ISSPropertyTypeNumber),
            p(S(stepValue), ISSPropertyTypeNumber),
            backgroundImage,
            pp(@"decrementImage", controlStateParametersValues, ISSPropertyTypeImage, ^(SetterBlockParamList) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setDecrementImage:forState:)] ) [viewObject setDecrementImage:value forState:state];
                else return NO;
                return YES;
            }),
            pp(@"incrementImage", controlStateParametersValues, ISSPropertyTypeImage, ^(SetterBlockParamList) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setIncrementImage:forState:)] ) [viewObject setIncrementImage:value forState:state];
                else return NO;
                return YES;
            }),
            dividerImage
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:stepperProperties];

    
#pragma mark - UISegmentedControl

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
            pp(@"contentPositionAdjustment", barMetricsSegmentAndControlStateParameters, ISSPropertyTypeOffset, ^(SetterBlockParamList) {
                UISegmentedControlSegment segment = parameters.count > 0 ? (UISegmentedControlSegment)[parameters[0] integerValue] : UISegmentedControlSegmentAny;
                UIBarMetrics metrics = parameters.count > 1 ? (UIBarMetrics)[parameters[1] integerValue] : UIBarMetricsDefault;
                if( [viewObject respondsToSelector:@selector(setContentPositionAdjustment:forSegmentType:barMetrics:)] ) {
                    [viewObject setContentPositionAdjustment:[value UIOffsetValue] forSegmentType:segment barMetrics:metrics];
                    return YES;
                }
                return NO;
            }),
            dividerImage
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:segmentedControlProperties];
    segmentedControlProperties = [segmentedControlProperties setByAddingObjectsFromSet:statefulTitleTextAttributes];

    
#pragma mark - UIBarButtonItem

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
            pp(@"backgroundVerticalPositionAdjustment", barMetricsParameters, ISSPropertyTypeNumber, ^(SetterBlockParamList) {
                UIBarMetrics metrics = parameters.count > 0 ? (UIBarMetrics) [parameters[0] integerValue] : UIBarMetricsDefault;
                if( [viewObject respondsToSelector:@selector(setBackgroundVerticalPositionAdjustment:forBarMetrics:)] ) {
                    [viewObject setBackgroundVerticalPositionAdjustment:[value floatValue] forBarMetrics:metrics];
                    return YES;
                }
                return NO;
            }),
            titlePositionAdjustment,
            pp(@"backButtonBackgroundImage", barMetricsAndControlStateParameters, ISSPropertyTypeImage, ^(SetterBlockParamList) {
                UIControlState state = parameters.count > 0 ? (UIControlState) [parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                UIBarMetrics metrics = parameters.count > 1 ? (UIBarMetrics) [parameters[1] integerValue] : UIBarMetricsDefault;
                if( [viewObject respondsToSelector:@selector(setBackButtonBackgroundImage:forState:barMetrics:)] ) {
                    [viewObject setBackButtonBackgroundImage:value forState:state barMetrics:metrics];
                    return YES;
                }
                return NO;
            }),
            pp(@"backButtonBackgroundVerticalPositionAdjustment", barMetricsParameters, ISSPropertyTypeNumber, ^(SetterBlockParamList) {
                UIBarMetrics metrics = parameters.count > 0 ? (UIBarMetrics) [parameters[0] integerValue] : UIBarMetricsDefault;
                if( [viewObject respondsToSelector:@selector(setBackButtonBackgroundVerticalPositionAdjustment:forBarMetrics:)] ) {
                    [viewObject setBackButtonBackgroundVerticalPositionAdjustment:[value floatValue] forBarMetrics:metrics];
                    return YES;
                }
                return NO;
            }),
            pp(@"backButtonTitlePositionAdjustment", barMetricsParameters, ISSPropertyTypeOffset, ^(SetterBlockParamList) {
                UIBarMetrics metrics = parameters.count > 0 ? (UIBarMetrics) [parameters[0] integerValue] : UIBarMetricsDefault;
                if( [viewObject respondsToSelector:@selector(setBackButtonTitlePositionAdjustment:forBarMetrics:)] ) {
                    [viewObject setBackButtonTitlePositionAdjustment:[value UIOffsetValue] forBarMetrics:metrics];
                    return YES;
                }
                return NO;
            }),
    ]];

    allProperties = [allProperties setByAddingObjectsFromSet:barButtonProperties];
    barButtonProperties = [barButtonProperties setByAddingObjectsFromSet:statefulTitleTextAttributes];

    
#pragma mark - UITableViewCell

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

    
#pragma mark - UIToolbar

    NSSet* toolbarProperties = [NSSet setWithArray:@[
            barStyle,
            translucent,
            barTintColor,
            backgroundImage,
            shadowImage
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:toolbarProperties];

    
#pragma mark - UINavigationBar

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

    
#pragma mark - UISearchBar

    NSDictionary* searchBarIconParameters = @{@"iconBookmark" : @(UISearchBarIconBookmark), @"iconClear" : @(UISearchBarIconClear),
                    @"iconResultsList" : @(UISearchBarIconResultsList), @"iconSearch" : @(UISearchBarIconSearch)};
    NSMutableDictionary* statefulSearchBarIconParameters = [NSMutableDictionary dictionaryWithDictionary:searchBarIconParameters];
    [statefulSearchBarIconParameters addEntriesFromDictionary:controlStateParametersValues];

    NSSet* searchBarProperties = [NSSet setWithArray:@[
            barStyle,
            text,
            prompt,
            placeholder,
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
            pp(@"searchFieldBackgroundImage", controlStateParametersValues, ISSPropertyTypeImage, ^(SetterBlockParamList) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setSearchFieldBackgroundImage:forState:)] ) {
                    [viewObject setSearchFieldBackgroundImage:value forState:state];
                    return YES;
                }
                return NO;
            }),
            pp(@"imageForSearchBarIcon", statefulSearchBarIconParameters, ISSPropertyTypeImage, ^(SetterBlockParamList) {
                UISearchBarIcon icon = parameters.count > 0 ? (UISearchBarIcon)[parameters[0] integerValue] : UISearchBarIconSearch;
                UIControlState state = parameters.count > 1 ? (UIControlState)[parameters[1] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setImage:forSearchBarIcon:state:)] ) {
                    [viewObject setImage:value forSearchBarIcon:icon state:state];
                    return YES;
                }
                return NO;
            }),
            pp(@"scopeBarButtonBackgroundImage", controlStateParametersValues, ISSPropertyTypeImage, ^(SetterBlockParamList) {
                UIControlState state = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setScopeBarButtonBackgroundImage:forState:)] ) {
                    [viewObject setScopeBarButtonBackgroundImage:value forState:state];
                    return YES;
                }
                return NO;
            }),
            pp(@"scopeBarButtonDividerImage", controlStateParametersValues, ISSPropertyTypeImage, ^(SetterBlockParamList) {
                UIControlState leftState = parameters.count > 0 ? (UIControlState)[parameters[0] unsignedIntegerValue] : UIControlStateNormal;
                UIControlState rightState = parameters.count > 1 ? (UIControlState)[parameters[1] unsignedIntegerValue] : UIControlStateNormal;
                if( [viewObject respondsToSelector:@selector(setScopeBarButtonDividerImage:forLeftSegmentState:rightSegmentState:)] ) {
                    [viewObject setScopeBarButtonDividerImage:value forLeftSegmentState:leftState rightSegmentState:rightState];
                    return YES;
                }
                return NO;
            }),
            pp(@"scopeBarButtonTitleFont", controlStateParametersValues, ISSPropertyTypeFont, ^(SetterBlockParamList) {
                return setTitleTextAttributes(viewObject, value, parameters, UITextAttributeFont);
            }),
            pp(@"scopeBarButtonTitleTextColor", controlStateParametersValues, ISSPropertyTypeColor, ^(SetterBlockParamList) {
                return setTitleTextAttributes(viewObject, value, parameters, UITextAttributeTextColor);
            }),
            pp(@"scopeBarButtonTitleShadowColor", controlStateParametersValues, ISSPropertyTypeColor, ^(SetterBlockParamList) {
                return setTitleTextAttributes(viewObject, value, parameters, UITextAttributeTextShadowColor);
            }),
            pp(@"scopeBarButtonTitleShadowOffset", controlStateParametersValues, ISSPropertyTypeOffset, ^(SetterBlockParamList) {
                return setTitleTextAttributes(viewObject, value, parameters, UITextAttributeTextShadowOffset);
            }),
            p(S(searchFieldBackgroundPositionAdjustment), ISSPropertyTypeOffset),
            p(S(searchTextPositionAdjustment), ISSPropertyTypeOffset),
            pp(@"positionAdjustmentForSearchBarIcon", searchBarIconParameters, ISSPropertyTypeOffset, ^(SetterBlockParamList) {
                UISearchBarIcon icon = parameters.count > 0 ? (UISearchBarIcon)[parameters[0] integerValue] : UISearchBarIconSearch;
                if( [viewObject respondsToSelector:@selector(setPositionAdjustment:forSearchBarIcon:)] ) {
                    [viewObject setPositionAdjustment:[value UIOffsetValue] forSearchBarIcon:icon];
                    return YES;
                }
                return NO;
            })
        ]];

    allProperties = [allProperties setByAddingObjectsFromSet:searchBarProperties];
    searchBarProperties = [searchBarProperties setByAddingObjectsFromSet:uiTextInputTraitsProperties];

    
#pragma mark - UITabBar

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

    allProperties = [allProperties setByAddingObjectsFromSet:tabBarProperties];

    
#pragma mark - UITabBarItem
    
    NSSet* tabBarItemProperties = [NSSet setWithArray:@[
            p(S(selectedImage), ISSPropertyTypeImage),
            titlePositionAdjustment,
    ]];

    allProperties = [allProperties setByAddingObjectsFromSet:tabBarItemProperties];


    self.propertyDefinitions = allProperties;


    self.propertyDefinitionsForClass = @{
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

    NSMutableDictionary* classesToNames = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* typeNamesToClasses = [[NSMutableDictionary alloc] init];

    // Extend the default set of valid type classes with a few common view controller classes
    NSArray* validTypeClasses = [self.propertyDefinitionsForClass.allKeys arrayByAddingObjectsFromArray:@[UIViewController.class, UINavigationController.class, UITabBarController.class, UIPageViewController.class, UITableViewController.class, UICollectionViewController.class]];

    for(Class clazz in validTypeClasses) {  
        NSString* typeName = [[clazz description] lowercaseString];
        classesToNames[resistanceIsFutile clazz] = typeName;
        typeNamesToClasses[typeName] = clazz;
    }
    classesToNames[resistanceIsFutile UIWindow.class] = @"uiwindow";
    typeNamesToClasses[@"uiwindow"] = UIWindow.class;
    self.classesToTypeNames = [NSDictionary dictionaryWithDictionary:classesToNames];
    self.typeNamesToClasses = [NSDictionary dictionaryWithDictionary:typeNamesToClasses];


    // Type properties
    NSSet* attributedStringProperties = [NSSet setWithArray:@[
        ps(@"font", ISSPropertyTypeFont, ^(ISSPropertyDefinition* property, NSMutableDictionary* attributes, id value, NSArray* parameters) {
            if( value ) attributes[NSFontAttributeName] = value;
            return YES;
        }),
        ps(@"backgroundColor", ISSPropertyTypeColor, ^(ISSPropertyDefinition* property, NSMutableDictionary* attributes, id value, NSArray* parameters) {
            if( value ) attributes[NSBackgroundColorAttributeName] = value;
            return YES;
        }),
        pas(@"foregroundColor", @[@"color"], ISSPropertyTypeColor, ^(ISSPropertyDefinition* property, NSMutableDictionary* attributes, id value, NSArray* parameters) {
            if( value ) attributes[NSForegroundColorAttributeName] = value;
            return YES;
        }),
        ps(@"ligature", ISSPropertyTypeNumber, ^(ISSPropertyDefinition* property, NSMutableDictionary* attributes, id value, NSArray* parameters) {
            if( value ) attributes[NSLigatureAttributeName] = value;
            return YES;
        }),
        ps(@"kern", ISSPropertyTypeNumber, ^(ISSPropertyDefinition* property, NSMutableDictionary* attributes, id value, NSArray* parameters) {
            if( value ) attributes[NSKernAttributeName] = value;
            return YES;
        }),
        ps(@"strikethroughStyle", ISSPropertyTypeNumber, ^(ISSPropertyDefinition* property, NSMutableDictionary* attributes, id value, NSArray* parameters) {
            if( value ) attributes[NSStrikethroughStyleAttributeName] = value;
            return YES;
        }),
        ps(@"underlineStyle", ISSPropertyTypeNumber, ^(ISSPropertyDefinition* property, NSMutableDictionary* attributes, id value, NSArray* parameters) {
            if( value ) attributes[NSUnderlineStyleAttributeName] = value;
            return YES;
        }),
        ps(@"strokeColor", ISSPropertyTypeColor, ^(ISSPropertyDefinition* property, NSMutableDictionary* attributes, id value, NSArray* parameters) {
            if( value ) attributes[NSStrokeColorAttributeName] = value;
            return YES;
        }),
        ps(@"strokeWidth", ISSPropertyTypeNumber, ^(ISSPropertyDefinition* property, NSMutableDictionary* attributes, id value, NSArray* parameters) {
            if( value ) attributes[NSStrokeWidthAttributeName] = value;
            return YES;
        }),
        // TODO: NSShadowAttributeName
        // TODO: NSTextEffectAttributeName
        ps(@"baselineOffset", ISSPropertyTypeNumber, ^(ISSPropertyDefinition* property, NSMutableDictionary* attributes, id value, NSArray* parameters) {
            if( value ) attributes[NSBaselineOffsetAttributeName] = value;
            return YES;
        }),
        ps(@"underlineColor", ISSPropertyTypeColor, ^(ISSPropertyDefinition* property, NSMutableDictionary* attributes, id value, NSArray* parameters) {
            if( value ) attributes[NSUnderlineColorAttributeName] = value;
            return YES;
        }),
        ps(@"strikethroughColor", ISSPropertyTypeColor, ^(ISSPropertyDefinition* property, NSMutableDictionary* attributes, id value, NSArray* parameters) {
            if( value ) attributes[NSStrikethroughColorAttributeName] = value;
            return YES;
        }),
        ps(@"obliqueness", ISSPropertyTypeNumber, ^(ISSPropertyDefinition* property, NSMutableDictionary* attributes, id value, NSArray* parameters) {
            if( value ) attributes[NSObliquenessAttributeName] = value;
            return YES;
        }),
        ps(@"expansion", ISSPropertyTypeNumber, ^(ISSPropertyDefinition* property, NSMutableDictionary* attributes, id value, NSArray* parameters) {
            if( value ) attributes[NSExpansionAttributeName] = value;
            return YES;
        })
        // TODO: NSWritingDirectionAttributeName
    ]];

    self.typePropertyDefinitions = @{
        @(ISSPropertyTypeAttributedString) : attributedStringProperties
    };

#pragma GCC diagnostic pop
}

@end
