//
//  UIColor+ISSColorAdditions.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
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
    BOOL withAlpha = hex.length == 4 || hex.length == 8;
    BOOL compact = hex.length == 3 || hex.length == 4;

    if ( hex.length == 6 || compact || withAlpha ) {
        NSScanner* scanner = [NSScanner scannerWithString:hex];
        unsigned int cc = 0;
        unsigned int alphaOffset = withAlpha ? (compact ? 4 : 8) : 0;
        unsigned int chanelOffset = compact ? 4 : 8;
        unsigned int mask = compact ? 0x0F : 0xFF;
        unsigned int multiplier = 0xFF/mask;

        if( [scanner scanHexInt:&cc] ) {
            NSInteger r = ((cc >> (2*chanelOffset + alphaOffset)) & mask) * multiplier;
            NSInteger g = ((cc >> (chanelOffset + alphaOffset)) & mask) * multiplier;
            NSInteger b = ((cc >> alphaOffset) & mask) * multiplier;
            if( withAlpha ) {
                float a = (cc & mask) / (float)mask;
                return [self iss_colorWithR:r G:g B:b A:a];
            } else {
                return [self iss_colorWithR:r G:g B:b];
            }
        }
    }
    return [UIColor magentaColor];
}

- (NSArray*) iss_rgbaComponents {
	CGFloat r,g,b,a;
	if( ![self getRed:&r green:&g blue:&b alpha:&a] ) {
        if( [self getWhite:&r alpha:&a] ) { // Grayscale
            return @[ @(r), @(r), @(r), @(a) ];
        }
    }
    return @[ @(r), @(g), @(b), @(a) ];
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
