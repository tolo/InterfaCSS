//
//  ISSPseudoClass.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-03-02.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

@class ISSUIElementDetails;

typedef NS_ENUM(NSInteger, ISSPseudoClassType) {
    // User interface orientation and traits
    ISSPseudoClassTypeInterfaceOrientationLandscape,
    ISSPseudoClassTypeInterfaceOrientationLandscapeLeft,
    ISSPseudoClassTypeInterfaceOrientationLandscapeRight,
    ISSPseudoClassTypeInterfaceOrientationPortrait,
    ISSPseudoClassTypeInterfaceOrientationPortraitUpright,
    ISSPseudoClassTypeInterfaceOrientationPortraitUpsideDown,
    ISSPseudoClassTypeUserInterfaceIdiomPad,
    ISSPseudoClassTypeUserInterfaceIdiomPhone,

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

- (instancetype) initWithA:(NSInteger)a b:(NSInteger)b type:(ISSPseudoClassType)pseudoClassType;
+ (instancetype) pseudoClassWithA:(NSInteger)a b:(NSInteger)b type:(ISSPseudoClassType)pseudoClassType;
+ (instancetype) pseudoClassWithType:(ISSPseudoClassType)pseudoClassType;
+ (instancetype) pseudoClassWithTypeString:(NSString*)typeAsString;

+ (ISSPseudoClassType) pseudoClassTypeFromString:(NSString*)typeAsString;

- (BOOL) matchesElement:(ISSUIElementDetails*)elementDetails;

@end
