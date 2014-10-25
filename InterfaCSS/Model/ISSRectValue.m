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
CGFloat const ISSRectValueNoValue = CGFLOAT_MAX;

#define ISS_SCALE [UIScreen mainScreen].scale


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
                               insets:UIEdgeInsetsMake(ISSRectValueNoValue, ISSRectValueNoValue, ISSRectValueNoValue, ISSRectValueNoValue)];
    if( relativeWidth || size.width == ISSRectValueAuto ) rectValue-> _parentRelativeMask |= ISSParentRelativeWidth;
    if( relativeHeight || size.height == ISSRectValueAuto ) rectValue-> _parentRelativeMask |= ISSParentRelativeHeight;
    return rectValue;
}

+ (ISSRectValue*) parentRelativeSizeToFitRectWithSize:(CGSize)size relativeWidth:(BOOL)relativeWidth relativeHeight:(BOOL)relativeHeight {
    ISSRectValue* rectValue = [self parentRelativeRectWithSize:size relativeWidth:relativeWidth relativeHeight:relativeHeight];
    rectValue->_type = ISSRectValueTypeParentRelativeSizeToFit;
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
    return _rect.size.width == ISSRectValueAuto && _type != ISSRectValueTypeParentRelativeSizeToFit;
}

- (BOOL) autoHeight {
    return _rect.size.height == ISSRectValueAuto && _type != ISSRectValueTypeParentRelativeSizeToFit;
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
    if( _parentRelativeMask & relativeMaskValue ) return floorf(ISS_SCALE * parentValue * value / 100.0f) / ISS_SCALE;
    else return value;
}

- (CGRect) applySizeAndInsetsToParentRect:(CGRect)parentRect forView:(UIView*)view {
    CGFloat width, height;

    if( self.autoWidth ) width = parentRect.size.width;
    else width = [self relativeValue:_rect.size.width parentValue:parentRect.size.width relativeMaskValue:ISSParentRelativeWidth];
    if( self.autoHeight ) height = parentRect.size.height;
    else height = [self relativeValue:_rect.size.height parentValue:parentRect.size.height relativeMaskValue:ISSParentRelativeHeight];

    // If sizeToFit mode - get the desired size for the view, using width & height as max values
    BOOL isSizeToFit = _type == ISSRectValueTypeParentRelativeSizeToFit;
    if( isSizeToFit ) {
        CGSize size = [view sizeThatFits:CGSizeMake(width, height)];
        if( size.width < width ) width = size.width;
        if( size.height < height ) height = size.height;
    }

    CGRect resultingRect = CGRectMake(0, 0, width, height);
    UIEdgeInsets actualInsets = UIEdgeInsetsZero;

    if( _insets.left != ISSRectValueNoValue ) {
        CGFloat leftInset = [self relativeValue:_insets.left parentValue:parentRect.size.width relativeMaskValue:ISSParentRelativeLeft];
        if( self.autoWidth ) actualInsets.left = leftInset;
        else resultingRect.origin.x = leftInset;
    }
    if( _insets.right != ISSRectValueNoValue ) {
        CGFloat rightInset = [self relativeValue:_insets.right parentValue:parentRect.size.width relativeMaskValue:ISSParentRelativeRight];
        if( self.autoWidth ) actualInsets.right = rightInset;
        else resultingRect.origin.x += (parentRect.size.width - width - rightInset);
    }
    if( _insets.top != ISSRectValueNoValue ) {
        CGFloat topInset = [self relativeValue:_insets.top parentValue:parentRect.size.height relativeMaskValue:ISSParentRelativeTop];
        if( self.autoHeight ) actualInsets.top = topInset;
        else resultingRect.origin.y = topInset;
    }
    if( _insets.bottom != ISSRectValueNoValue ) {
        CGFloat bottomInset = [self relativeValue:_insets.bottom parentValue:parentRect.size.height relativeMaskValue:ISSParentRelativeBottom];
        if( self.autoHeight ) actualInsets.bottom = bottomInset;
        else resultingRect.origin.y += (parentRect.size.height - height - bottomInset);
    }

    return UIEdgeInsetsInsetRect(resultingRect, actualInsets);
}

- (CGRect) applyInsetsToParentRect:(CGRect)parentRect {
    if( !UIEdgeInsetsEqualToEdgeInsets(_insets, UIEdgeInsetsZero) ) {
        return UIEdgeInsetsInsetRect(parentRect, _insets);
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
        return _rect;
    } else if( _type == ISSRectValueTypeParentInsets ) {
        return [self applyInsetsToParentRect:[self.class parentBoundsForView:view]];
    } else if( _type == ISSRectValueTypeParentRelative || _type == ISSRectValueTypeParentRelativeSizeToFit ) {
        return [self applySizeAndInsetsToParentRect:[self.class parentBoundsForView:view] forView:view];
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
