//
//  ISSPseudoClass.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSPseudoClass.h"

#import "ISSStylingManager.h"

#import "ISSElementStylingProxy.h"
#import "ISSStylingContext.h"

#import "UIDevice+ISSAdditions.h"
#import "ISSMacros.h"


#if TARGET_OS_TV == 0
// User interface orientation and traits
ISSPseudoClassType const ISSPseudoClassTypeInterfaceOrientationLandscape = @"landscape";
ISSPseudoClassType const ISSPseudoClassTypeInterfaceOrientationLandscapeLeft = @"landscapeleft";
ISSPseudoClassType const ISSPseudoClassTypeInterfaceOrientationLandscapeRight = @"landscaperight";
ISSPseudoClassType const ISSPseudoClassTypeInterfaceOrientationPortrait = @"portrait";
ISSPseudoClassType const ISSPseudoClassTypeInterfaceOrientationPortraitUpright = @"portraitupright";
ISSPseudoClassType const ISSPseudoClassTypeInterfaceOrientationPortraitUpsideDown = @"portraitupsidedown";
#endif

// Device
ISSPseudoClassType const ISSPseudoClassTypeUserInterfaceIdiomPad = @"pad";
ISSPseudoClassType const ISSPseudoClassTypeUserInterfaceIdiomPhone = @"phone";
#if TARGET_OS_TV == 1
ISSPseudoClassType const ISSPseudoClassTypeUserInterfaceIdiomTV = @"tv";
#endif
ISSPseudoClassType const ISSPseudoClassTypeMinOSVersion = @"minosversion";
ISSPseudoClassType const ISSPseudoClassTypeMaxOSVersion = @"maxosversion";
ISSPseudoClassType const ISSPseudoClassTypeDeviceModel = @"devicemodel";
ISSPseudoClassType const ISSPseudoClassTypeScreenWidth = @"screenwidth";
ISSPseudoClassType const ISSPseudoClassTypeScreenWidthLessThan = @"screenwidthlessthan";
ISSPseudoClassType const ISSPseudoClassTypeScreenWidthGreaterThan = @"screenwidthgreaterthan";
ISSPseudoClassType const ISSPseudoClassTypeScreenHeight = @"screenheight";
ISSPseudoClassType const ISSPseudoClassTypeScreenHeightLessThan = @"screenheightlessthan";
ISSPseudoClassType const ISSPseudoClassTypeScreenHeightGreaterThan = @"screenheightgreaterthan";

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
ISSPseudoClassType const ISSPseudoClassTypeHorizontalSizeClassRegular = @"regularwidth";
ISSPseudoClassType const ISSPseudoClassTypeHorizontalSizeClassCompact = @"compactwidth";
ISSPseudoClassType const ISSPseudoClassTypeVerticalSizeClassRegular = @"regularheight";
ISSPseudoClassType const ISSPseudoClassTypeVerticalSizeClassCompact = @"compactheight";
#endif

// UI element state
ISSPseudoClassType const ISSPseudoClassTypeStateEnabled = @"enabled";
ISSPseudoClassType const ISSPseudoClassTypeStateDisabled = @"disabled";
ISSPseudoClassType const ISSPseudoClassTypeStateSelected = @"selected";
ISSPseudoClassType const ISSPseudoClassTypeStateHighlighted = @"highlighted";

// Structural
ISSPseudoClassType const ISSPseudoClassTypeRoot = @"root";
ISSPseudoClassType const ISSPseudoClassTypeNthChild = @"nthchild";
ISSPseudoClassType const ISSPseudoClassTypeNthLastChild = @"nthlastchild";
ISSPseudoClassType const ISSPseudoClassTypeOnlyChild = @"onlychild";
ISSPseudoClassType const ISSPseudoClassTypeFirstChild = @"firstchild";
ISSPseudoClassType const ISSPseudoClassTypeLastChild = @"lastchild";
ISSPseudoClassType const ISSPseudoClassTypeNthOfType = @"nthoftype";
ISSPseudoClassType const ISSPseudoClassTypeNthLastOfType = @"nthlastoftype";
ISSPseudoClassType const ISSPseudoClassTypeOnlyOfType = @"onlyoftype";
ISSPseudoClassType const ISSPseudoClassTypeFirstOfType = @"firstoftype";
ISSPseudoClassType const ISSPseudoClassTypeLastOfType = @"lastoftype";
ISSPseudoClassType const ISSPseudoClassTypeEmpty = @"empty";

ISSPseudoClassType const ISSPseudoClassTypeUnknown = @"unknown";


/**
 * See http://www.w3.org/TR/selectors/#structural-pseudos for a description of the a & p parameters.
 */
@implementation ISSPseudoClass {
    NSString* _parameter;
    NSInteger _a, _b;
    ISSPseudoClassType _pseudoClassType;
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


#pragma mark - Internal pseudo class matching helpers

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

- (UIInterfaceOrientation) currentInterfaceOrientationForDevice:(ISSElementStylingProxy*)elementDetails {
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


#pragma mark - ISSPseudoClass

- (BOOL) matchesElement:(ISSElementStylingProxy*)elementDetails stylingContext:(ISSStylingContext*)stylingContext {
    id uiElement = elementDetails.uiElement;
    ISSPseudoClassType t = _pseudoClassType;
    
    if ( t == ISSPseudoClassTypeInterfaceOrientationLandscape ) return UIInterfaceOrientationIsLandscape([self currentInterfaceOrientationForDevice:elementDetails]);
    else if ( t == ISSPseudoClassTypeInterfaceOrientationLandscapeLeft ) return [self currentInterfaceOrientationForDevice:elementDetails] == UIInterfaceOrientationLandscapeLeft;
    else if ( t == ISSPseudoClassTypeInterfaceOrientationLandscapeRight ) return [self currentInterfaceOrientationForDevice:elementDetails] == UIInterfaceOrientationLandscapeRight;
    else if ( t == ISSPseudoClassTypeInterfaceOrientationPortrait ) return UIInterfaceOrientationIsPortrait([self currentInterfaceOrientationForDevice:elementDetails]);
    else if ( t == ISSPseudoClassTypeInterfaceOrientationPortraitUpright ) return [self currentInterfaceOrientationForDevice:elementDetails] == UIInterfaceOrientationPortrait;
    else if ( t == ISSPseudoClassTypeInterfaceOrientationPortraitUpsideDown ) return [self currentInterfaceOrientationForDevice:elementDetails] == UIInterfaceOrientationPortraitUpsideDown;
    
    else if ( t == ISSPseudoClassTypeUserInterfaceIdiomPad ) return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
    else if ( t == ISSPseudoClassTypeUserInterfaceIdiomPhone ) return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
    #if TARGET_OS_TV == 1
    else if ( t == ISSPseudoClassTypeUserInterfaceIdiomTV) return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomTV;
    #endif
             
    else if ( t == ISSPseudoClassTypeMinOSVersion ) return [UIDevice iss_versionGreaterOrEqualTo:_parameter];
    else if ( t == ISSPseudoClassTypeMaxOSVersion ) return [UIDevice iss_versionLessOrEqualTo:_parameter];
    else if ( t == ISSPseudoClassTypeDeviceModel ) return [[UIDevice iss_deviceModelId] hasPrefix:_parameter];
    else if ( t == ISSPseudoClassTypeScreenWidth ) return ISS_ISEQUAL_FLT(self.screenNativeWidth, [_parameter floatValue]);
    else if ( t == ISSPseudoClassTypeScreenWidthLessThan ) return self.screenNativeWidth < [_parameter floatValue];
    else if ( t == ISSPseudoClassTypeScreenWidthGreaterThan ) return self.screenNativeWidth > [_parameter floatValue];
    else if ( t == ISSPseudoClassTypeScreenHeight ) return ISS_ISEQUAL_FLT(self.screenNativeHeight, [_parameter floatValue]);
    else if ( t == ISSPseudoClassTypeScreenHeightLessThan ) return self.screenNativeHeight < [_parameter floatValue];
    else if ( t == ISSPseudoClassTypeScreenHeightGreaterThan ) return self.screenNativeHeight > [_parameter floatValue];

    #if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    else if ( t == ISSPseudoClassTypeHorizontalSizeClassRegular ) return [elementDetails.view respondsToSelector:@selector(traitCollection)] && elementDetails.view.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular;
    else if ( t == ISSPseudoClassTypeHorizontalSizeClassCompact ) return [elementDetails.view respondsToSelector:@selector(traitCollection)] && elementDetails.view.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;
    else if ( t == ISSPseudoClassTypeVerticalSizeClassRegular ) return [elementDetails.view respondsToSelector:@selector(traitCollection)] && elementDetails.view.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular;
    else if ( t == ISSPseudoClassTypeVerticalSizeClassCompact ) return [elementDetails.view respondsToSelector:@selector(traitCollection)] && elementDetails.view.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact;
    #endif

    else if ( t == ISSPseudoClassTypeStateEnabled ) return [uiElement respondsToSelector:@selector(isEnabled)] && [uiElement isEnabled];
    else if ( t == ISSPseudoClassTypeStateDisabled ) return [uiElement respondsToSelector:@selector(isEnabled)] && ![uiElement isEnabled];
    else if ( t == ISSPseudoClassTypeStateSelected ) return [uiElement respondsToSelector:@selector(isSelected)] && [uiElement isSelected];
    else if ( t == ISSPseudoClassTypeStateHighlighted ) return [uiElement respondsToSelector:@selector(isHighlighted)] && [uiElement isHighlighted];
    
    else if ( t == ISSPseudoClassTypeRoot ) return elementDetails.parentViewController != nil;
    else if ( t == ISSPseudoClassTypeNthChild || t == ISSPseudoClassTypeFirstChild ) {
        if( elementDetails.parentView ) return [self matchesIndex:[elementDetails.parentView.subviews indexOfObject:uiElement] count:elementDetails.parentView.subviews.count reverse:NO];
        else return NO;
    }
    else if ( t == ISSPseudoClassTypeNthLastChild || t == ISSPseudoClassTypeLastChild ) {
        if( elementDetails.parentView ) return [self matchesIndex:[elementDetails.parentView.subviews indexOfObject:uiElement] count:elementDetails.parentView.subviews.count reverse:YES];
        else return NO;
    }
    else if ( t == ISSPseudoClassTypeOnlyChild ) {
        return elementDetails.parentView.subviews.count == 1;
    }
    else if ( t == ISSPseudoClassTypeNthOfType || t == ISSPseudoClassTypeFirstOfType || t == ISSPseudoClassTypeNthLastOfType || t == ISSPseudoClassTypeLastOfType ) {
        NSInteger position, count;
        [stylingContext.stylingManager typeQualifiedPositionInParentForElement:elementDetails position:&position count:&count];
        return [self matchesIndex:position count:count reverse:(_pseudoClassType == ISSPseudoClassTypeNthLastOfType || _pseudoClassType == ISSPseudoClassTypeLastOfType)];
    }
    else if ( t == ISSPseudoClassTypeOnlyOfType ) {
        NSInteger position, count;
        [stylingContext.stylingManager typeQualifiedPositionInParentForElement:elementDetails position:&position count:&count];
        return position == 0 && count == 1;
    }
    else if ( t == ISSPseudoClassTypeEmpty ) return elementDetails.view.subviews.count == 0;

    return NO;
}

- (NSString*) displayDescription {
    ISSPseudoClassType t = _pseudoClassType;
    BOOL stucturalParameterized = !(t == ISSPseudoClassTypeRoot || t == ISSPseudoClassTypeOnlyChild || t == ISSPseudoClassTypeFirstChild || t == ISSPseudoClassTypeLastChild ||
        t == ISSPseudoClassTypeOnlyOfType || t == ISSPseudoClassTypeFirstOfType || t == ISSPseudoClassTypeLastOfType || t == ISSPseudoClassTypeEmpty);
    
    if( stucturalParameterized && (_a != 0 || _b != 0) ) {
        NSString* bSign = _b < 0 ? @"" : @"+";
        return [NSString stringWithFormat:@"%@(%ldn%@%ld)", _pseudoClassType, (long)_a, bSign, (long)_b];
    } else if (_parameter) {
        return [NSString stringWithFormat:@"%@(%@)", _pseudoClassType, _parameter];
    } else {
        return [NSString stringWithFormat:@"%@", _pseudoClassType];
    }
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
