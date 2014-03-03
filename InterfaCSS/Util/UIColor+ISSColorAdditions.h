//
//  UIColor+ISSColorAdditions.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2011-06-15.
//  Copyright (c) 2011 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

@interface UIColor (ISSColorAdditions)

+ (UIColor*) colorWithR:(NSInteger)r G:(NSInteger)g B:(NSInteger)b;
+ (UIColor*) colorWithR:(NSInteger)r G:(NSInteger)g B:(NSInteger)b A:(float)a;
+ (UIColor*) colorWithHexString:(NSString*)hex;

- (NSArray*) rgbaComponents;

- (UIColor*) colorByIncreasingBrightnessBy:(CGFloat)amount;
- (UIColor*) colorByIncreasingSaturationBy:(CGFloat)amount;
- (UIColor*) colorByIncreasingAlphaBy:(CGFloat)amount;

+ (UIImage*) colorAsUIImage:(UIColor*)color;
- (UIImage*) asUIImage;

- (UIImage*) topDownLinearGradientImageToColor:(UIColor*)color height:(CGFloat)height;
- (UIColor*) topDownLinearGradientToColor:(UIColor*)color height:(CGFloat)height;

@end
