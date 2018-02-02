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

- (void) registerPropertyWithName:(NSString*)name inClasses:(NSArray<Class>*)classes type:(ISSPropertyType)type enumValueMapping:(nullable ISSPropertyEnumValueMapping*)enumValueMapping {
    for(Class clazz in classes) {
        [self registerPropertyWithName:name inClass:clazz type:type enumValueMapping:enumValueMapping];
    }
}

- (ISSPropertyDefinition*) registerPropertyWithName:(NSString*)name inClass:(Class)clazz type:(ISSPropertyType)type enumValueMapping:(nullable ISSPropertyEnumValueMapping*)enumValueMapping {
    ISSRuntimeProperty* runtimeProperty = [ISSRuntimeIntrospectionUtils runtimePropertyWithName:name inClass:clazz lowercasedNames:YES];
    if( runtimeProperty ) {
        return [self registerProperty:[[ISSPropertyDefinition alloc] initWithRuntimeProperty:runtimeProperty type:type enumValueMapping:enumValueMapping] inClass:clazz];
    }
    return nil;
}

- (ISSPropertyDefinition*) registerPropertyWithName:(NSString*)name inClass:(Class)clazz type:(ISSPropertyType)type selector:(SEL)selector parameterTransformers:(NSArray<ISSPropertyParameterTransformer>*)parameterTransformers {
    return [self registerProperty:[[ISSPropertyDefinition alloc] initParameterizedPropertyWithName:name inClass:clazz type:type selector:selector parameterTransformers:parameterTransformers] inClass:clazz];
}

- (ISSPropertyDefinition*) registerPropertyWithName:(NSString*)name inClass:(Class)clazz type:(ISSPropertyType)type setterBlock:(ISSPropertySetterBlock)setter {
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

    BOOL result = property.setterBlock(property, targetElement.uiElement, value, propertyValue.parameters);

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



        #if ISS_OS_VERSION_MIN_REQUIRED < 90000
        NSDictionary* controlStateParametersValues = @{@"normal" : @(UIControlStateNormal), @"highlighted" :
                                                           @(UIControlStateNormal), @"selected" : @(UIControlStateSelected), @"disabled" : @(UIControlStateDisabled)};
        #else
        NSDictionary* controlStateParametersValues = @{@"normal" : @(UIControlStateNormal), @"focused" : @(UIControlStateFocused), @"highlighted" : @(UIControlStateHighlighted),
                                                       @"selected" : @(UIControlStateSelected), @"disabled" : @(UIControlStateDisabled)};
        #endif
        ISSPropertyEnumValueMapping* controlStateMapping = [[ISSPropertyEnumValueMapping alloc] initWithBitMaskEnumValues:controlStateParametersValues defaultValue:@(UIControlStateNormal)];

        ISSPropertyEnumValueMapping* contentModeMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:
                              @{@"scaletofill" : @(UIViewContentModeScaleToFill), @"scaleaspectfit" : @(UIViewContentModeScaleAspectFit),
                                @"scaleaspectfill" : @(UIViewContentModeScaleAspectFill), @"redraw" : @(UIViewContentModeRedraw), @"center" : @(UIViewContentModeCenter), @"top" : @(UIViewContentModeTop),
                                @"bottom" : @(UIViewContentModeBottom), @"left" : @(UIViewContentModeLeft), @"right" : @(UIViewContentModeRight), @"topleft" : @(UIViewContentModeTopLeft),
                                @"topright" : @(UIViewContentModeTopRight), @"bottomleft" : @(UIViewContentModeBottomLeft), @"bottomright" : @(UIViewContentModeBottomRight)} defaultValue:@(UIViewContentModeScaleToFill)];

        ISSPropertyEnumValueMapping* viewAutoresizingMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{ @"none" : @(UIViewAutoresizingNone),
                                     @"width" : @(UIViewAutoresizingFlexibleWidth), @"flexibleWidth" : @(UIViewAutoresizingFlexibleWidth),
                                     @"height" : @(UIViewAutoresizingFlexibleHeight), @"flexibleHeight" : @(UIViewAutoresizingFlexibleHeight),
                                     @"bottom" : @(UIViewAutoresizingFlexibleBottomMargin), @"flexibleBottomMargin" : @(UIViewAutoresizingFlexibleBottomMargin),
                                     @"top" : @(UIViewAutoresizingFlexibleTopMargin), @"flexibleTopMargin" : @(UIViewAutoresizingFlexibleTopMargin),
                                     @"left" : @(UIViewAutoresizingFlexibleLeftMargin), @"flexibleLeftMargin" : @(UIViewAutoresizingFlexibleLeftMargin),
                                     @"right" : @(UIViewAutoresizingFlexibleRightMargin), @"flexibleRightMargin" : @(UIViewAutoresizingFlexibleRightMargin)} defaultValue:@(UIViewAutoresizingNone)];

        ISSPropertyEnumValueMapping* tintAdjustmentModeMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"automatic" : @(UIViewTintAdjustmentModeAutomatic), @"normal" : @(UIViewTintAdjustmentModeNormal),
                                                                                                                           @"dimmed" : @(UIViewTintAdjustmentModeDimmed)} defaultValue:@(UIViewTintAdjustmentModeAutomatic)];

        ISSPropertyEnumValueMapping* barMetricsMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"metricsDefault" : @(UIBarMetricsDefault), @"metricsLandscapePhone" : @(UIBarMetricsCompact), @"metricsCompact" : @(UIBarMetricsCompact),
                                                        @"metricsLandscapePhonePrompt" : @(UIBarMetricsCompactPrompt), @"metricsCompactPrompt" : @(UIBarMetricsCompactPrompt), @"metricsDefaultPrompt" : @(UIBarMetricsDefaultPrompt)} defaultValue:@(UIBarMetricsDefault)];

        ISSPropertyEnumValueMapping* barPositionMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"barPositionAny" : @(UIBarPositionAny), @"barPositionBottom" : @(UIBarPositionBottom),
                                                        @"barPositionTop" : @(UIBarPositionTop), @"barPositionTopAttached" : @(UIBarPositionTopAttached)} defaultValue:@(UIBarPositionAny)];

        ISSPropertyEnumValueMapping* segmentTypeMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"segmentAny" : @(UISegmentedControlSegmentAny), @"segmentLeft" : @(UISegmentedControlSegmentLeft), @"segmentCenter" : @(UISegmentedControlSegmentCenter),
                                                        @"segmentRight" : @(UISegmentedControlSegmentRight), @"segmentAlone" : @(UISegmentedControlSegmentAlone)} defaultValue:@(UISegmentedControlSegmentAny)];

        ISSPropertyEnumValueMapping* dataDetectorTypesMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"all" : @(UIDataDetectorTypeAll), @"none" : @(UIDataDetectorTypeNone), @"address" : @(UIDataDetectorTypeAddress),
                                                                                                                          @"calendarEvent" : @(UIDataDetectorTypeCalendarEvent), @"link" : @(UIDataDetectorTypeLink), @"phoneNumber" : @(UIDataDetectorTypePhoneNumber)} defaultValue:@(UIDataDetectorTypeNone)];

        ISSPropertyEnumValueMapping* textAlignmentMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"left" : @(NSTextAlignmentLeft), @"center" : @(NSTextAlignmentCenter), @"right" : @(NSTextAlignmentRight)} defaultValue:@(NSTextAlignmentLeft)];
        ISSPropertyEnumValueMapping* viewModeMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"never" : @(UITextFieldViewModeNever), @"always" : @(UITextFieldViewModeAlways), @"unlessEditing" : @(UITextFieldViewModeUnlessEditing), @"whileEditing" : @(UITextFieldViewModeWhileEditing)} defaultValue:@(UITextFieldViewModeNever)];

        #if TARGET_OS_TV == 0
        ISSPropertyEnumValueMapping* barStyleMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"default" : @(UIBarStyleDefault), @"black" : @(UIBarStyleBlack),
                                                                                                                 @"blackOpaque" : @(UIBarStyleBlackOpaque), @"blackTranslucent" : @(UIBarStyleBlackTranslucent)} defaultValue:@(UIBarStyleDefault)];

        ISSPropertyEnumValueMapping* accessoryTypeMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"none" : @(UITableViewCellAccessoryNone), @"checkmark" : @(UITableViewCellAccessoryCheckmark), @"detailButton" : @(UITableViewCellAccessoryDetailButton),
                                                                                  @"disclosureButton" : @(UITableViewCellAccessoryDetailDisclosureButton), @"disclosureIndicator" : @(UITableViewCellAccessoryDisclosureIndicator)} defaultValue:@(UITableViewCellAccessoryNone)];

        NSDictionary* searchBarIconParameters = @{@"iconBookmark" : @(UISearchBarIconBookmark), @"iconClear" : @(UISearchBarIconClear),
                                                  @"iconResultsList" : @(UISearchBarIconResultsList), @"iconSearch" : @(UISearchBarIconSearch)};
        #else
        NSDictionary* searchBarIconParameters = @{@"iconSearch" : @(UISearchBarIconSearch)};
        #endif

        ISSPropertyEnumValueMapping* searchBarIconMapping = [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:searchBarIconParameters defaultValue:@(UISearchBarIconSearch)];


        if (withStandardPropertyCustomizations) {
            ISSPropertyParameterTransformer controlStateTransformer = ^(ISSPropertyDefinition* property, NSString* parameterStringValue) { return [controlStateMapping enumValueFromString:parameterStringValue]; };
            ISSPropertyParameterTransformer barMetricsTransformer = ^(ISSPropertyDefinition* property, NSString* parameterStringValue) { return [barMetricsMapping enumValueFromString:parameterStringValue]; };
            ISSPropertyParameterTransformer barPositionTransformer = ^(ISSPropertyDefinition* property, NSString* parameterStringValue) { return [barPositionMapping enumValueFromString:parameterStringValue]; };
            ISSPropertyParameterTransformer integerTransformer = ^(ISSPropertyDefinition* property, NSString* parameterStringValue) { return @([parameterStringValue integerValue]); };
            ISSPropertyParameterTransformer segmentTypeTransformer = ^(ISSPropertyDefinition* property, NSString* parameterStringValue) { return [segmentTypeMapping enumValueFromString:parameterStringValue]; };
            ISSPropertyParameterTransformer searchBarIconTransformer = ^(ISSPropertyDefinition* property, NSString* parameterStringValue) { return [searchBarIconMapping enumValueFromString:parameterStringValue]; };


            /** UIView **/
            Class clazz = UIView.class;
            [self registerPropertyWithName:@"autoresizingMask" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:viewAutoresizingMapping];
            [self registerPropertyWithName:@"contentMode" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:contentModeMapping];
            [self registerPropertyWithName:@"tintAdjustmentMode" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:tintAdjustmentModeMapping];

            /** UIControl **/
            clazz = UIControl.class;
            [self registerPropertyWithName:@"contentVerticalAlignment" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"center" : @(UIControlContentVerticalAlignmentCenter), @"top" : @(UIControlContentVerticalAlignmentTop),
                    @"bottom" : @(UIControlContentVerticalAlignmentBottom), @"fill" : @(UIControlContentVerticalAlignmentFill)} defaultValue:@(UIControlContentVerticalAlignmentTop)]];
            [self registerPropertyWithName:@"contentHorizontalAlignment" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"center" : @(UIControlContentHorizontalAlignmentCenter), @"left" : @(UIControlContentHorizontalAlignmentLeft),
                    @"right" : @(UIControlContentHorizontalAlignmentRight), @"fill" : @(UIControlContentHorizontalAlignmentFill)} defaultValue:@(UIControlContentHorizontalAlignmentCenter)]];

            /** UIButton **/
            clazz = UIButton.class;
            [self registerPropertyWithName:@"attributedTitle" inClass:clazz type:ISSPropertyTypeAttributedString selector:@selector(setAttributedTitle:forState:) parameterTransformers:@[controlStateTransformer]];
            [self registerPropertyWithName:@"backgroundImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setBackgroundImage:forState:) parameterTransformers:@[controlStateTransformer]];
            [self registerPropertyWithName:@"image" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setImage:forState:) parameterTransformers:@[controlStateTransformer]];
            [self registerPropertyWithName:@"title" inClass:clazz type:ISSPropertyTypeString selector:@selector(setTitle:forState:) parameterTransformers:@[controlStateTransformer]];
            [self registerPropertyWithName:@"titleColor" inClass:clazz type:ISSPropertyTypeColor selector:@selector(setTitleColor:forState:) parameterTransformers:@[controlStateTransformer]];
            [self registerPropertyWithName:@"titleShadowColor" inClass:clazz type:ISSPropertyTypeColor selector:@selector(setTitleShadowColor:forState:) parameterTransformers:@[controlStateTransformer]];

            /** UILabel **/
            clazz = UILabel.class;
            [self registerPropertyWithName:@"baselineAdjustment" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"none" : @(UIBaselineAdjustmentNone), @"alignBaselines" : @(UIBaselineAdjustmentAlignBaselines), @"alignCenters" : @(UIBaselineAdjustmentAlignCenters)} defaultValue:@(UIBaselineAdjustmentNone)]];
            [self registerPropertyWithName:@"lineBreakMode" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"wordWrap" : @(NSLineBreakByWordWrapping), @"wordWrapping" : @(NSLineBreakByWordWrapping),
                                                                       @"charWrap" : @(NSLineBreakByCharWrapping), @"charWrapping" : @(NSLineBreakByCharWrapping),
                                                                       @"clip" : @(NSLineBreakByClipping), @"clipping" : @(NSLineBreakByClipping),
                                                                       @"truncateHead" : @(NSLineBreakByTruncatingHead), @"truncatingHead" : @(NSLineBreakByTruncatingHead),
                                                                       @"truncateTail" : @(NSLineBreakByTruncatingTail), @"truncatingTail" : @(NSLineBreakByTruncatingTail),
                                                                       @"truncateMiddle" : @(NSLineBreakByTruncatingMiddle), @"truncatingMiddle" : @(NSLineBreakByTruncatingMiddle)} defaultValue:@(NSLineBreakByTruncatingTail)]];
            [self registerPropertyWithName:@"textAlignment" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:textAlignmentMapping];

            /** UISegmentedControl **/
            clazz = UISegmentedControl.class;
            [self registerPropertyWithName:@"backgroundImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setBackgroundImage:forState:barMetrics:) parameterTransformers:@[controlStateTransformer, barMetricsTransformer]];
            [self registerPropertyWithName:@"contentPositionAdjustment" inClass:clazz type:ISSPropertyTypeOffset selector:@selector(setContentPositionAdjustment:forSegmentType:barMetrics:) parameterTransformers:@[segmentTypeTransformer, barMetricsTransformer]];
            [self registerPropertyWithName:@"contentOffset" inClass:clazz type:ISSPropertyTypeOffset selector:@selector(setContentOffset:forSegmentAtIndex:) parameterTransformers:@[integerTransformer]];
            [self registerPropertyWithName:@"dividerImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setDividerImage:forLeftSegmentState:rightSegmentState:barMetrics:) parameterTransformers:@[controlStateTransformer, controlStateTransformer, barMetricsTransformer]];
            [self registerPropertyWithName:@"enabled" inClass:clazz type:ISSPropertyTypeBool selector:@selector(setEnabled:forSegmentAtIndex:) parameterTransformers:@[integerTransformer]];
            [self registerPropertyWithName:@"image" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setImage:forSegmentAtIndex:) parameterTransformers:@[integerTransformer]];
            [self registerPropertyWithName:@"title" inClass:clazz type:ISSPropertyTypeString selector:@selector(setTitle:forSegmentAtIndex:) parameterTransformers:@[integerTransformer]];
            [self registerPropertyWithName:@"titleTextAttributes" inClass:clazz type:ISSPropertyTypeTextAttributes selector:@selector(setTitleTextAttributes:forState:) parameterTransformers:@[controlStateTransformer]];
            [self registerPropertyWithName:@"width" inClass:clazz type:ISSPropertyTypeNumber selector:@selector(setWidth:forSegmentAtIndex:) parameterTransformers:@[integerTransformer]];

            /** UISlider **/
            clazz = UISlider.class;
            [self registerPropertyWithName:@"maximumTrackImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setMaximumTrackImage:forState:) parameterTransformers:@[controlStateTransformer]];
            [self registerPropertyWithName:@"minimumTrackImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setMinimumTrackImage:forState:) parameterTransformers:@[controlStateTransformer]];
            [self registerPropertyWithName:@"thumbImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setThumbImage:forState:) parameterTransformers:@[controlStateTransformer]];

            /** UIStepper **/
            clazz = UIStepper.class;
            [self registerPropertyWithName:@"backgroundImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setBackgroundImage:forState:) parameterTransformers:@[controlStateTransformer]];
            [self registerPropertyWithName:@"decrementImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setDecrementImage:forState:) parameterTransformers:@[controlStateTransformer]];
            [self registerPropertyWithName:@"dividerImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setDividerImage:forLeftSegmentState:rightSegmentState:) parameterTransformers:@[controlStateTransformer, controlStateTransformer]];
            [self registerPropertyWithName:@"incrementImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setIncrementImage:forState:) parameterTransformers:@[controlStateTransformer]];

            /** UIActivityIndicatorView **/
            clazz = UIActivityIndicatorView.class;
            #if TARGET_OS_TV == 1
            [self registerPropertyWithName:@"activityIndicatorViewStyle" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"white" : @(UIActivityIndicatorViewStyleWhite), @"whiteLarge" : @(UIActivityIndicatorViewStyleWhiteLarge)} defaultValue:@(UIActivityIndicatorViewStyleWhite)]];
            #else
            [self registerPropertyWithName:@"activityIndicatorViewStyle" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"gray" : @(UIActivityIndicatorViewStyleGray), @"white" : @(UIActivityIndicatorViewStyleWhite), @"whiteLarge" : @(UIActivityIndicatorViewStyleWhiteLarge)} defaultValue:@(UIActivityIndicatorViewStyleWhite)]];
            #endif
            [self registerPropertyWithName:@"animating" inClass:clazz type:ISSPropertyTypeBool setterBlock:^BOOL(ISSPropertyDefinition* property, id target, id value, NSArray* parameters) {
                [value boolValue] ? [target startAnimating] : [target stopAnimating];
                return YES;
            }];

            /** UIProgressView **/
            clazz = UIProgressView.class;
            #if TARGET_OS_TV == 0
            [self registerPropertyWithName:@"progressViewStyle" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"default" : @(UIProgressViewStyleDefault), @"bar" : @(UIProgressViewStyleBar)} defaultValue:@(UIProgressViewStyleDefault)]];
            #endif

            /** UIProgressView **/
            clazz = UITextField.class;
            [self registerPropertyWithName:@"borderStyle" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"none" : @(UITextBorderStyleNone), @"bezel" : @(UITextBorderStyleBezel), @"line" : @(UITextBorderStyleLine), @"roundedRect" : @(UITextBorderStyleRoundedRect)} defaultValue:@(UITextBorderStyleNone)]];
            [self registerPropertyWithName:@"defaultTextAttributes" inClass:clazz type:ISSPropertyTypeTextAttributes enumValueMapping:nil];
            [self registerPropertyWithName:@"leftViewMode" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:viewModeMapping];
            [self registerPropertyWithName:@"rightViewMode" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:viewModeMapping];
            [self registerPropertyWithName:@"textAlignment" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:textAlignmentMapping];

            /** UITextView **/
            clazz = UITextView.class;
            #if TARGET_OS_TV == 0
            [self registerPropertyWithName:@"dataDetectorTypes" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:dataDetectorTypesMapping];
            #endif
            [self registerPropertyWithName:@"linkTextAttributes" inClass:clazz type:ISSPropertyTypeTextAttributes enumValueMapping:nil];
            [self registerPropertyWithName:@"textAlignment" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:textAlignmentMapping];
            [self registerPropertyWithName:@"typingAttributes" inClass:clazz type:ISSPropertyTypeTextAttributes enumValueMapping:nil];

            /** UIScrollView **/
            clazz = UIScrollView.class;
            [self registerPropertyWithName:@"indicatorStyle" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"default" : @(UIScrollViewIndicatorStyleDefault), @"black" : @(UIScrollViewIndicatorStyleBlack), @"white" : @(UIScrollViewIndicatorStyleWhite)} defaultValue:@(UIScrollViewIndicatorStyleDefault)]];
            [self registerPropertyWithName:@"decelerationRate" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"normal" : @(UIScrollViewDecelerationRateNormal), @"fast" : @(UIScrollViewDecelerationRateFast)} defaultValue:@(UIScrollViewDecelerationRateNormal)]];
            [self registerPropertyWithName:@"keyboardDismissMode" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"none" : @(UIScrollViewKeyboardDismissModeNone), @"onDrag" : @(UIScrollViewKeyboardDismissModeOnDrag), @"interactive" : @(UIScrollViewKeyboardDismissModeInteractive)} defaultValue:@(UIScrollViewKeyboardDismissModeNone)]];

            /** UITableView **/
            clazz = UITableView.class;
            #if TARGET_OS_TV == 0
            [self registerPropertyWithName:@"separatorStyle" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"none" : @(UITableViewCellSeparatorStyleNone), @"singleLine" : @(UITableViewCellSeparatorStyleSingleLine), @"singleLineEtched" : @(UITableViewCellSeparatorStyleSingleLineEtched)} defaultValue:@(UITableViewCellSeparatorStyleNone)]];
            #endif

            /** UITableViewCell **/
            clazz = UITableViewCell.class;
            [self registerPropertyWithName:@"selectionStyle" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"none" : @(UITableViewCellSelectionStyleNone), @"default" : @(UITableViewCellSelectionStyleDefault), @"blue" : @(UITableViewCellSelectionStyleBlue), @"gray" : @(UITableViewCellSelectionStyleGray)} defaultValue:@(UITableViewCellSelectionStyleNone)]];
            [self registerPropertyWithName:@"editingStyle" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"none" : @(UITableViewCellEditingStyleNone), @"delete" : @(UITableViewCellEditingStyleDelete), @"insert" : @(UITableViewCellEditingStyleInsert)} defaultValue:@(UITableViewCellEditingStyleNone)]];
            #if TARGET_OS_TV == 0
            [self registerPropertyWithName:@"accessoryType" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:accessoryTypeMapping];
            [self registerPropertyWithName:@"editingAccessoryType" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:accessoryTypeMapping];
            #endif

            /** UIWebView **/
            clazz = UIWebView.class;
            #if TARGET_OS_TV == 0
            [self registerPropertyWithName:@"dataDetectorTypes" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:dataDetectorTypesMapping];
            [self registerPropertyWithName:@"paginationMode" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"unpaginated" : @(UIWebPaginationModeUnpaginated), @"lefttoright" : @(UIWebPaginationModeLeftToRight),
                    @"toptobottom" : @(UIWebPaginationModeTopToBottom), @"bottomtotop" : @(UIWebPaginationModeBottomToTop), @"righttoleft" : @(UIWebPaginationModeRightToLeft)} defaultValue:@(UIWebPaginationModeUnpaginated)]];
            [self registerPropertyWithName:@"paginationBreakingMode" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"page" : @(UIWebPaginationBreakingModePage), @"column" : @(UIWebPaginationBreakingModeColumn)} defaultValue:@(UIWebPaginationBreakingModePage)]];
            #endif

            /** UIBarItem **/
            clazz = UIBarItem.class;
            [self registerPropertyWithName:@"titleTextAttributes" inClass:clazz type:ISSPropertyTypeTextAttributes selector:@selector(setTitleTextAttributes:forState:) parameterTransformers:@[controlStateTransformer]];

            /** UIBarButtonItem **/
            clazz = UIBarButtonItem.class;
            //setBackgroundImage:forState:style:barMetrics:
            [self registerPropertyWithName:@"backButtonBackgroundImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setBackButtonBackgroundImage:forState:barMetrics:) parameterTransformers:@[controlStateTransformer, barMetricsTransformer]];
            [self registerPropertyWithName:@"backButtonBackgroundVerticalPositionAdjustment" inClass:clazz type:ISSPropertyTypeNumber selector:@selector(setBackButtonBackgroundVerticalPositionAdjustment:forBarMetrics:) parameterTransformers:@[barMetricsTransformer]];
            [self registerPropertyWithName:@"backgroundImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setBackgroundImage:forState:barMetrics:) parameterTransformers:@[controlStateTransformer, barMetricsTransformer]];
            [self registerPropertyWithName:@"backgroundVerticalPositionAdjustment" inClass:clazz type:ISSPropertyTypeNumber selector:@selector(setBackgroundVerticalPositionAdjustment:forBarMetrics:) parameterTransformers:@[barMetricsTransformer]];
            [self registerPropertyWithName:@"backButtonTitlePositionAdjustment" inClass:clazz type:ISSPropertyTypeOffset selector:@selector(setBackButtonTitlePositionAdjustment:forBarMetrics:) parameterTransformers:@[barMetricsTransformer]];
            [self registerPropertyWithName:@"style" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"plain" : @(UIBarButtonItemStylePlain), @"done" : @(UIBarButtonItemStyleDone)} defaultValue:@(UIBarButtonItemStylePlain)]];
            [self registerPropertyWithName:@"titlePositionAdjustment" inClass:clazz type:ISSPropertyTypeOffset selector:@selector(setTitlePositionAdjustment:forBarMetrics:) parameterTransformers:@[barMetricsTransformer]];


            /** UISearchBar **/
            clazz = UISearchBar.class;
            [self registerPropertyWithName:@"backgroundImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setBackgroundImage:forBarPosition:barMetrics:) parameterTransformers:@[barPositionTransformer, barMetricsTransformer]];
            #if TARGET_OS_TV == 0
            [self registerPropertyWithName:@"barStyle" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:barStyleMapping];
            #endif
            [self registerPropertyWithName:@"imageForSearchBarIcon" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setImage:forSearchBarIcon:state:) parameterTransformers:@[searchBarIconTransformer, controlStateTransformer]];
            [self registerPropertyWithName:@"positionAdjustmentForSearchBarIcon" inClass:clazz type:ISSPropertyTypeOffset selector:@selector(setPositionAdjustment:forSearchBarIcon:) parameterTransformers:@[searchBarIconTransformer]];
            [self registerPropertyWithName:@"scopeBarButtonBackgroundImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setScopeBarButtonBackgroundImage:forState:) parameterTransformers:@[controlStateTransformer]];
            [self registerPropertyWithName:@"scopeBarButtonDividerImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setScopeBarButtonDividerImage:forLeftSegmentState:rightSegmentState:) parameterTransformers:@[controlStateTransformer, controlStateTransformer]];
            #if TARGET_OS_TV == 0
            [self registerPropertyWithName:@"scopeBarButtonTitleTextAttributes" inClass:clazz type:ISSPropertyTypeTextAttributes selector:@selector(setScopeBarButtonTitleTextAttributes:forState:) parameterTransformers:@[controlStateTransformer]];
            #endif
            [self registerPropertyWithName:@"searchBarStyle" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"default" : @(UISearchBarStyleDefault), @"minimal" : @(UISearchBarStyleMinimal), @"prominent" : @(UISearchBarStyleProminent)} defaultValue:@(UISearchBarStyleDefault)]];
            [self registerPropertyWithName:@"searchFieldBackgroundImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setSearchFieldBackgroundImage:forState:) parameterTransformers:@[controlStateTransformer]];

            /** UINavigationBar **/
            clazz = UINavigationBar.class;
            [self registerPropertyWithName:@"backgroundImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setBackgroundImage:forBarPosition:barMetrics:) parameterTransformers:@[barPositionTransformer, barMetricsTransformer]];
            #if TARGET_OS_TV == 0
            [self registerPropertyWithName:@"barStyle" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:barStyleMapping];
            #endif
            [self registerPropertyWithName:@"titleTextAttributes" inClass:clazz type:ISSPropertyTypeTextAttributes enumValueMapping:nil];

            /** UIToolbar **/
            clazz = UIToolbar.class;
            [self registerPropertyWithName:@"backgroundImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setBackgroundImage:forToolbarPosition:barMetrics:) parameterTransformers:@[barPositionTransformer, barMetricsTransformer]];
            #if TARGET_OS_TV == 0
            [self registerPropertyWithName:@"barStyle" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:barStyleMapping];
            #endif
            [self registerPropertyWithName:@"shadowImage" inClass:clazz type:ISSPropertyTypeImage selector:@selector(setShadowImage:forToolbarPosition:) parameterTransformers:@[barPositionTransformer]];

            /** UITabBar **/
            clazz = UITabBar.class;
            #if TARGET_OS_TV == 0
            [self registerPropertyWithName:@"barStyle" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:barStyleMapping];
            #endif
            [self registerPropertyWithName:@"itemPositioning" inClass:clazz type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"automatic" : @(UITabBarItemPositioningAutomatic), @"centered" : @(UITabBarItemPositioningCentered), @"fill" : @(UITabBarItemPositioningFill)} defaultValue:@(UITabBarItemPositioningAutomatic)]];


            /** UITextInputTraits **/
            NSArray* classes = @[UITextField.class,  UITextView.class, UISearchBar.class];
            [self registerPropertyWithName:@"autocapitalizationType" inClasses:classes type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"none" : @(UITextAutocapitalizationTypeNone), @"allCharacters" : @(UITextAutocapitalizationTypeAllCharacters),
                     @"sentences" : @(UITextAutocapitalizationTypeSentences), @"words" : @(UITextAutocapitalizationTypeWords)} defaultValue:@(UITextAutocapitalizationTypeNone)]];
            [self registerPropertyWithName:@"autocorrectionType" inClasses:classes type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"default" : @(UITextAutocorrectionTypeDefault), @"no" : @(UITextAutocorrectionTypeNo), @"yes" : @(UITextAutocorrectionTypeYes)} defaultValue:@(UITextAutocorrectionTypeDefault)]];
            [self registerPropertyWithName:@"keyboardAppearance" inClasses:classes type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"default" : @(UIKeyboardAppearanceDefault), @"alert" : @(UIKeyboardAppearanceAlert),
                                                                       @"dark" : @(UIKeyboardAppearanceDark), @"light" : @(UIKeyboardAppearanceLight)} defaultValue:@(UIKeyboardAppearanceDefault)]];
            [self registerPropertyWithName:@"keyboardType" inClasses:classes type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"default" : @(UIKeyboardTypeDefault), @"alphabet" : @(UIKeyboardTypeAlphabet), @"asciiCapable" : @(UIKeyboardTypeASCIICapable),
                                                                       @"decimalPad" : @(UIKeyboardTypeDecimalPad), @"emailAddress" : @(UIKeyboardTypeEmailAddress), @"namePhonePad" : @(UIKeyboardTypeNamePhonePad),
                                                                       @"numberPad" : @(UIKeyboardTypeNumberPad), @"numbersAndPunctuation" : @(UIKeyboardTypeNumbersAndPunctuation), @"phonePad" : @(UIKeyboardTypePhonePad),
                                                                       @"twitter" : @(UIKeyboardTypeTwitter), @"URL" : @(UIKeyboardTypeURL), @"webSearch" : @(UIKeyboardTypeWebSearch)} defaultValue:@(UIKeyboardTypeDefault)]];
            [self registerPropertyWithName:@"returnKeyType" inClasses:classes type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"default" : @(UIReturnKeyDefault), @"go" : @(UIReturnKeyGo), @"google" : @(UIReturnKeyGoogle), @"join" : @(UIReturnKeyJoin),
                                                                       @"next" : @(UIReturnKeyNext), @"route" : @(UIReturnKeyRoute), @"search" : @(UIReturnKeySearch), @"send" : @(UIReturnKeySend),
                                                                       @"yahoo" : @(UIReturnKeyYahoo), @"done" : @(UIReturnKeyDone), @"emergencyCall" : @(UIReturnKeyEmergencyCall)} defaultValue:@(UIReturnKeyDefault)]];
            [self registerPropertyWithName:@"spellCheckingType" inClasses:classes type:ISSPropertyTypeEnumType enumValueMapping:
                [[ISSPropertyEnumValueMapping alloc] initWithEnumValues:@{@"default" : @(UITextSpellCheckingTypeDefault), @"no" : @(UITextSpellCheckingTypeNo), @"yes" : @(UITextSpellCheckingTypeYes)} defaultValue:@(UITextSpellCheckingTypeDefault)]];
        }
    }
    return self;
}

@end
