//
//  ISSLayout.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2015-01-24.
//  Copyright (c) 2015 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSRectValue.h"


extern NSString* const ISSLayoutAttributeRelationParent;
extern NSString* const ISSLayoutAttributeRelationLayoutGuide;


/**
 * ISSLayoutAttribute
 */
typedef NS_ENUM(NSInteger, ISSLayoutAttribute) {
    ISSLayoutAttributeDefault     = 0,

    ISSLayoutAttributeWidth         = 0x11,
    ISSLayoutAttributeRight         = 0x12,
    ISSLayoutAttributeRightMargin   = 0x52,
    ISSLayoutAttributeLeft          = 0x14,
    ISSLayoutAttributeLeftMargin    = 0x54,
    ISSLayoutAttributeCenterX       = 0x16,
//    ISSLayoutAttributeBaseline // TODO: Support for this will possibly be added in the future.

    ISSLayoutAttributeHeight        = 0x31,
    ISSLayoutAttributeTop           = 0x32,
    ISSLayoutAttributeTopMargin     = 0x62,
    ISSLayoutAttributeBottom        = 0x34,
    ISSLayoutAttributeBottomMargin  = 0x64,
    ISSLayoutAttributeCenterY       = 0x36
};

typedef NS_ENUM(NSInteger, ISSLayoutGuide) {
    ISSLayoutGuideTop = ISSLayoutAttributeTop,
    ISSLayoutGuideBottom = ISSLayoutAttributeBottom,
    ISSLayoutGuideCenter = ISSLayoutAttributeCenterY, // Position with equal distance to top and bottom layout guide
};

typedef NS_ENUM(NSInteger, ISSLayoutType) {
    ISSLayoutTypeStandard,
    ISSLayoutTypeSizeToFit,
};


/**
 * ISSLayoutAttributeValue
 */
@interface ISSLayoutAttributeValue : NSObject

@property (nonatomic, readonly) ISSLayoutAttribute targetAttribute;

@property (nonatomic, strong, readonly) NSString* relativeElementId;
@property (nonatomic, readonly) ISSLayoutAttribute relativeAttribute;

@property (nonatomic) CGFloat multiplier;
@property (nonatomic) CGFloat constant;

@property (nonatomic, readonly) BOOL isConstantValue;
@property (nonatomic, readonly) BOOL isParentRelativeValue;
@property (nonatomic, readonly) BOOL isLayoutGuideValue;
@property (nonatomic, readonly) BOOL isRelativeToLayoutMargin;

+ (ISSLayoutAttributeValue*) constantValue:(CGFloat)constant;
+ (ISSLayoutAttributeValue*) valueRelativeToAttributeInParent:(ISSLayoutAttribute)attribute multiplier:(CGFloat)multiplier constant:(CGFloat)constant;
+ (ISSLayoutAttributeValue*) valueRelativeToAttribute:(ISSLayoutAttribute)attribute inElement:(NSString*)elementId multiplier:(CGFloat)multiplier constant:(CGFloat)constant;
+ (ISSLayoutAttributeValue*) valueRelativeToLayoutGuide:(ISSLayoutGuide)guide multiplier:(CGFloat)multiplier constant:(CGFloat)constant;

@end


/**
 * ISSLayout
 */
@interface ISSLayout : NSObject

@property (nonatomic) ISSLayoutType layoutType;

+ (NSArray*) attributeNames;
+ (NSString*) attributeToString:(ISSLayoutAttribute)attribute;
+ (ISSLayoutAttribute) attributeFromString:(NSString*)string;
+ (ISSLayoutGuide) layoutGuideFromString:(NSString*)string;

@property (nonatomic, readonly) NSArray* layoutAttributeValues;
- (ISSLayoutAttributeValue*) valueForLayoutAttribute:(ISSLayoutAttribute)attribute;

- (void) setLayoutAttributeValue:(ISSLayoutAttributeValue*)attributeValue forTargetAttribute:(ISSLayoutAttribute)targetAttribute;
- (void) setLayoutAttributeValue:(ISSLayoutAttributeValue*)value;

- (void) removeLayoutAttributeValue:(ISSLayoutAttributeValue*)attributeValue;
- (void) removeValueForLayoutAttribute:(ISSLayoutAttribute)attribute;
- (void) removeValuesForLayoutAttributes:(NSArray*)attributes;

- (BOOL) resolveRectForView:(UIView*)view withResolvedElements:(NSDictionary*)elementMappings andLayoutGuideInsets:(UIEdgeInsets)layoutGuideInsets;

@end
