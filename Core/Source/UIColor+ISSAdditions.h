//
//  UIColor+ISSColorAdditions.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (ISSColorAdditions)

+ (UIColor*) iss_colorWithR:(NSInteger)r G:(NSInteger)g B:(NSInteger)b;
+ (UIColor*) iss_colorWithR:(NSInteger)r G:(NSInteger)g B:(NSInteger)b A:(float)a;
+ (UIColor*) iss_colorWithHexString:(NSString*)hex;

- (NSArray*) iss_rgbaComponents;

- (UIColor*) iss_colorByIncreasingBrightnessBy:(CGFloat)amount;
- (UIColor*) iss_colorByIncreasingSaturationBy:(CGFloat)amount;
- (UIColor*) iss_colorByIncreasingAlphaBy:(CGFloat)amount;

+ (nullable UIImage*) iss_colorAsUIImage:(UIColor*)color;
- (nullable UIImage*) iss_asUIImage;

- (nullable UIImage*) iss_topDownLinearGradientImageToColor:(UIColor*)color height:(CGFloat)height;
- (nullable UIColor*) iss_topDownLinearGradientToColor:(UIColor*)color height:(CGFloat)height;

@end

NS_ASSUME_NONNULL_END
