//
//  ISSPseudoClass.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-03-02.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSPseudoClass.h"

#import "ISSUIElementDetails.h"
#import "UIDevice+ISSAdditions.h"


static NSDictionary* stringToPseudoClassType;

/**
 * See http://www.w3.org/TR/selectors/#structural-pseudos for a description of the a & p parameters.
 */
@implementation ISSPseudoClass {
    NSString* _parameter;
    NSInteger _a, _b;
    ISSPseudoClassType _pseudoClassType;
}

+ (void) initialize {
    stringToPseudoClassType = @{
#if TARGET_OS_TV == 0
            @"landscape" : @(ISSPseudoClassTypeInterfaceOrientationLandscape),
            @"landscapeleft": @(ISSPseudoClassTypeInterfaceOrientationLandscapeLeft),
            @"landscaperight" : @(ISSPseudoClassTypeInterfaceOrientationLandscapeRight),
            @"portrait" : @(ISSPseudoClassTypeInterfaceOrientationPortrait),
            @"portraitupright" : @(ISSPseudoClassTypeInterfaceOrientationPortraitUpright),
            @"portraitupsidedown" : @(ISSPseudoClassTypeInterfaceOrientationPortraitUpsideDown),
#endif

            @"pad" : @(ISSPseudoClassTypeUserInterfaceIdiomPad),
            @"phone" : @(ISSPseudoClassTypeUserInterfaceIdiomPhone),
#if TARGET_OS_TV == 1
            @"tv" : @(ISSPseudoClassTypeUserInterfaceIdiomTV),
#endif

            @"minosversion" : @(ISSPseudoClassTypeMinOSVersion),
            @"maxosversion" : @(ISSPseudoClassTypeMaxOSVersion),
            @"devicemodel" : @(ISSPseudoClassTypeDeviceModel),
            @"screenwidth" : @(ISSPseudoClassTypeScreenWidth),
            @"screenwidthlessthan" : @(ISSPseudoClassTypeScreenWidthLessThan),
            @"screenwidthgreaterthan" : @(ISSPseudoClassTypeScreenWidthGreaterThan),
            @"screenheight" : @(ISSPseudoClassTypeScreenHeight),
            @"screenheightlessthan" : @(ISSPseudoClassTypeScreenHeightLessThan),
            @"screenheightgreaterthan" : @(ISSPseudoClassTypeScreenHeightGreaterThan),

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
            @"regularwidth" : @(ISSPseudoClassTypeHorizontalSizeClassRegular),
            @"compactwidth" : @(ISSPseudoClassTypeHorizontalSizeClassCompact),
            @"regularheight" : @(ISSPseudoClassTypeVerticalSizeClassRegular),
            @"compactheight" : @(ISSPseudoClassTypeVerticalSizeClassCompact),
#endif

            @"enabled" : @(ISSPseudoClassTypeStateEnabled),
            @"disabled" : @(ISSPseudoClassTypeStateDisabled),
            @"selected" : @(ISSPseudoClassTypeStateSelected),
            @"highlighted" : @(ISSPseudoClassTypeStateHighlighted),

            @"root" : @(ISSPseudoClassTypeRoot),
            @"nthchild" : @(ISSPseudoClassTypeNthChild),
            @"nthlastchild" : @(ISSPseudoClassTypeNthLastChild),
            @"onlychild" : @(ISSPseudoClassTypeOnlyChild),
            @"firstchild" : @(ISSPseudoClassTypeFirstChild),
            @"lastchild" : @(ISSPseudoClassTypeLastChild),
            @"nthoftype" : @(ISSPseudoClassTypeNthOfType),
            @"nthlastoftype" : @(ISSPseudoClassTypeNthLastOfType),
            @"onlyoftype" : @(ISSPseudoClassTypeOnlyOfType),
            @"firstoftype" : @(ISSPseudoClassTypeFirstOfType),
            @"lastoftype" : @(ISSPseudoClassTypeLastOfType),
            @"empty" : @(ISSPseudoClassTypeEmpty)
    };
}

- (instancetype) initStructuralPseudoClassWithA:(NSInteger)a b:(NSInteger)b type:(ISSPseudoClassType)pseudoClassType {
    if ( self = [super init] ) {
        if( (pseudoClassType == ISSPseudoClassTypeFirstChild) || (pseudoClassType == ISSPseudoClassTypeLastChild) ||
            (pseudoClassType == ISSPseudoClassTypeFirstOfType) || (pseudoClassType == ISSPseudoClassTypeLastOfType) ) {
            _a = 0;
            _b = 1;
        } else {
            _a = a;
            _b = b;
        }
        _pseudoClassType = pseudoClassType;
    }

    return self;
}

- (instancetype) initPseudoClassWithParameter:(NSString*)parameter type:(ISSPseudoClassType)pseudoClassType {
    if ( self = [self initStructuralPseudoClassWithA:0 b:0 type:pseudoClassType] ) {
        if( pseudoClassType == ISSPseudoClassTypeDeviceModel ) _parameter = [_parameter lowercaseString];
        else _parameter = parameter;
    }
    return self;
}

+ (instancetype) structuralPseudoClassWithA:(NSInteger)a b:(NSInteger)b type:(ISSPseudoClassType)pseudoClassType {
    return [[self alloc] initStructuralPseudoClassWithA:a b:b type:pseudoClassType];
}

+ (instancetype) pseudoClassWithType:(ISSPseudoClassType)pseudoClassType andParameter:(NSString*)parameter {
    return [[self alloc] initPseudoClassWithParameter:parameter type:pseudoClassType];
}

+ (instancetype) pseudoClassWithType:(ISSPseudoClassType)pseudoClassType {
    return [[self alloc] initStructuralPseudoClassWithA:0 b:0 type:pseudoClassType];
}

+ (instancetype) pseudoClassWithTypeString:(NSString*)typeAsString {
    return [[self alloc] initStructuralPseudoClassWithA:0 b:0 type:[self pseudoClassTypeFromString:typeAsString]];
}

+ (instancetype) pseudoClassWithTypeString:(NSString*)typeAsString andParameter:(NSString*)parameter {
    return [self pseudoClassWithType:[self pseudoClassTypeFromString:typeAsString] andParameter:parameter];
}

+ (ISSPseudoClassType) pseudoClassTypeFromString:(NSString*)typeAsString {
    typeAsString = [typeAsString stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSNumber* b = typeAsString ? stringToPseudoClassType[typeAsString.lowercaseString] : nil;
    if( b ) return (ISSPseudoClassType)b.integerValue;
    else @throw([NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Invalid enum class type: %@", typeAsString] userInfo:nil]);
}

- (BOOL) matchesIndex:(NSInteger)indexInParent count:(NSInteger)n reverse:(BOOL)reverse {
    if( indexInParent != NSNotFound ) {
        for(NSInteger i=1; i<=n; i++) {
            NSInteger index = (i-1)*_a + _b - 1;
            if( reverse ) index = n-1 - index;
            if( index == indexInParent ) {
                return YES;
            }
        }
    }
    return NO;
}

#if TARGET_OS_TV == 0
- (NSString*) interfaceOrientationToString:(UIInterfaceOrientation)orientation {
    switch (orientation) {
        case UIInterfaceOrientationPortrait: return @"UIInterfaceOrientationPortrait";
        case UIInterfaceOrientationPortraitUpsideDown: return @"UIInterfaceOrientationPortraitUpsideDown";
        case UIInterfaceOrientationLandscapeLeft: return @"UIInterfaceOrientationLandscapeLeft";
        case UIInterfaceOrientationLandscapeRight: return @"UIInterfaceOrientationLandscapeRight";
        default: return @"UIInterfaceOrientationUnknown";
    }
}

- (UIInterfaceOrientation) currentInterfaceOrientationForDevice:(ISSUIElementDetails*)elementDetails {
    // Transform device orientation into interface orientation
    UIInterfaceOrientation orientation = UIInterfaceOrientationUnknown;
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if( UIDeviceOrientationIsValidInterfaceOrientation(deviceOrientation) ) {
        switch( deviceOrientation ) {
            case UIDeviceOrientationLandscapeLeft : orientation = UIInterfaceOrientationLandscapeRight; break;
            case UIDeviceOrientationLandscapeRight : orientation = UIInterfaceOrientationLandscapeLeft; break;
            case UIDeviceOrientationPortraitUpsideDown : orientation = UIInterfaceOrientationPortraitUpsideDown; break;
            default: orientation = UIInterfaceOrientationPortrait;
        }
    }
    
    // Setup set with valid interface orienrations for application
    static NSSet* supportedInterfaceOrientations;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray* supportedInterfaceOrientationsArray = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UISupportedInterfaceOrientations"];
        if( supportedInterfaceOrientationsArray.count ) supportedInterfaceOrientations = [NSSet setWithArray:supportedInterfaceOrientationsArray];
        else supportedInterfaceOrientations = nil;
    });
    
    // Validate interface orientation
    static UIInterfaceOrientation lastValidInterfaceOrientation = UIInterfaceOrientationUnknown;
    if( !supportedInterfaceOrientations || [supportedInterfaceOrientations containsObject:[self interfaceOrientationToString:orientation]] ) {
        lastValidInterfaceOrientation = orientation;
        if( elementDetails.closestViewController && ((elementDetails.closestViewController.supportedInterfaceOrientations & (1 << orientation)) == 0) ) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
            return elementDetails.closestViewController.interfaceOrientation; // If orientation is not supported by vc - use last good one
#pragma GCC diagnostic pop            
        } else {
            return orientation;
        }
    }
    else return lastValidInterfaceOrientation;
    
}
#endif

- (CGFloat) screenNativeWidth {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    return [UIScreen mainScreen].nativeBounds.size.width / [UIScreen mainScreen].nativeScale;
#else
    return MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
#endif
}

- (CGFloat) screenNativeHeight {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    return [UIScreen mainScreen].nativeBounds.size.height / [UIScreen mainScreen].nativeScale;
#else
    return MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
#endif
}

- (BOOL) matchesElement:(ISSUIElementDetails*)elementDetails {
    id uiElement = elementDetails.uiElement;
    switch( _pseudoClassType ) {
#if TARGET_OS_TV == 0
        case ISSPseudoClassTypeInterfaceOrientationLandscape: return UIInterfaceOrientationIsLandscape([self currentInterfaceOrientationForDevice:elementDetails]);
        case ISSPseudoClassTypeInterfaceOrientationLandscapeLeft: return [self currentInterfaceOrientationForDevice:elementDetails] == UIInterfaceOrientationLandscapeLeft;
        case ISSPseudoClassTypeInterfaceOrientationLandscapeRight: return [self currentInterfaceOrientationForDevice:elementDetails] == UIInterfaceOrientationLandscapeRight;
        case ISSPseudoClassTypeInterfaceOrientationPortrait: return UIInterfaceOrientationIsPortrait([self currentInterfaceOrientationForDevice:elementDetails]);
        case ISSPseudoClassTypeInterfaceOrientationPortraitUpright: return [self currentInterfaceOrientationForDevice:elementDetails] == UIInterfaceOrientationPortrait;
        case ISSPseudoClassTypeInterfaceOrientationPortraitUpsideDown: return [self currentInterfaceOrientationForDevice:elementDetails] == UIInterfaceOrientationPortraitUpsideDown;
#endif

        case ISSPseudoClassTypeUserInterfaceIdiomPad: return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
        case ISSPseudoClassTypeUserInterfaceIdiomPhone: return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
#if TARGET_OS_TV == 1
        case ISSPseudoClassTypeUserInterfaceIdiomTV: return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomTV;
#endif
        case ISSPseudoClassTypeMinOSVersion: {
            return [UIDevice iss_versionGreaterOrEqualTo:_parameter];
        }
        case ISSPseudoClassTypeMaxOSVersion: {
            return [UIDevice iss_versionLessOrEqualTo:_parameter];
        }
        case ISSPseudoClassTypeDeviceModel: {
            return [[UIDevice iss_deviceModelId] hasPrefix:_parameter];
        }
        case ISSPseudoClassTypeScreenWidth: {
            return ISS_EQUAL_FLT(self.screenNativeWidth, [_parameter floatValue]);
        }
        case ISSPseudoClassTypeScreenWidthLessThan: {
            return self.screenNativeWidth < [_parameter floatValue];
        }
        case ISSPseudoClassTypeScreenWidthGreaterThan: {
            return self.screenNativeWidth > [_parameter floatValue];
        }
        case ISSPseudoClassTypeScreenHeight: {
            return ISS_EQUAL_FLT(self.screenNativeWidth, [_parameter floatValue]);
        }
        case ISSPseudoClassTypeScreenHeightLessThan: {
            return self.screenNativeHeight < [_parameter floatValue];
        }
        case ISSPseudoClassTypeScreenHeightGreaterThan: {
            return self.screenNativeHeight > [_parameter floatValue];
        }


#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
        case ISSPseudoClassTypeHorizontalSizeClassRegular: {
            NSLog(@"elementDetails.view.traitCollection: %@", elementDetails.view.traitCollection);
            NSLog(@"elementDetails.view.traitCollection: %@", elementDetails.closestViewController.view.traitCollection);
            return [elementDetails.view respondsToSelector:@selector(traitCollection)] && elementDetails.view.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular;
        }
        case ISSPseudoClassTypeHorizontalSizeClassCompact: return [elementDetails.view respondsToSelector:@selector(traitCollection)] && elementDetails.view.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;
        case ISSPseudoClassTypeVerticalSizeClassRegular: return [elementDetails.view respondsToSelector:@selector(traitCollection)] && elementDetails.view.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular;
        case ISSPseudoClassTypeVerticalSizeClassCompact: return [elementDetails.view respondsToSelector:@selector(traitCollection)] && elementDetails.view.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact;
#endif

        case ISSPseudoClassTypeStateEnabled: {
            return [uiElement respondsToSelector:@selector(isEnabled)] && [uiElement isEnabled];
        }
        case ISSPseudoClassTypeStateDisabled: {
            return [uiElement respondsToSelector:@selector(isEnabled)] && ![uiElement isEnabled];
        }
        case ISSPseudoClassTypeStateSelected: {
            return [uiElement respondsToSelector:@selector(isSelected)] && [uiElement isSelected];
        }
        case ISSPseudoClassTypeStateHighlighted: {
            return [uiElement respondsToSelector:@selector(isHighlighted)] && [uiElement isHighlighted];
        }

        case ISSPseudoClassTypeRoot: {
            return elementDetails.parentViewController != nil;
        }
        case ISSPseudoClassTypeNthChild:
        case ISSPseudoClassTypeFirstChild: {
            if( elementDetails.parentView ) return [self matchesIndex:[elementDetails.parentView.subviews indexOfObject:uiElement] count:elementDetails.parentView.subviews.count reverse:NO];
            else return NO;
        }
        case ISSPseudoClassTypeNthLastChild:
        case ISSPseudoClassTypeLastChild: {
            if( elementDetails.parentView ) return [self matchesIndex:[elementDetails.parentView.subviews indexOfObject:uiElement] count:elementDetails.parentView.subviews.count reverse:YES];
            else return NO;
        }
        case ISSPseudoClassTypeOnlyChild: {
            return elementDetails.parentView.subviews.count == 1;
        }
        case ISSPseudoClassTypeNthOfType:
        case ISSPseudoClassTypeFirstOfType:
        case ISSPseudoClassTypeNthLastOfType:
        case ISSPseudoClassTypeLastOfType: {
            NSInteger position, count;
            [elementDetails typeQualifiedPositionInParent:&position count:&count];
            return [self matchesIndex:position count:count reverse:(_pseudoClassType == ISSPseudoClassTypeNthLastOfType || _pseudoClassType == ISSPseudoClassTypeLastOfType)];
        }
        case ISSPseudoClassTypeOnlyOfType: {
            NSInteger position, count;
            [elementDetails typeQualifiedPositionInParent:&position count:&count];
            return position == 0 && count == 1;
        }
        case ISSPseudoClassTypeEmpty: {
            return elementDetails.view.subviews.count == 0;
        }
    }
    return NO;
}

- (NSString*) displayDescription {
    NSString* bSign = _b < 0 ? @"-" : @"+";

    switch( _pseudoClassType ) {
#if TARGET_OS_TV == 0
        case ISSPseudoClassTypeInterfaceOrientationLandscape: return @"landscape";
        case ISSPseudoClassTypeInterfaceOrientationLandscapeLeft: return @"landscapeLeft";
        case ISSPseudoClassTypeInterfaceOrientationLandscapeRight: return @"landscapeRight";
        case ISSPseudoClassTypeInterfaceOrientationPortrait: return @"portrait";
        case ISSPseudoClassTypeInterfaceOrientationPortraitUpright: return @"portraitUpright";
        case ISSPseudoClassTypeInterfaceOrientationPortraitUpsideDown: return @"portraitUpsideDown";
#endif

        case ISSPseudoClassTypeUserInterfaceIdiomPad: return @"pad";
        case ISSPseudoClassTypeUserInterfaceIdiomPhone: return @"phone";
#if TARGET_OS_TV == 1
        case ISSPseudoClassTypeUserInterfaceIdiomTV: return @"tv";
#endif

        case ISSPseudoClassTypeMinOSVersion: return [NSString stringWithFormat:@"minosversion(%@)", _parameter];
        case ISSPseudoClassTypeMaxOSVersion: return [NSString stringWithFormat:@"maxosversion(%@)", _parameter];
        case ISSPseudoClassTypeDeviceModel: return [NSString stringWithFormat:@"devicemodel(%@)", _parameter];
        case ISSPseudoClassTypeScreenWidth: return [NSString stringWithFormat:@"screenwidth(%@)", _parameter];
        case ISSPseudoClassTypeScreenWidthLessThan: return [NSString stringWithFormat:@"screenwidthlessthan(%@)", _parameter];
        case ISSPseudoClassTypeScreenWidthGreaterThan: return [NSString stringWithFormat:@"screenwidthgreaterthan(%@)", _parameter];
        case ISSPseudoClassTypeScreenHeight: return [NSString stringWithFormat:@"screenheight(%@)", _parameter];
        case ISSPseudoClassTypeScreenHeightLessThan: return [NSString stringWithFormat:@"screenheightlessthan(%@)", _parameter];
        case ISSPseudoClassTypeScreenHeightGreaterThan: return [NSString stringWithFormat:@"screenheightgreaterthan(%@)", _parameter];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
        case ISSPseudoClassTypeHorizontalSizeClassRegular: return @"regularwidth";
        case ISSPseudoClassTypeHorizontalSizeClassCompact: return @"compactwidth";
        case ISSPseudoClassTypeVerticalSizeClassRegular: return @"regularheight";
        case ISSPseudoClassTypeVerticalSizeClassCompact: return @"compactheight";
#endif

        case ISSPseudoClassTypeStateEnabled: return @"enabled";
        case ISSPseudoClassTypeStateDisabled: return @"disabled";
        case ISSPseudoClassTypeStateSelected: return @"selected";
        case ISSPseudoClassTypeStateHighlighted: return @"highlighted";

        case ISSPseudoClassTypeRoot: return @"root";
        case ISSPseudoClassTypeNthChild: return [NSString stringWithFormat:@"nthchild(%ldn%@%ld)", (long)_a, bSign, (long)_b];
        case ISSPseudoClassTypeNthLastChild: return [NSString stringWithFormat:@"nthlastchild(%ldn%@%ld)", (long)_a, bSign, (long)_b];
        case ISSPseudoClassTypeOnlyChild: return @"onlychild";
        case ISSPseudoClassTypeFirstChild: return @"firstchild";
        case ISSPseudoClassTypeLastChild: return @"lastchild";
        case ISSPseudoClassTypeNthOfType: return [NSString stringWithFormat:@"nthoftype(%ldn%@%ld)", (long)_a, bSign, (long)_b];
        case ISSPseudoClassTypeNthLastOfType: return [NSString stringWithFormat:@"nthlastofyype(%ldn%@%ld)", (long)_a, bSign, (long)_b];
        case ISSPseudoClassTypeOnlyOfType: return @"onlyoftype";
        case ISSPseudoClassTypeFirstOfType: return @"firstoftype";
        case ISSPseudoClassTypeLastOfType: return @"lastoftype";
        case ISSPseudoClassTypeEmpty: return @"empty";
    }
    return @"";
}


#pragma mark - NSObject overrides

- (NSString*) description {
    return [NSString stringWithFormat:@"PseudoClass(%@)", self.displayDescription];
}

- (BOOL) isEqual:(id)object {
    if( object == self ) return YES;
    else if ( [object isKindOfClass:ISSPseudoClass.class] ) {
        ISSPseudoClass* other = (ISSPseudoClass*)object;
        return _pseudoClassType == other->_pseudoClassType && _a == other->_a && _b == other->_b;
    } else return NO;
}

- (NSUInteger) hash {
    return self.displayDescription.hash;
}

@end
