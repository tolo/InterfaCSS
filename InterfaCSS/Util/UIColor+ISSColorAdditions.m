//
//  UIColor+ISSColorAdditions.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2011-06-15.
//  Copyright (c) 2011 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "UIColor+ISSColorAdditions.h"

#import "NSString+ISSStringAdditions.h"


static inline CGFloat adjustWithAbsoluteAmount(CGFloat value, CGFloat adjustAmount) {
    return MIN(MAX(0.0f, value + value * adjustAmount / 100.0f), 1.0f);
}

@implementation UIColor (ISSColorAdditions)

+ (UIColor*) iss_colorWithR:(NSInteger)r G:(NSInteger)g B:(NSInteger)b {
    return [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1];
}

+ (UIColor*) iss_colorWithR:(NSInteger)r G:(NSInteger)g B:(NSInteger)b A:(float)a {
    return [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a];
}

+ (UIColor*) iss_colorWithHexString:(NSString*)hex {
    hex = [hex iss_trim];
    if ( hex.length == 6 ) {
        NSScanner* scanner = [NSScanner scannerWithString:hex];
        unsigned int cc = 0;

        if( [scanner scanHexInt:&cc] ) {
            NSInteger r = (cc >> 16) & 0xFF;
            NSInteger g = (cc >> 8) & 0xFF;
            NSInteger b = cc & 0xFF;
            return [self iss_colorWithR:r G:g B:b];
        }
    }
    return [UIColor magentaColor];
}

- (NSArray*) iss_rgbaComponents {
	CGFloat r,g,b,a;
	[self getRed:&r green:&g blue:&b alpha:&a];
	return @[@(r), @(g), @(b), @(a)];
}

- (UIColor*) iss_colorByIncreasingBrightnessBy:(CGFloat)amount {
    CGFloat h,s,b,a;
    if( [self getHue:&h saturation:&s brightness:&b alpha:&a] ) { // RGB or HSB
        b = adjustWithAbsoluteAmount(b, amount);
        return [UIColor colorWithHue:h saturation:s brightness:b alpha:a];
    } else if( [self getWhite:&b alpha:&a] ) { // Grayscale
        b = adjustWithAbsoluteAmount(b, amount);
        return [UIColor colorWithWhite:b alpha:a];
    } else return self;
}

- (UIColor*) iss_colorByIncreasingSaturationBy:(CGFloat)amount {
    CGFloat h,s,b,a;
    if( [self getHue:&h saturation:&s brightness:&b alpha:&a] ) { // RGB or HSB
        s = adjustWithAbsoluteAmount(s, amount);
        return [UIColor colorWithHue:h saturation:s brightness:b alpha:a];
    } else return self;
}

- (UIColor*) iss_colorByIncreasingAlphaBy:(CGFloat)amount {
    CGFloat h,s,b,a;
    if( [self getHue:&h saturation:&s brightness:&b alpha:&a] ) { // RGB or HSB
        a = adjustWithAbsoluteAmount(a, amount);
        return [UIColor colorWithHue:h saturation:s brightness:b alpha:a];
    } else if( [self getWhite:&b alpha:&a] ) { // Grayscale
        a = adjustWithAbsoluteAmount(a, amount);
        return [UIColor colorWithWhite:b alpha:a];
    } else return self;
}

+ (UIImage*) iss_colorAsUIImage:(UIColor*)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);

    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

- (UIImage*) iss_asUIImage {
    return [self.class iss_colorAsUIImage:self];
}

- (UIImage*) iss_topDownLinearGradientImageToColor:(UIColor*)color height:(CGFloat)height {
    CGSize size = CGSizeMake(1, height);

    UIGraphicsBeginImageContextWithOptions(size, NO, 0);

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGFloat locations[2] = {0.0, 1.0};
    CGFloat components[8];
    NSArray* colorComponents = [self iss_rgbaComponents];
    for (NSUInteger i = 0; i < colorComponents.count; i++) components[i] = [colorComponents[i] floatValue];
    colorComponents = [color iss_rgbaComponents];
    for (NSUInteger i = 0; i < colorComponents.count; i++) components[i + 4] = [colorComponents[i] floatValue];

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, 2);

    CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(0, size.height), 0);

    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);

    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

- (UIColor*) iss_topDownLinearGradientToColor:(UIColor*)color height:(CGFloat)height {
    return [UIColor colorWithPatternImage:[self iss_topDownLinearGradientImageToColor:color height:height]];
}

@end
