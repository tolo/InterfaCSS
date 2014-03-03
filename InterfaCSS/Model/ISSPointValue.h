//
//  ISSPointValue.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-02-10.
//  Copyright (c) 2014 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, ISSPointValueType) {
    ISSPointValueTypeStandard,
    ISSPointValueTypeParentRelative,
    ISSPointValueTypeWindowRelative,
};

@interface ISSPointValue : NSObject

@property (nonatomic, readonly) ISSPointValueType type;
@property (nonatomic, readonly) CGPoint point;


+ (ISSPointValue*) zeroPoint;
+ (ISSPointValue*) pointWithPoint:(CGPoint)point;

+ (ISSPointValue*) parentCenter;
+ (ISSPointValue*) parentRelativeCenterPointWithPoint:(CGPoint)point;

+ (ISSPointValue*) windowCenter;
+ (ISSPointValue*) windowRelativeCenterPointWithPoint:(CGPoint)point;


- (CGPoint) pointForView:(UIView*)view;

@end
