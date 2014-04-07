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
    ISSPseudoClassTypeInterfaceOrientationLandscape,
    ISSPseudoClassTypeInterfaceOrientationLandscapeLeft,
    ISSPseudoClassTypeInterfaceOrientationLandscapeRight,
    ISSPseudoClassTypeInterfaceOrientationPortrait,
    ISSPseudoClassTypeInterfaceOrientationPortraitUpright,
    ISSPseudoClassTypeInterfaceOrientationPortraitUpsideDown,
    ISSPseudoClassTypeStateEnabled,
    ISSPseudoClassTypeStateDisabled,
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

+ (ISSPseudoClassType) pseudoClassTypeFromString:(NSString*)typeAsString;

- (BOOL) matchesElement:(ISSUIElementDetails*)elementDetails;

@end
