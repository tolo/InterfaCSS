//
//  ISSPointValue.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-02-10.
//  Copyright (c) 2014 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSPointValue.h"


@implementation ISSPointValue

+ (ISSPointValue*) zeroPoint {
    return [[self alloc] initWithType:ISSPointValueTypeStandard point:CGPointZero];
}

+ (ISSPointValue*) pointWithPoint:(CGPoint)point {
    return [[self alloc] initWithType:ISSPointValueTypeStandard point:point];
}

+ (ISSPointValue*) parentCenter {
    return [[self alloc] initWithType:ISSPointValueTypeParentRelative point:CGPointZero];
}

+ (ISSPointValue*) parentRelativeCenterPointWithPoint:(CGPoint)point {
    return [[self alloc] initWithType:ISSPointValueTypeParentRelative point:point];
}

+ (ISSPointValue*) windowCenter {
    return [[self alloc] initWithType:ISSPointValueTypeWindowRelative point:CGPointZero];
}

+ (ISSPointValue*) windowRelativeCenterPointWithPoint:(CGPoint)point {
    return [[self alloc] initWithType:ISSPointValueTypeWindowRelative point:point];
}

- (instancetype) initWithType:(enum ISSPointValueType)type point:(CGPoint)point {
    self = [super init];
    if ( self ) {
        _type = type;
        _point = point;
    }
    return self;
}

+ (CGPoint) sourcePoint:(CGPoint)sourcePoint adjustedBy:(CGPoint)point {
    sourcePoint.x += point.x;
    sourcePoint.y += point.y;
    return sourcePoint;
}

+ (CGPoint) windowCenterForView:(UIView*)view {
    UIWindow* window = view.window;
    CGRect bounds;
    if( !window ) window = [UIApplication sharedApplication].keyWindow;
    if( window ) bounds = window.bounds;
    else bounds = [UIScreen mainScreen].bounds;
    return CGPointMake(CGRectGetWidth(bounds)/2, CGRectGetHeight(bounds)/2);
}

+ (CGPoint) superViewCenterForView:(UIView*)view {
    if( view.superview ) return CGPointMake(CGRectGetWidth(view.superview.bounds)/2, CGRectGetHeight(view.superview.bounds)/2);
    else return [self windowCenterForView:view];
}

- (CGPoint) pointForView:(UIView*)view {
    if( self.type == ISSPointValueTypeStandard ) {
        return self.point;
    } else if( self.type == ISSPointValueTypeParentRelative ) {
        return [self.class sourcePoint:[self.class superViewCenterForView:view] adjustedBy:self.point];
    } else /*if( self.type == ISSPointValueTypeWindowRelative )*/ {
        return [self.class sourcePoint:[self.class windowCenterForView:view] adjustedBy:self.point];
    }
}

- (NSValue*) transformToNSValue {
    return [NSValue valueWithCGPoint:self.point];
}


#pragma mark - NSObject overrides

- (NSString*) description {
    return [NSString stringWithFormat:@"ISSPointValue(%d - %@)", _type, NSStringFromCGPoint(_point)];
}

@end
