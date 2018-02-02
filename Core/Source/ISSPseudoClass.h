//
//  ISSPseudoClass.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@class ISSElementStylingProxy, ISSStylingContext;


typedef NSString* ISSPseudoClassType NS_EXTENSIBLE_STRING_ENUM;

#if TARGET_OS_TV == 0
// User interface orientation and traits
extern ISSPseudoClassType const ISSPseudoClassTypeInterfaceOrientationLandscape;
extern ISSPseudoClassType const ISSPseudoClassTypeInterfaceOrientationLandscapeLeft;
extern ISSPseudoClassType const ISSPseudoClassTypeInterfaceOrientationLandscapeRight;
extern ISSPseudoClassType const ISSPseudoClassTypeInterfaceOrientationPortrait;
extern ISSPseudoClassType const ISSPseudoClassTypeInterfaceOrientationPortraitUpright;
extern ISSPseudoClassType const ISSPseudoClassTypeInterfaceOrientationPortraitUpsideDown;
#endif

// Device
extern ISSPseudoClassType const ISSPseudoClassTypeUserInterfaceIdiomPad;
extern ISSPseudoClassType const ISSPseudoClassTypeUserInterfaceIdiomPhone;
#if TARGET_OS_TV == 1
extern ISSPseudoClassType const ISSPseudoClassTypeUserInterfaceIdiomTV;
#endif
extern ISSPseudoClassType const ISSPseudoClassTypeMinOSVersion;
extern ISSPseudoClassType const ISSPseudoClassTypeMaxOSVersion;
extern ISSPseudoClassType const ISSPseudoClassTypeDeviceModel;
extern ISSPseudoClassType const ISSPseudoClassTypeScreenWidth;
extern ISSPseudoClassType const ISSPseudoClassTypeScreenWidthLessThan;
extern ISSPseudoClassType const ISSPseudoClassTypeScreenWidthGreaterThan;
extern ISSPseudoClassType const ISSPseudoClassTypeScreenHeight;
extern ISSPseudoClassType const ISSPseudoClassTypeScreenHeightLessThan;
extern ISSPseudoClassType const ISSPseudoClassTypeScreenHeightGreaterThan;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
extern ISSPseudoClassType const ISSPseudoClassTypeHorizontalSizeClassRegular;
extern ISSPseudoClassType const ISSPseudoClassTypeHorizontalSizeClassCompact;
extern ISSPseudoClassType const ISSPseudoClassTypeVerticalSizeClassRegular;
extern ISSPseudoClassType const ISSPseudoClassTypeVerticalSizeClassCompact;
#endif

// UI element state
extern ISSPseudoClassType const ISSPseudoClassTypeStateEnabled;
extern ISSPseudoClassType const ISSPseudoClassTypeStateDisabled;
extern ISSPseudoClassType const ISSPseudoClassTypeStateSelected;
extern ISSPseudoClassType const ISSPseudoClassTypeStateHighlighted;

// Structural
extern ISSPseudoClassType const ISSPseudoClassTypeRoot;
extern ISSPseudoClassType const ISSPseudoClassTypeNthChild;
extern ISSPseudoClassType const ISSPseudoClassTypeNthLastChild;
extern ISSPseudoClassType const ISSPseudoClassTypeOnlyChild;
extern ISSPseudoClassType const ISSPseudoClassTypeFirstChild;
extern ISSPseudoClassType const ISSPseudoClassTypeLastChild;
extern ISSPseudoClassType const ISSPseudoClassTypeNthOfType;
extern ISSPseudoClassType const ISSPseudoClassTypeNthLastOfType;
extern ISSPseudoClassType const ISSPseudoClassTypeOnlyOfType;
extern ISSPseudoClassType const ISSPseudoClassTypeFirstOfType;
extern ISSPseudoClassType const ISSPseudoClassTypeLastOfType;
extern ISSPseudoClassType const ISSPseudoClassTypeEmpty;

extern ISSPseudoClassType const ISSPseudoClassTypeUnknown;


@interface ISSPseudoClass : NSObject

@property (nonatomic, readonly) NSString* displayDescription;

- (instancetype) initStructuralPseudoClassWithA:(NSInteger)a b:(NSInteger)b type:(ISSPseudoClassType)pseudoClassType;
- (instancetype) initPseudoClassWithParameter:(nullable NSString*)parameter type:(ISSPseudoClassType)pseudoClassType;

- (BOOL) matchesElement:(ISSElementStylingProxy*)elementDetails stylingContext:(ISSStylingContext*)stylingContext;

@end


NS_ASSUME_NONNULL_END
