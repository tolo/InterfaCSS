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


@class ISSUIElementDetails;

typedef NS_ENUM(NSInteger, ISSPseudoClassType) {
#if TARGET_OS_TV == 0
    // User interface orientation and traits
    ISSPseudoClassTypeInterfaceOrientationLandscape,
    ISSPseudoClassTypeInterfaceOrientationLandscapeLeft,
    ISSPseudoClassTypeInterfaceOrientationLandscapeRight,
    ISSPseudoClassTypeInterfaceOrientationPortrait,
    ISSPseudoClassTypeInterfaceOrientationPortraitUpright,
    ISSPseudoClassTypeInterfaceOrientationPortraitUpsideDown,
#endif

    // Device
    ISSPseudoClassTypeUserInterfaceIdiomPad,
    ISSPseudoClassTypeUserInterfaceIdiomPhone,
#if TARGET_OS_TV == 1
    ISSPseudoClassTypeUserInterfaceIdiomTV,
#endif
    ISSPseudoClassTypeMinOSVersion,
    ISSPseudoClassTypeMaxOSVersion,
    ISSPseudoClassTypeDeviceModel,
    ISSPseudoClassTypeScreenWidth,
    ISSPseudoClassTypeScreenWidthLessThan,
    ISSPseudoClassTypeScreenWidthGreaterThan,
    ISSPseudoClassTypeScreenHeight,
    ISSPseudoClassTypeScreenHeightLessThan,
    ISSPseudoClassTypeScreenHeightGreaterThan,

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    ISSPseudoClassTypeHorizontalSizeClassRegular,
    ISSPseudoClassTypeHorizontalSizeClassCompact,
    ISSPseudoClassTypeVerticalSizeClassRegular,
    ISSPseudoClassTypeVerticalSizeClassCompact,
#endif

    // UI element state
    ISSPseudoClassTypeStateEnabled,
    ISSPseudoClassTypeStateDisabled,
    ISSPseudoClassTypeStateSelected,
    ISSPseudoClassTypeStateHighlighted,

    // Structural
    ISSPseudoClassTypeRoot,
    ISSPseudoClassTypeNthChild,
    ISSPseudoClassTypeNthLastChild,
    ISSPseudoClassTypeOnlyChild,
    ISSPseudoClassTypeFirstChild,
    ISSPseudoClassTypeLastChild,
    ISSPseudoClassTypeNthOfType,
    ISSPseudoClassTypeNthLastOfType,
    ISSPseudoClassTypeOnlyOfType,
    ISSPseudoClassTypeFirstOfType,
    ISSPseudoClassTypeLastOfType,
    ISSPseudoClassTypeEmpty
};

@interface ISSPseudoClass : NSObject

@property (nonatomic, readonly) NSString* displayDescription;

- (instancetype) initStructuralPseudoClassWithA:(NSInteger)a b:(NSInteger)b type:(ISSPseudoClassType)pseudoClassType;
+ (instancetype) structuralPseudoClassWithA:(NSInteger)a b:(NSInteger)b type:(ISSPseudoClassType)pseudoClassType;
+ (instancetype) pseudoClassWithType:(ISSPseudoClassType)pseudoClassType;
+ (instancetype) pseudoClassWithType:(ISSPseudoClassType)pseudoClassType andParameter:(NSString*)parameter;
+ (instancetype) pseudoClassWithTypeString:(NSString*)typeAsString;
+ (instancetype) pseudoClassWithTypeString:(NSString*)typeAsString andParameter:(NSString*)parameter;

+ (ISSPseudoClassType) pseudoClassTypeFromString:(NSString*)typeAsString;

- (BOOL) matchesElement:(ISSUIElementDetails*)elementDetails;

@end


NS_ASSUME_NONNULL_END
