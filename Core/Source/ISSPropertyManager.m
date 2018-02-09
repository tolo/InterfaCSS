//
//  ISSPropertyManager.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSPropertyManager.h"

#import "ISSPropertyDeclaration.h"
#import "ISSPropertyDefinition.h"
#import "ISSElementStylingProxy.h"
#import "ISSRuntimeIntrospectionUtils.h"
#import "ISSRuntimeProperty.h"
#import "ISSUpdatableValue.h"

#import "NSObject+ISSLogSupport.h"
#import "NSString+ISSAdditions.h"


#define resistanceIsFutile (id <NSCopying>)



#pragma mark - ISSPropertyManager


@interface ISSPropertyManager ()

@property (nonatomic, strong) NSMutableDictionary* propertiesByType;

@property (nonatomic, strong) NSDictionary* classesToTypeNames;
@property (nonatomic, strong) NSDictionary* typeNamesToClasses;

@end


@implementation ISSPropertyManager

#pragma mark -

- (ISSPropertyDefinition*) findPropertyWithName:(NSString*)name inClass:(Class)clazz {
    NSString* canonicalType = [self canonicalTypeForClass:clazz];
    NSMutableDictionary* properties = self.propertiesByType[canonicalType];
    NSString* lcName = [name lowercaseString];
    ISSPropertyDefinition* property = properties[lcName];
    if( !property ) {
        NSDictionary* runtimeProperties = [ISSRuntimeIntrospectionUtils runtimePropertiesForClass:clazz lowercasedNames:YES];
        ISSRuntimeProperty* runtimeProperty = runtimeProperties[lcName];
        if( runtimeProperty ) {
            property = [[ISSPropertyDefinition alloc] initWithRuntimeProperty:runtimeProperty type:[self runtimePropertyToPropertyType:runtimeProperty] enumValueMapping:nil];
            self.propertiesByType[canonicalType] = properties;
        }
    }
    return property;
}


#pragma mark - Property registration

- (ISSPropertyDefinition*) registerProperty:(ISSPropertyDefinition*)property inClass:(Class)clazz {
    NSString* typeName = [self registerCanonicalTypeClass:clazz]; // Register canonical type, if needed
    NSMutableDictionary* properties = self.propertiesByType[typeName];
    if (properties) {
        properties[[property.name lowercaseString]] = property;
    } else {
        self.propertiesByType[typeName] = [NSMutableDictionary dictionaryWithDictionary:@{[property.name lowercaseString]: property}];
    }
    return property;
}


#pragma mark - Internal convenience property registration methods

- (void) _register:(NSString*)name inClasses:(NSArray<Class>*)classes type:(ISSPropertyType)type enums:(nullable ISSPropertyEnumValueMapping*)enumValueMapping {
    for(Class clazz in classes) {
        [self _register:name inClass:clazz type:type enums:enumValueMapping];
    }
}

- (ISSPropertyDefinition*) _register:(NSString*)name inClass:(Class)clazz type:(ISSPropertyType)type enums:(nullable ISSPropertyEnumValueMapping*)enumValueMapping {
    ISSRuntimeProperty* runtimeProperty = [ISSRuntimeIntrospectionUtils runtimePropertyWithName:name inClass:clazz lowercasedNames:YES];
    if( runtimeProperty ) {
        return [self registerProperty:[[ISSPropertyDefinition alloc] initWithRuntimeProperty:runtimeProperty type:type enumValueMapping:enumValueMapping] inClass:clazz];
    }
    return nil;
}

- (ISSPropertyDefinition*) _register:(NSString*)name inClass:(Class)clazz type:(ISSPropertyType)type selector:(SEL)selector params:(NSArray<ISSPropertyParameterTransformer>*)parameterTransformers {
    return [self registerProperty:[[ISSPropertyDefinition alloc] initParameterizedPropertyWithName:name inClass:clazz type:type selector:selector enumValueMapping:nil parameterTransformers:parameterTransformers] inClass:clazz];
}

- (ISSPropertyDefinition*) _register:(NSString*)name inClass:(Class)clazz type:(ISSPropertyType)type setter:(ISSPropertySetterBlock)setter {
    return [self registerProperty:[[ISSPropertyDefinition alloc] initCustomPropertyWithName:name inClass:clazz type:type setterBlock:setter] inClass:clazz];
}


#pragma mark - Apply property value

- (BOOL) applyPropertyValue:(ISSPropertyDeclaration*)propertyValue onTarget:(ISSElementStylingProxy*)targetElement {
    if( propertyValue.useCurrentValue ) {
        ISSLogTrace(@"Property value not changed - using existing value for '%@' in '%@'", propertyValue.propertyName, targetElement);
        return YES;
    }

    if( propertyValue.isNestedElementKeyPathRegistrationPlaceholder ) {
        NSString* keyPath = [ISSRuntimeIntrospectionUtils validKeyPathForCaseInsensitivePath:propertyValue.nestedElementKeyPath inClass:[targetElement.uiElement class]];
        if( keyPath ) {
            [targetElement addValidNestedElementKeyPath:keyPath];
        } else {
            ISSLogWarning(@"Unable to resolve keypath '%@' in '%@'", propertyValue.nestedElementKeyPath, targetElement);
        }
        return keyPath != nil;
    }

    ISSPropertyDefinition* property = [self findPropertyWithName:propertyValue.propertyName inClass:[targetElement.uiElement class]];
    if( !property ) {
        ISSLogWarning(@"Cannot apply property value - unknown property (%@)!", propertyValue);
        return NO;
    }

    id value = [propertyValue valueForProperty:property];

    if( !value ) {
        ISSLogWarning(@"Cannot apply property value to '%@' in '%@' - value is nil!", property.fqn, targetElement);
        return NO;
    }

    if( [value isKindOfClass:ISSUpdatableValue.class] ) {
        __weak ISSUpdatableValue* weakUpdatableValue = value;
        __weak ISSPropertyDefinition* weakProperty = property;
        __weak ISSPropertyDeclaration* weakPropertyValue = propertyValue;
        __weak ISSElementStylingProxy* weakElement = targetElement;
        [targetElement addObserverForValue:weakUpdatableValue inProperty:propertyValue withBlock:^(NSNotification* note) {
            weakProperty.setterBlock(weakProperty, weakElement.uiElement, weakUpdatableValue, weakPropertyValue.parameters);
        }];
        [weakUpdatableValue requestUpdate];
        value = weakUpdatableValue.lastValue;
    }

    BOOL result = [property setValue:value onTarget:targetElement.uiElement withParameters:propertyValue.parameters];
    
    if( !result ) {
        ISSLogDebug(@"Unable to apply property value to '%@' in '%@'", property.fqn, targetElement.uiElement);
    }

    return result;
}



- (ISSPropertyType) runtimePropertyToPropertyType:(ISSRuntimeProperty*)runtimeProperty {
    if( runtimeProperty.propertyClass ) {
        if ( [runtimeProperty.propertyClass isSubclassOfClass:NSString.class] ) {
            return ISSPropertyTypeString;
        }
        else if ( [runtimeProperty.propertyClass isSubclassOfClass:NSAttributedString.class] ) {
            return ISSPropertyTypeAttributedString;
        }
        else if ( [runtimeProperty.propertyClass isSubclassOfClass:UIFont.class] ) {
            return ISSPropertyTypeFont;
        }
        else if ( [runtimeProperty.propertyClass isSubclassOfClass:UIImage.class] ) {
            return ISSPropertyTypeImage;
        }
        else if ( [runtimeProperty.propertyClass isSubclassOfClass:UIColor.class] ) {
            return ISSPropertyTypeColor;
        }
    }
    else if( runtimeProperty.isBooleanType ) {
        return ISSPropertyTypeBool;
    }
    else if( runtimeProperty.isNumericType ) {
        return ISSPropertyTypeNumber;
    }
    else if ( [runtimeProperty isType:@encode(CGColorRef)] ) {
        return ISSPropertyTypeCGColor;
    }
    else if ( [runtimeProperty isType:@encode(CGRect)] ) {
        return ISSPropertyTypeRect;
    }
    else if ( [runtimeProperty isType:@encode(CGPoint)] ) {
        return ISSPropertyTypePoint;
    }
    else if ( [runtimeProperty isType:@encode(UIEdgeInsets)] ) {
        return ISSPropertyTypeEdgeInsets;
    }
    else if ( [runtimeProperty isType:@encode(UIOffset)] ) {
        return ISSPropertyTypeOffset;
    }
    else if ( [runtimeProperty isType:@encode(CGSize)] ) {
        return ISSPropertyTypeSize;
    }
    else if ( [runtimeProperty isType:@encode(CGAffineTransform)] ) {
        return ISSPropertyTypeTransform;
    }

    return ISSPropertyTypeUnknown;
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
        clazz = [ISSRuntimeIntrospectionUtils classWithName:type];
        if( clazz ) {
            // ...and if it is - register it as a canonical type (keep case)
            [self registerCanonicalTypeClass:clazz];
        }
    }
    return clazz;
}

- (NSString*) registerCanonicalTypeClass:(Class)clazz {
    NSString* type = [NSStringFromClass(clazz) lowercaseString];
    if (self.typeNamesToClasses[type]) return type; // Already registered

    NSMutableDictionary* temp = [NSMutableDictionary dictionaryWithDictionary:self.typeNamesToClasses];
    temp[type] = clazz;
    self.typeNamesToClasses = [NSDictionary dictionaryWithDictionary:temp];

    temp = [NSMutableDictionary dictionaryWithDictionary:self.classesToTypeNames];
    temp[resistanceIsFutile clazz] = type;
    self.classesToTypeNames = [NSDictionary dictionaryWithDictionary:temp];

    // Reset all cached data ISSElementStylingProxy, since canonical type class may have changed for some elements
    [ISSElementStylingProxy markAllCachedStylingInformationAsDirty];

    return type;
}



#pragma mark - initialization - setup of property definitions

- (instancetype) init {
    return [self init:YES];
}

- (instancetype) init:(BOOL)withStandardPropertyCustomizations {
    if( self = [super init] ) {
        NSArray* validTypeClasses = @[
             resistanceIsFutile UIView.class,
             resistanceIsFutile UIImageView.class,
             resistanceIsFutile UIScrollView.class,
             resistanceIsFutile UITableView.class,
        #if TARGET_OS_TV == 0
             resistanceIsFutile UIWebView.class,
        #endif
             resistanceIsFutile UITableViewCell.class,
             resistanceIsFutile UICollectionView.class,

             resistanceIsFutile UINavigationBar.class,
             resistanceIsFutile UISearchBar.class,
        #if TARGET_OS_TV == 0
             resistanceIsFutile UIToolbar.class,
        #endif
             resistanceIsFutile UIBarButtonItem.class,

             resistanceIsFutile UITabBar.class,
             resistanceIsFutile UITabBarItem.class,

             resistanceIsFutile UIControl.class,
             resistanceIsFutile UIActivityIndicatorView.class,
             resistanceIsFutile UIButton.class,
             resistanceIsFutile UILabel.class,
             resistanceIsFutile UIProgressView.class,
             resistanceIsFutile UISegmentedControl.class,
             resistanceIsFutile UITextField.class,
             resistanceIsFutile UITextView.class,
        #if TARGET_OS_TV == 0
             resistanceIsFutile UISlider.class,
             resistanceIsFutile UIStepper.class,
             resistanceIsFutile UISwitch.class
        #endif
             ];


        NSMutableDictionary* classesToNames = [[NSMutableDictionary alloc] init];
        NSMutableDictionary* typeNamesToClasses = [[NSMutableDictionary alloc] init];

        // Extend the default set of valid type classes with a few common view controller classes
        validTypeClasses = [validTypeClasses arrayByAddingObjectsFromArray:@[UIViewController.class, UINavigationController.class, UITabBarController.class, UIPageViewController.class, UITableViewController.class, UICollectionViewController.class]];

        for(Class clazz in validTypeClasses) {
            NSString* typeName = [[clazz description] lowercaseString];
            classesToNames[resistanceIsFutile clazz] = typeName;
            typeNamesToClasses[typeName] = clazz;
        }
        classesToNames[resistanceIsFutile UIWindow.class] = @"uiwindow";
        typeNamesToClasses[@"uiwindow"] = UIWindow.class;
        _classesToTypeNames = [NSDictionary dictionaryWithDictionary:classesToNames];
        _typeNamesToClasses = [NSDictionary dictionaryWithDictionary:typeNamesToClasses];

        
        _propertiesByType = [NSMutableDictionary dictionary];


        #if ISS_OS_VERSION_MIN_REQUIRED < 90000
        NSDictionary* controlStateParametersValues = @{@"normal" : @(UIControlStateNormal), @"highlighted" : @(UIControlStateHighlighted),
                                                       @"selected" : @(UIControlStateSelected), @"disabled" : @(UIControlStateDisabled)};
        #else
        NSDictionary* controlStateParametersValues = @{@"normal" : @(UIControlStateNormal), @"focused" : @(UIControlStateFocused), @"highlighted" : @(UIControlStateHighlighted),
                                                       @"selected" : @(UIControlStateSelected), @"disabled" : @(UIControlStateDisabled)};
        #endif
        ISSPropertyEnumValueMapping* controlStateMapping = [[ISSPropertyBitMaskEnumValueMapping alloc] initWithEnumValues:controlStateParametersValues enumBaseName:@"UIControlState" defaultValue:@(UIControlStateNormal)];
        
        ISSPropertyEnumValueMapping* contentModeMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:
                              @{@"scaletofill" : @(UIViewContentModeScaleToFill), @"scaleaspectfit" : @(UIViewContentModeScaleAspectFit),
                                @"scaleaspectfill" : @(UIViewContentModeScaleAspectFill), @"redraw" : @(UIViewContentModeRedraw), @"center" : @(UIViewContentModeCenter), @"top" : @(UIViewContentModeTop),
                                @"bottom" : @(UIViewContentModeBottom), @"left" : @(UIViewContentModeLeft), @"right" : @(UIViewContentModeRight), @"topleft" : @(UIViewContentModeTopLeft),
                                @"topright" : @(UIViewContentModeTopRight), @"bottomleft" : @(UIViewContentModeBottomLeft), @"bottomright" : @(UIViewContentModeBottomRight)} enumBaseName:@"UIViewContentMode" defaultValue:@(UIViewContentModeScaleToFill)];
        
        ISSPropertyEnumValueMapping* viewAutoresizingMapping = [[ISSPropertyBitMaskEnumValueMapping alloc] initWithEnumValues:@{ @"none" : @(UIViewAutoresizingNone),
                                     @"width" : @(UIViewAutoresizingFlexibleWidth), @"flexibleWidth" : @(UIViewAutoresizingFlexibleWidth),
                                     @"height" : @(UIViewAutoresizingFlexibleHeight), @"flexibleHeight" : @(UIViewAutoresizingFlexibleHeight),
                                     @"bottom" : @(UIViewAutoresizingFlexibleBottomMargin), @"flexibleBottomMargin" : @(UIViewAutoresizingFlexibleBottomMargin),
                                     @"top" : @(UIViewAutoresizingFlexibleTopMargin), @"flexibleTopMargin" : @(UIViewAutoresizingFlexibleTopMargin),
                                     @"left" : @(UIViewAutoresizingFlexibleLeftMargin), @"flexibleLeftMargin" : @(UIViewAutoresizingFlexibleLeftMargin),
                                     @"right" : @(UIViewAutoresizingFlexibleRightMargin), @"flexibleRightMargin" : @(UIViewAutoresizingFlexibleRightMargin)} enumBaseName:@"UIViewAutoresizing" defaultValue:@(UIViewAutoresizingNone)];
        
        ISSPropertyEnumValueMapping* tintAdjustmentModeMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"automatic" : @(UIViewTintAdjustmentModeAutomatic),
                                     @"normal" : @(UIViewTintAdjustmentModeNormal), @"dimmed" : @(UIViewTintAdjustmentModeDimmed)} enumBaseName:@"UIViewTintAdjustmentMode" defaultValue:@(UIViewTintAdjustmentModeAutomatic)];

        ISSPropertyEnumValueMapping* barMetricsMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"default" : @(UIBarMetricsDefault), @"landscapePhone" : @(UIBarMetricsCompact), @"compact" : @(UIBarMetricsCompact),
                                     @"landscapePhonePrompt" : @(UIBarMetricsCompactPrompt), @"compactPrompt" : @(UIBarMetricsCompactPrompt), @"defaultPrompt" : @(UIBarMetricsDefaultPrompt)} enumBaseName:@"UIBarMetrics" defaultValue:@(UIBarMetricsDefault)];

        ISSPropertyEnumValueMapping* barPositionMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"any" : @(UIBarPositionAny), @"bottom" : @(UIBarPositionBottom),
                                                        @"top" : @(UIBarPositionTop), @"topAttached" : @(UIBarPositionTopAttached)} enumBaseName:@"UIBarPosition" defaultValue:@(UIBarPositionAny)];

        ISSPropertyEnumValueMapping* segmentTypeMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"any" : @(UISegmentedControlSegmentAny), @"left" : @(UISegmentedControlSegmentLeft), @"center" : @(UISegmentedControlSegmentCenter),
                                                        @"right" : @(UISegmentedControlSegmentRight), @"alone" : @(UISegmentedControlSegmentAlone)} enumBaseName:@"UISegmentedControlSegment" defaultValue:@(UISegmentedControlSegmentAny)];

        ISSPropertyEnumValueMapping* dataDetectorTypesMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"all" : @(UIDataDetectorTypeAll), @"none" : @(UIDataDetectorTypeNone), @"address" : @(UIDataDetectorTypeAddress),
                                                        @"calendarEvent" : @(UIDataDetectorTypeCalendarEvent), @"link" : @(UIDataDetectorTypeLink), @"phoneNumber" : @(UIDataDetectorTypePhoneNumber)} enumBaseName:@"UIDataDetectorType" defaultValue:@(UIDataDetectorTypeNone)];

        ISSPropertyEnumValueMapping* textAlignmentMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"left" : @(NSTextAlignmentLeft), @"center" : @(NSTextAlignmentCenter), @"right" : @(NSTextAlignmentRight)}
                                                                                                       enumBaseName:@"NSTextAlignment" defaultValue:@(NSTextAlignmentLeft)];
        ISSPropertyEnumValueMapping* viewModeMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"never" : @(UITextFieldViewModeNever), @"always" : @(UITextFieldViewModeAlways),
                                                    @"unlessEditing" : @(UITextFieldViewModeUnlessEditing), @"whileEditing" : @(UITextFieldViewModeWhileEditing)} enumBaseName:@"UITextFieldViewMode" defaultValue:@(UITextFieldViewModeNever)];

        #if TARGET_OS_TV == 0
        ISSPropertyEnumValueMapping* barStyleMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"default" : @(UIBarStyleDefault), @"black" : @(UIBarStyleBlack),
                                                    @"blackOpaque" : @(UIBarStyleBlackOpaque), @"blackTranslucent" : @(UIBarStyleBlackTranslucent)} enumBaseName:@"UIBarStyle" defaultValue:@(UIBarStyleDefault)];

        ISSPropertyEnumValueMapping* accessoryTypeMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"none" : @(UITableViewCellAccessoryNone), @"checkmark" : @(UITableViewCellAccessoryCheckmark), @"detailButton" : @(UITableViewCellAccessoryDetailButton),
                                                @"disclosureButton" : @(UITableViewCellAccessoryDetailDisclosureButton), @"disclosureIndicator" : @(UITableViewCellAccessoryDisclosureIndicator)} enumBaseName:@"UITableViewCellAccessory" defaultValue:@(UITableViewCellAccessoryNone)];

        NSDictionary* searchBarIconParameters = @{@"bookmark" : @(UISearchBarIconBookmark), @"clear" : @(UISearchBarIconClear),
                                                  @"resultsList" : @(UISearchBarIconResultsList), @"search" : @(UISearchBarIconSearch)};
        #else
        NSDictionary* searchBarIconParameters = @{@"search" : @(UISearchBarIconSearch)};
        #endif

        ISSPropertyEnumValueMapping* searchBarIconMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:searchBarIconParameters enumBaseName:@"UISearchBarIcon" defaultValue:@(UISearchBarIconSearch)];


        if (withStandardPropertyCustomizations) {
            ISSPropertyParameterTransformer controlStateTransformer = ^(ISSPropertyDefinition* property, NSString* parameterStringValue) { return [controlStateMapping enumValueFromString:parameterStringValue]; };
            ISSPropertyParameterTransformer barMetricsTransformer = ^(ISSPropertyDefinition* property, NSString* parameterStringValue) { return [barMetricsMapping enumValueFromString:parameterStringValue]; };
            ISSPropertyParameterTransformer barPositionTransformer = ^(ISSPropertyDefinition* property, NSString* parameterStringValue) { return [barPositionMapping enumValueFromString:parameterStringValue]; };
            ISSPropertyParameterTransformer integerTransformer = ^(ISSPropertyDefinition* property, NSString* parameterStringValue) { return @([parameterStringValue integerValue]); };
            ISSPropertyParameterTransformer segmentTypeTransformer = ^(ISSPropertyDefinition* property, NSString* parameterStringValue) { return [segmentTypeMapping enumValueFromString:parameterStringValue]; };
            ISSPropertyParameterTransformer searchBarIconTransformer = ^(ISSPropertyDefinition* property, NSString* parameterStringValue) { return [searchBarIconMapping enumValueFromString:parameterStringValue]; };


            /** UIView **/
            Class clazz = UIView.class;
            [self _register:@"autoresizingMask" inClass:clazz type:ISSPropertyTypeEnumType enums:viewAutoresizingMapping];
            [self _register:@"contentMode" inClass:clazz type:ISSPropertyTypeEnumType enums:contentModeMapping];
            [self _register:@"tintAdjustmentMode" inClass:clazz type:ISSPropertyTypeEnumType enums:tintAdjustmentModeMapping];

            /** UIControl **/
            clazz = UIControl.class;
            [self _register:@"contentVerticalAlignment" inClass:clazz type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"center" : @(UIControlContentVerticalAlignmentCenter), @"top" : @(UIControlContentVerticalAlignmentTop),
                    @"bottom" : @(UIControlContentVerticalAlignmentBottom), @"fill" : @(UIControlContentVerticalAlignmentFill)} enumBaseName:@"UIControlContentVerticalAlignment" defaultValue:@(UIControlContentVerticalAlignmentTop)]];
            [self _register:@"contentHorizontalAlignment" inClass:clazz type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"center" : @(UIControlContentHorizontalAlignmentCenter), @"left" : @(UIControlContentHorizontalAlignmentLeft),
                    @"right" : @(UIControlContentHorizontalAlignmentRight), @"fill" : @(UIControlContentHorizontalAlignmentFill)} enumBaseName:@"UIControlContentHorizontalAlignment" defaultValue:@(UIControlContentHorizontalAlignmentCenter)]];

            /** UIButton **/
            clazz = UIButton.class;
            [self _register:@"attributedTitle" inClass:clazz type:ISSPropertyTypeAttributedString selector:@selector(setAttributedTitle:forState:) params:@[controlStateTransformer]];
            [self _register:@"backgroundImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setBackgroundImage:forState:) params:@[controlStateTransformer]];
            [self _register:@"image" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setImage:forState:) params:@[controlStateTransformer]];
            [self _register:@"title" inClass:clazz type:ISSPropertyTypeString selector:@selector(setTitle:forState:) params:@[controlStateTransformer]];
            [self _register:@"titleColor" inClass:clazz type:ISSPropertyTypeColor selector:@selector(setTitleColor:forState:) params:@[controlStateTransformer]];
            [self _register:@"titleShadowColor" inClass:clazz type:ISSPropertyTypeColor selector:@selector(setTitleShadowColor:forState:) params:@[controlStateTransformer]];

            /** UILabel **/
            clazz = UILabel.class;
            [self _register:@"baselineAdjustment" inClass:clazz type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"none" : @(UIBaselineAdjustmentNone), @"alignBaselines" : @(UIBaselineAdjustmentAlignBaselines), @"alignCenters" : @(UIBaselineAdjustmentAlignCenters)} enumBaseName:@"UIBaselineAdjustment" defaultValue:@(UIBaselineAdjustmentNone)]];
            [self _register:@"lineBreakMode" inClass:clazz type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"wordWrap" : @(NSLineBreakByWordWrapping), @"wordWrapping" : @(NSLineBreakByWordWrapping),
                                                                       @"charWrap" : @(NSLineBreakByCharWrapping), @"charWrapping" : @(NSLineBreakByCharWrapping),
                                                                       @"clip" : @(NSLineBreakByClipping), @"clipping" : @(NSLineBreakByClipping),
                                                                       @"truncateHead" : @(NSLineBreakByTruncatingHead), @"truncatingHead" : @(NSLineBreakByTruncatingHead),
                                                                       @"truncateTail" : @(NSLineBreakByTruncatingTail), @"truncatingTail" : @(NSLineBreakByTruncatingTail),
                                                                       @"truncateMiddle" : @(NSLineBreakByTruncatingMiddle), @"truncatingMiddle" : @(NSLineBreakByTruncatingMiddle)} enumBaseName:@"NSLineBreakBy" defaultValue:@(NSLineBreakByTruncatingTail)]];
            [self _register:@"textAlignment" inClass:clazz type:ISSPropertyTypeEnumType enums:textAlignmentMapping];

            /** UISegmentedControl **/
            clazz = UISegmentedControl.class;
            [self _register:@"backgroundImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setBackgroundImage:forState:barMetrics:) params:@[controlStateTransformer, barMetricsTransformer]];
            [self _register:@"contentPositionAdjustment" inClass:clazz type:ISSPropertyTypeOffset selector:@selector(setContentPositionAdjustment:forSegmentType:barMetrics:) params:@[segmentTypeTransformer, barMetricsTransformer]];
            [self _register:@"contentOffset" inClass:clazz type:ISSPropertyTypeOffset selector:@selector(setContentOffset:forSegmentAtIndex:) params:@[integerTransformer]];
            [self _register:@"dividerImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setDividerImage:forLeftSegmentState:rightSegmentState:barMetrics:) params:@[controlStateTransformer, controlStateTransformer, barMetricsTransformer]];
            [self _register:@"enabled" inClass:clazz type:ISSPropertyTypeBool selector:@selector(setEnabled:forSegmentAtIndex:) params:@[integerTransformer]];
            [self _register:@"image" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setImage:forSegmentAtIndex:) params:@[integerTransformer]];
            [self _register:@"title" inClass:clazz type:ISSPropertyTypeString selector:@selector(setTitle:forSegmentAtIndex:) params:@[integerTransformer]];
            [self _register:@"titleTextAttributes" inClass:clazz type:ISSPropertyTypeTextAttributes selector:@selector(setTitleTextAttributes:forState:) params:@[controlStateTransformer]];
            [self _register:@"width" inClass:clazz type:ISSPropertyTypeNumber selector:@selector(setWidth:forSegmentAtIndex:) params:@[integerTransformer]];

            /** UISlider **/
            clazz = UISlider.class;
            [self _register:@"maximumTrackImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setMaximumTrackImage:forState:) params:@[controlStateTransformer]];
            [self _register:@"minimumTrackImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setMinimumTrackImage:forState:) params:@[controlStateTransformer]];
            [self _register:@"thumbImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setThumbImage:forState:) params:@[controlStateTransformer]];

            /** UIStepper **/
            clazz = UIStepper.class;
            [self _register:@"backgroundImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setBackgroundImage:forState:) params:@[controlStateTransformer]];
            [self _register:@"decrementImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setDecrementImage:forState:) params:@[controlStateTransformer]];
            [self _register:@"dividerImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setDividerImage:forLeftSegmentState:rightSegmentState:) params:@[controlStateTransformer, controlStateTransformer]];
            [self _register:@"incrementImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setIncrementImage:forState:) params:@[controlStateTransformer]];

            /** UIActivityIndicatorView **/
            clazz = UIActivityIndicatorView.class;
            #if TARGET_OS_TV == 1
            [self _register:@"activityIndicatorViewStyle" inClass:clazz type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"white" : @(UIActivityIndicatorViewStyleWhite), @"whiteLarge" : @(UIActivityIndicatorViewStyleWhiteLarge)} defaultValue:@(UIActivityIndicatorViewStyleWhite)]];
            #else
            [self _register:@"activityIndicatorViewStyle" inClass:clazz type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"gray" : @(UIActivityIndicatorViewStyleGray), @"white" : @(UIActivityIndicatorViewStyleWhite), @"whiteLarge" : @(UIActivityIndicatorViewStyleWhiteLarge)} enumBaseName:@"UIActivityIndicatorViewStyle" defaultValue:@(UIActivityIndicatorViewStyleWhite)]];
            #endif
            [self _register:@"animating" inClass:clazz type:ISSPropertyTypeBool setter:^BOOL(ISSPropertyDefinition* property, id target, id value, NSArray* parameters) {
                [value boolValue] ? [target startAnimating] : [target stopAnimating];
                return YES;
            }];

            /** UIProgressView **/
            clazz = UIProgressView.class;
            #if TARGET_OS_TV == 0
            [self _register:@"progressViewStyle" inClass:clazz type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"default" : @(UIProgressViewStyleDefault), @"bar" : @(UIProgressViewStyleBar)} enumBaseName:@"UIProgressViewStyle" defaultValue:@(UIProgressViewStyleDefault)]];
            #endif

            /** UIProgressView **/
            clazz = UITextField.class;
            [self _register:@"borderStyle" inClass:clazz type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"none" : @(UITextBorderStyleNone), @"bezel" : @(UITextBorderStyleBezel), @"line" : @(UITextBorderStyleLine), @"roundedRect" : @(UITextBorderStyleRoundedRect)} enumBaseName:@"UITextBorderStyle" defaultValue:@(UITextBorderStyleNone)]];
            [self _register:@"defaultTextAttributes" inClass:clazz type:ISSPropertyTypeTextAttributes enums:nil];
            [self _register:@"leftViewMode" inClass:clazz type:ISSPropertyTypeEnumType enums:viewModeMapping];
            [self _register:@"rightViewMode" inClass:clazz type:ISSPropertyTypeEnumType enums:viewModeMapping];
            [self _register:@"textAlignment" inClass:clazz type:ISSPropertyTypeEnumType enums:textAlignmentMapping];

            /** UITextView **/
            clazz = UITextView.class;
            #if TARGET_OS_TV == 0
            [self _register:@"dataDetectorTypes" inClass:clazz type:ISSPropertyTypeEnumType enums:dataDetectorTypesMapping];
            #endif
            [self _register:@"linkTextAttributes" inClass:clazz type:ISSPropertyTypeTextAttributes enums:nil];
            [self _register:@"textAlignment" inClass:clazz type:ISSPropertyTypeEnumType enums:textAlignmentMapping];
            [self _register:@"typingAttributes" inClass:clazz type:ISSPropertyTypeTextAttributes enums:nil];

            /** UIScrollView **/
            clazz = UIScrollView.class;
            [self _register:@"indicatorStyle" inClass:clazz type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"default" : @(UIScrollViewIndicatorStyleDefault), @"black" : @(UIScrollViewIndicatorStyleBlack), @"white" : @(UIScrollViewIndicatorStyleWhite)} enumBaseName:@"UIScrollViewIndicatorStyle" defaultValue:@(UIScrollViewIndicatorStyleDefault)]];
            [self _register:@"decelerationRate" inClass:clazz type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"normal" : @(UIScrollViewDecelerationRateNormal), @"fast" : @(UIScrollViewDecelerationRateFast)} enumBaseName:@"UIScrollViewDecelerationRate" defaultValue:@(UIScrollViewDecelerationRateNormal)]];
            [self _register:@"keyboardDismissMode" inClass:clazz type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"none" : @(UIScrollViewKeyboardDismissModeNone), @"onDrag" : @(UIScrollViewKeyboardDismissModeOnDrag), @"interactive" : @(UIScrollViewKeyboardDismissModeInteractive)} enumBaseName:@"UIScrollViewKeyboardDismissMode" defaultValue:@(UIScrollViewKeyboardDismissModeNone)]];

            /** UITableView **/
            clazz = UITableView.class;
            #if TARGET_OS_TV == 0
            [self _register:@"separatorStyle" inClass:clazz type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"none" : @(UITableViewCellSeparatorStyleNone), @"singleLine" : @(UITableViewCellSeparatorStyleSingleLine), @"singleLineEtched" : @(UITableViewCellSeparatorStyleSingleLineEtched)} enumBaseName:@"UITableViewCellSeparatorStyle" defaultValue:@(UITableViewCellSeparatorStyleNone)]];
            #endif

            /** UITableViewCell **/
            clazz = UITableViewCell.class;
            [self _register:@"selectionStyle" inClass:clazz type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"none" : @(UITableViewCellSelectionStyleNone), @"default" : @(UITableViewCellSelectionStyleDefault), @"blue" : @(UITableViewCellSelectionStyleBlue), @"gray" : @(UITableViewCellSelectionStyleGray)} enumBaseName:@"UITableViewCellSelectionStyle" defaultValue:@(UITableViewCellSelectionStyleNone)]];
            [self _register:@"editingStyle" inClass:clazz type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"none" : @(UITableViewCellEditingStyleNone), @"delete" : @(UITableViewCellEditingStyleDelete), @"insert" : @(UITableViewCellEditingStyleInsert)} enumBaseName:@"UITableViewCellEditingStyle" defaultValue:@(UITableViewCellEditingStyleNone)]];
            #if TARGET_OS_TV == 0
            [self _register:@"accessoryType" inClass:clazz type:ISSPropertyTypeEnumType enums:accessoryTypeMapping];
            [self _register:@"editingAccessoryType" inClass:clazz type:ISSPropertyTypeEnumType enums:accessoryTypeMapping];
            #endif

            /** UIWebView **/
            clazz = UIWebView.class;
            #if TARGET_OS_TV == 0
            [self _register:@"dataDetectorTypes" inClass:clazz type:ISSPropertyTypeEnumType enums:dataDetectorTypesMapping];
            [self _register:@"paginationMode" inClass:clazz type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"unpaginated" : @(UIWebPaginationModeUnpaginated), @"lefttoright" : @(UIWebPaginationModeLeftToRight),
                    @"toptobottom" : @(UIWebPaginationModeTopToBottom), @"bottomtotop" : @(UIWebPaginationModeBottomToTop), @"righttoleft" : @(UIWebPaginationModeRightToLeft)} enumBaseName:@"UIWebPaginationMode" defaultValue:@(UIWebPaginationModeUnpaginated)]];
            [self _register:@"paginationBreakingMode" inClass:clazz type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"page" : @(UIWebPaginationBreakingModePage), @"column" : @(UIWebPaginationBreakingModeColumn)} enumBaseName:@"UIWebPaginationBreakingMode" defaultValue:@(UIWebPaginationBreakingModePage)]];
            #endif

            /** UIBarItem **/
            clazz = UIBarItem.class;
            [self _register:@"titleTextAttributes" inClass:clazz type:ISSPropertyTypeTextAttributes selector:@selector(setTitleTextAttributes:forState:) params:@[controlStateTransformer]];

            /** UIBarButtonItem **/
            clazz = UIBarButtonItem.class;
            //setBackgroundImage:forState:style:barMetrics:
            [self _register:@"backButtonBackgroundImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setBackButtonBackgroundImage:forState:barMetrics:) params:@[controlStateTransformer, barMetricsTransformer]];
            [self _register:@"backButtonBackgroundVerticalPositionAdjustment" inClass:clazz type:ISSPropertyTypeNumber selector:@selector(setBackButtonBackgroundVerticalPositionAdjustment:forBarMetrics:) params:@[barMetricsTransformer]];
            [self _register:@"backgroundImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setBackgroundImage:forState:barMetrics:) params:@[controlStateTransformer, barMetricsTransformer]];
            [self _register:@"backgroundVerticalPositionAdjustment" inClass:clazz type:ISSPropertyTypeNumber selector:@selector(setBackgroundVerticalPositionAdjustment:forBarMetrics:) params:@[barMetricsTransformer]];
            [self _register:@"backButtonTitlePositionAdjustment" inClass:clazz type:ISSPropertyTypeOffset selector:@selector(setBackButtonTitlePositionAdjustment:forBarMetrics:) params:@[barMetricsTransformer]];
            [self _register:@"style" inClass:clazz type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"plain" : @(UIBarButtonItemStylePlain), @"done" : @(UIBarButtonItemStyleDone)} enumBaseName:@"UIBarButtonItemStyle" defaultValue:@(UIBarButtonItemStylePlain)]];
            [self _register:@"titlePositionAdjustment" inClass:clazz type:ISSPropertyTypeOffset selector:@selector(setTitlePositionAdjustment:forBarMetrics:) params:@[barMetricsTransformer]];


            /** UISearchBar **/
            clazz = UISearchBar.class;
            [self _register:@"backgroundImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setBackgroundImage:forBarPosition:barMetrics:) params:@[barPositionTransformer, barMetricsTransformer]];
            #if TARGET_OS_TV == 0
            [self _register:@"barStyle" inClass:clazz type:ISSPropertyTypeEnumType enums:barStyleMapping];
            #endif
            [self _register:@"imageForSearchBarIcon" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setImage:forSearchBarIcon:state:) params:@[searchBarIconTransformer, controlStateTransformer]];
            [self _register:@"positionAdjustmentForSearchBarIcon" inClass:clazz type:ISSPropertyTypeOffset selector:@selector(setPositionAdjustment:forSearchBarIcon:) params:@[searchBarIconTransformer]];
            [self _register:@"scopeBarButtonBackgroundImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setScopeBarButtonBackgroundImage:forState:) params:@[controlStateTransformer]];
            [self _register:@"scopeBarButtonDividerImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setScopeBarButtonDividerImage:forLeftSegmentState:rightSegmentState:) params:@[controlStateTransformer, controlStateTransformer]];
            #if TARGET_OS_TV == 0
            [self _register:@"scopeBarButtonTitleTextAttributes" inClass:clazz type:ISSPropertyTypeTextAttributes selector:@selector(setScopeBarButtonTitleTextAttributes:forState:) params:@[controlStateTransformer]];
            #endif
            [self _register:@"searchBarStyle" inClass:clazz type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"default" : @(UISearchBarStyleDefault), @"minimal" : @(UISearchBarStyleMinimal), @"prominent" : @(UISearchBarStyleProminent)} enumBaseName:@"UISearchBarStyle" defaultValue:@(UISearchBarStyleDefault)]];
            [self _register:@"searchFieldBackgroundImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setSearchFieldBackgroundImage:forState:) params:@[controlStateTransformer]];

            /** UINavigationBar **/
            clazz = UINavigationBar.class;
            [self _register:@"backgroundImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setBackgroundImage:forBarPosition:barMetrics:) params:@[barPositionTransformer, barMetricsTransformer]];
            #if TARGET_OS_TV == 0
            [self _register:@"barStyle" inClass:clazz type:ISSPropertyTypeEnumType enums:barStyleMapping];
            #endif
            [self _register:@"titleTextAttributes" inClass:clazz type:ISSPropertyTypeTextAttributes enums:nil];

            /** UIToolbar **/
            clazz = UIToolbar.class;
            [self _register:@"backgroundImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setBackgroundImage:forToolbarPosition:barMetrics:) params:@[barPositionTransformer, barMetricsTransformer]];
            #if TARGET_OS_TV == 0
            [self _register:@"barStyle" inClass:clazz type:ISSPropertyTypeEnumType enums:barStyleMapping];
            #endif
            [self _register:@"shadowImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setShadowImage:forToolbarPosition:) params:@[barPositionTransformer]];

            /** UITabBar **/
            clazz = UITabBar.class;
            #if TARGET_OS_TV == 0
            [self _register:@"barStyle" inClass:clazz type:ISSPropertyTypeEnumType enums:barStyleMapping];
            #endif
            [self _register:@"itemPositioning" inClass:clazz type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"automatic" : @(UITabBarItemPositioningAutomatic), @"centered" : @(UITabBarItemPositioningCentered), @"fill" : @(UITabBarItemPositioningFill)} enumBaseName:@"UITabBarItemPositioning" defaultValue:@(UITabBarItemPositioningAutomatic)]];


            /** UITextInputTraits **/
            NSArray* classes = @[UITextField.class,  UITextView.class, UISearchBar.class];
            [self _register:@"autocapitalizationType" inClasses:classes type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"none" : @(UITextAutocapitalizationTypeNone), @"allCharacters" : @(UITextAutocapitalizationTypeAllCharacters),
                     @"sentences" : @(UITextAutocapitalizationTypeSentences), @"words" : @(UITextAutocapitalizationTypeWords)} enumBaseName:@"UITextAutocapitalizationType" defaultValue:@(UITextAutocapitalizationTypeNone)]];
            [self _register:@"autocorrectionType" inClasses:classes type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"default" : @(UITextAutocorrectionTypeDefault), @"no" : @(UITextAutocorrectionTypeNo), @"yes" : @(UITextAutocorrectionTypeYes)} enumBaseName:@"UITextAutocorrectionType" defaultValue:@(UITextAutocorrectionTypeDefault)]];
            [self _register:@"keyboardAppearance" inClasses:classes type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"default" : @(UIKeyboardAppearanceDefault), @"alert" : @(UIKeyboardAppearanceAlert),
                                                                       @"dark" : @(UIKeyboardAppearanceDark), @"light" : @(UIKeyboardAppearanceLight)} enumBaseName:@"UIKeyboardAppearance" defaultValue:@(UIKeyboardAppearanceDefault)]];
            [self _register:@"keyboardType" inClasses:classes type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"default" : @(UIKeyboardTypeDefault), @"alphabet" : @(UIKeyboardTypeAlphabet), @"asciiCapable" : @(UIKeyboardTypeASCIICapable),
                                                                       @"decimalPad" : @(UIKeyboardTypeDecimalPad), @"emailAddress" : @(UIKeyboardTypeEmailAddress), @"namePhonePad" : @(UIKeyboardTypeNamePhonePad),
                                                                       @"numberPad" : @(UIKeyboardTypeNumberPad), @"numbersAndPunctuation" : @(UIKeyboardTypeNumbersAndPunctuation), @"phonePad" : @(UIKeyboardTypePhonePad),
                                                                       @"twitter" : @(UIKeyboardTypeTwitter), @"URL" : @(UIKeyboardTypeURL), @"webSearch" : @(UIKeyboardTypeWebSearch)} enumBaseName:@"UIKeyboardType" defaultValue:@(UIKeyboardTypeDefault)]];
            [self _register:@"returnKeyType" inClasses:classes type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"default" : @(UIReturnKeyDefault), @"go" : @(UIReturnKeyGo), @"google" : @(UIReturnKeyGoogle), @"join" : @(UIReturnKeyJoin),
                                                                       @"next" : @(UIReturnKeyNext), @"route" : @(UIReturnKeyRoute), @"search" : @(UIReturnKeySearch), @"send" : @(UIReturnKeySend),
                                                                       @"yahoo" : @(UIReturnKeyYahoo), @"done" : @(UIReturnKeyDone), @"emergencyCall" : @(UIReturnKeyEmergencyCall)} enumBaseName:@"UIReturnKey" defaultValue:@(UIReturnKeyDefault)]];
            [self _register:@"spellCheckingType" inClasses:classes type:ISSPropertyTypeEnumType enums:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"default" : @(UITextSpellCheckingTypeDefault), @"no" : @(UITextSpellCheckingTypeNo), @"yes" : @(UITextSpellCheckingTypeYes)} enumBaseName:@"UITextSpellCheckingType" defaultValue:@(UITextSpellCheckingTypeDefault)]];
        }
    }
    return self;
}

@end
