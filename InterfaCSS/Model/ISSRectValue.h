//
//  ISSRectValue.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, ISSRectValueType) {
    ISSRectValueTypeStandard,
    ISSRectValueTypeParentInsets,
    ISSRectValueTypeParentRelative,
    ISSRectValueTypeParentRelativeSizeToFit,
    ISSRectValueTypeWindowInsets,
};


extern CGFloat const ISSRectValueAuto;


@interface ISSRectValue : NSObject

@property (nonatomic, readonly) ISSRectValueType type;
@property (nonatomic, readonly) CGRect rect;
@property (nonatomic, readonly) UIEdgeInsets insets;

+ (ISSRectValue*) zeroRect;
+ (ISSRectValue*) rectWithRect:(CGRect)rect;

+ (ISSRectValue*) parentRect;
+ (ISSRectValue*) parentInsetRectWithSize:(CGSize)size;
+ (ISSRectValue*) parentInsetRectWithInsets:(UIEdgeInsets)insets;
+ (ISSRectValue*) parentRelativeRectWithSize:(CGSize)size relativeWidth:(BOOL)relativeWidth relativeHeight:(BOOL)relativeHeight;
+ (ISSRectValue*) parentRelativeSizeToFitRectWithSize:(CGSize)size relativeWidth:(BOOL)relativeWidth relativeHeight:(BOOL)relativeHeight;

+ (ISSRectValue*) windowRect;
+ (ISSRectValue*) windowInsetRectWithSize:(CGSize)size;
+ (ISSRectValue*) windowInsetRectWithInsets:(UIEdgeInsets)insets;

- (void) setLeftInset:(CGFloat)inset relative:(BOOL)relative;
- (void) setRightInset:(CGFloat)inset relative:(BOOL)relative;
- (void) setTopInset:(CGFloat)inset relative:(BOOL)relative;
- (void) setBottomInset:(CGFloat)inset relative:(BOOL)relative;

- (CGRect) rectForView:(UIView*)view;

@end


NS_ASSUME_NONNULL_END
