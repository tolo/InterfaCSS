//
//  ISSRectValue.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-02-10.
//  Copyright (c) 2014 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSRectValue.h"


typedef NS_OPTIONS(NSUInteger, ISSParentRelative) {
    ISSParentRelativeNone       = 0,
    ISSParentRelativeWidth      = 1 << 0,
    ISSParentRelativeHeight     = 1 << 1,
    ISSParentRelativeTop        = 1 << 2,
    ISSParentRelativeLeft       = 1 << 3,
    ISSParentRelativeBottom     = 1 << 4,
    ISSParentRelativeRight      = 1 << 5
};


CGFloat const ISSRectValueAuto = CGFLOAT_MIN;


@implementation ISSRectValue {
    ISSParentRelative _parentRelativeMask;
}


#pragma mark - Creation


+ (ISSRectValue*) zeroRect {
    return [[self alloc] initWithType:ISSRectValueTypeStandard rect:CGRectZero insets:UIEdgeInsetsZero];
}

+ (ISSRectValue*) rectWithRect:(CGRect)rect {
    return [[self alloc] initWithType:ISSRectValueTypeStandard rect:rect insets:UIEdgeInsetsZero];
}

+ (ISSRectValue*) parentRect {
    return [[self alloc] initWithType:ISSRectValueTypeParentInsets rect:CGRectZero insets:UIEdgeInsetsZero];
}

+ (ISSRectValue*) parentInsetRectWithSize:(CGSize)insetSize {
    return [[self alloc] initWithType:ISSRectValueTypeParentInsets rect:CGRectZero
                               insets:UIEdgeInsetsMake(insetSize.height, insetSize.width, insetSize.height, insetSize.width)];
}

+ (ISSRectValue*) parentInsetRectWithInsets:(UIEdgeInsets)insets {
    return [[self alloc] initWithType:ISSRectValueTypeParentInsets rect:CGRectZero insets:insets];
}

+ (ISSRectValue*) parentRelativeRectWithSize:(CGSize)size relativeWidth:(BOOL)relativeWidth relativeHeight:(BOOL)relativeHeight {
    ISSRectValue* rectValue = [[self alloc] initWithType:ISSRectValueTypeParentRelative rect:CGRectMake(0, 0, size.width, size.height)
                               insets:UIEdgeInsetsMake(CGFLOAT_MIN, CGFLOAT_MIN, CGFLOAT_MIN, CGFLOAT_MIN)];
    if( relativeWidth || size.width == ISSRectValueAuto ) rectValue-> _parentRelativeMask |= ISSParentRelativeWidth;
    if( relativeHeight || size.height == ISSRectValueAuto ) rectValue-> _parentRelativeMask |= ISSParentRelativeHeight;
    return rectValue;
}

+ (ISSRectValue*) windowRect {
    return [[self alloc] initWithType:ISSRectValueTypeWindowInsets rect:CGRectZero insets:UIEdgeInsetsZero];
}

+ (ISSRectValue*) windowInsetRectWithSize:(CGSize)insetSize {
    return [[self alloc] initWithType:ISSRectValueTypeWindowInsets rect:CGRectZero
                               insets:UIEdgeInsetsMake(insetSize.height, insetSize.width, insetSize.height, insetSize.height)];
}

+ (ISSRectValue*) windowInsetRectWithInsets:(UIEdgeInsets)insets {
    return [[self alloc] initWithType:ISSRectValueTypeWindowInsets rect:CGRectZero insets:insets];
}


- (instancetype) initWithType:(enum ISSRectValueType)type rect:(CGRect)rect insets:(UIEdgeInsets)insets {
    if ( self = [super init] ) {
        _type = type;
        _rect = rect;
        _insets = insets;
        _parentRelativeMask = ISSParentRelativeNone;
    }
    return self;
}


- (BOOL) autoWidth {
    return _rect.size.width == ISSRectValueAuto;
}

- (BOOL) autoHeight {
    return _rect.size.height == ISSRectValueAuto;
}


#pragma mark - Insets


- (void) setRelativeFlag:(BOOL)flag forMask:(ISSParentRelative)mask {
    if( flag ) _parentRelativeMask |= mask;
    else _parentRelativeMask &= ~mask;
}

- (void) setLeftInset:(CGFloat)inset relative:(BOOL)relative {
    _insets.left = inset;
    [self setRelativeFlag:relative forMask:ISSParentRelativeLeft];
}

- (void) setRightInset:(CGFloat)inset relative:(BOOL)relative {
    _insets.right = inset;
    [self setRelativeFlag:relative forMask:ISSParentRelativeRight];
}

- (void) setTopInset:(CGFloat)inset relative:(BOOL)relative {
    _insets.top = inset;
    [self setRelativeFlag:relative forMask:ISSParentRelativeTop];
}

- (void) setBottomInset:(CGFloat)inset relative:(BOOL)relative {
    _insets.bottom = inset;
    [self setRelativeFlag:relative forMask:ISSParentRelativeBottom];
}


#pragma mark - Obtaining CGRect result (for view)


- (CGFloat) relativeValue:(CGFloat)value parentValue:(CGFloat)parentValue relativeMaskValue:(ISSParentRelative)relativeMaskValue {
    if( _parentRelativeMask & relativeMaskValue ) return parentValue * value / 100.0f;
    else return value;
}

- (CGRect) applySizeAndInsetsToParentRect:(CGRect)parentRect {
    CGRect result = parentRect;

    if( self.autoWidth ) result.size.width = parentRect.size.width;
    else result.size.width = [self relativeValue:_rect.size.width parentValue:parentRect.size.width relativeMaskValue:ISSParentRelativeWidth];
    if( self.autoHeight ) result.size.height = parentRect.size.height;
    else result.size.height = [self relativeValue:_rect.size.height parentValue:parentRect.size.height relativeMaskValue:ISSParentRelativeHeight];


    if( _insets.left != CGFLOAT_MIN ) {
        result.origin.x = [self relativeValue:_insets.left parentValue:parentRect.size.width relativeMaskValue:ISSParentRelativeLeft];
        if( self.autoWidth ) result.size.width -= result.origin.x; // Reduce width with inset amount when auto width is used
    }
    if( _insets.right != CGFLOAT_MIN ) {
        CGFloat value = [self relativeValue:_insets.right parentValue:parentRect.size.width relativeMaskValue:ISSParentRelativeRight];
        result.origin.x = parentRect.size.width - result.size.width - value;
        if( self.autoWidth ) {
            result.origin.x += value; // When auto width is used, right inset should not affect left/x value
            result.size.width -= value; // Reduce width with inset amount when auto width is used
        }
    }

    if( _insets.top != CGFLOAT_MIN ) {
        result.origin.y = [self relativeValue:_insets.top parentValue:parentRect.size.height relativeMaskValue:ISSParentRelativeTop];
        if( self.autoHeight ) result.size.height -= result.origin.y; // Reduce height with inset amount when auto width is used
    }
    if( _insets.bottom != CGFLOAT_MIN ) {
        CGFloat value = [self relativeValue:_insets.bottom parentValue:parentRect.size.height relativeMaskValue:ISSParentRelativeBottom];
        result.origin.y = parentRect.size.height - result.size.height - value;
        if( self.autoHeight ) {
            result.origin.y += value; // When auto width is used, right inset should not affect top/y value
            result.size.height -= value; // Reduce height with inset amount when auto width is used
        }
    }

    return result;
}

- (CGRect) applyInsetsToParentRect:(CGRect)parentRect {
    if( !UIEdgeInsetsEqualToEdgeInsets(_insets, UIEdgeInsetsZero) ) {
        parentRect.origin.x = _insets.left;
        parentRect.origin.y = _insets.top;
        parentRect.size.width -= _insets.left + _insets.right;
        parentRect.size.height -= _insets.top + _insets.bottom;
    }
    return parentRect;
}

+ (CGRect) windowBoundsForView:(UIView*)view {
    UIWindow* window = view.window;
    if( !window ) window = [UIApplication sharedApplication].keyWindow;
    if( window ) return window.bounds;
    else return [UIScreen mainScreen].bounds;
}

+ (CGRect) parentBoundsForView:(UIView*)view {
    if( view.superview ) return view.superview.bounds;
    else return [self windowBoundsForView:view];
}

- (CGRect) rectForView:(UIView*)view {
    if( _type == ISSRectValueTypeStandard ) {
        return self.rect;
    } else if( _type == ISSRectValueTypeParentInsets ) {
        return [self applyInsetsToParentRect:[self.class parentBoundsForView:view]];
    } else if( _type == ISSRectValueTypeParentRelative ) {
        return [self applySizeAndInsetsToParentRect:[self.class parentBoundsForView:view]];
    } else /*if( _type == ISSRectValueTypeWindowInsets )*/ {
        return [self applyInsetsToParentRect:[self.class windowBoundsForView:view]];
    }
}

- (NSValue*) transformToNSValue {
    return [NSValue valueWithCGRect:_rect];
}


#pragma mark - NSObject overrides

- (NSString*) description {
    if( _type == ISSRectValueTypeParentInsets || _type == ISSRectValueTypeWindowInsets ) return [NSString stringWithFormat:@"ISSRectValue(%ld - %@)", (long)_type, NSStringFromUIEdgeInsets(_insets)];
    else if( _type == ISSRectValueTypeParentRelative ) return [NSString stringWithFormat:@"ISSRectValue(%ld - %@, %@)", (long)_type, NSStringFromCGRect(_rect), NSStringFromUIEdgeInsets(_insets)];
    else return [NSString stringWithFormat:@"ISSRectValue(%ld - %@)", (long)_type, NSStringFromCGRect(_rect)];
}

@end
