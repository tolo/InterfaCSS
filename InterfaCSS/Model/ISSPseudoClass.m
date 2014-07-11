//
//  ISSPseudoClass.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-03-02.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSPseudoClass.h"

#import "ISSUIElementDetails.h"

static NSDictionary* stringToPseudoClassType;

/**
 * See http://www.w3.org/TR/selectors/#structural-pseudos for a description of the a & p parameters.
 */
@implementation ISSPseudoClass {
    NSInteger _a, _b;
    ISSPseudoClassType _pseudoClassType;
}

+ (void) initialize {
    stringToPseudoClassType = @{
            @"landscape" : @(ISSPseudoClassTypeInterfaceOrientationLandscape),
            @"landscapeleft": @(ISSPseudoClassTypeInterfaceOrientationLandscapeLeft),
            @"landscaperight" : @(ISSPseudoClassTypeInterfaceOrientationLandscapeRight),
            @"portrait" : @(ISSPseudoClassTypeInterfaceOrientationPortrait),
            @"portraitupright" : @(ISSPseudoClassTypeInterfaceOrientationPortraitUpright),
            @"portraitupsidedown" : @(ISSPseudoClassTypeInterfaceOrientationPortraitUpsideDown),
            @"enabled" : @(ISSPseudoClassTypeStateEnabled),
            @"disabled" : @(ISSPseudoClassTypeStateDisabled),
            @"nthchild" : @(ISSPseudoClassTypeNthChild),
            @"nthlastchild" : @(ISSPseudoClassTypeNthLastChild),
            @"onlychild" : @(ISSPseudoClassTypeOnlyChild),
            @"firstchild" : @(ISSPseudoClassTypeFirstChild),
            @"lastchild" : @(ISSPseudoClassTypeLastChild),
            @"nthoftype" : @(ISSPseudoClassTypeNthOfType),
            @"nthlastofyype" : @(ISSPseudoClassTypeNthLastOfType),
            @"onlyoftype" : @(ISSPseudoClassTypeOnlyOfType),
            @"firstoftype" : @(ISSPseudoClassTypeFirstOfType),
            @"lastoftype" : @(ISSPseudoClassTypeLastOfType),
            @"empty" : @(ISSPseudoClassTypeEmpty)
    };
}

- (instancetype) initWithA:(NSInteger)a b:(NSInteger)b type:(ISSPseudoClassType)pseudoClassType {
    self = [super init];
    if ( self ) {
        if( (pseudoClassType == ISSPseudoClassTypeFirstChild) || (pseudoClassType == ISSPseudoClassTypeLastChild) ||
            (pseudoClassType == ISSPseudoClassTypeFirstOfType) || (pseudoClassType == ISSPseudoClassTypeLastOfType) ) {
            _a = 0;
            _b = 1;
        } else {
            _a = a;
            _b = b;
        }
        _pseudoClassType = pseudoClassType;
    }

    return self;
}

+ (instancetype) pseudoClassWithA:(NSInteger)a b:(NSInteger)b type:(ISSPseudoClassType)pseudoClassType {
    return [[self alloc] initWithA:a b:b type:pseudoClassType];
}

+ (ISSPseudoClassType) pseudoClassTypeFromString:(NSString*)typeAsString {
    NSNumber* b = stringToPseudoClassType[typeAsString.lowercaseString];
    if( b ) return (ISSPseudoClassType)b.integerValue;
    else @throw([NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Invalid enum class type: %@", typeAsString] userInfo:nil]);
}

- (BOOL) matchesIndex:(NSInteger)indexInParent count:(NSInteger)n reverse:(BOOL)reverse {
    if( indexInParent != NSNotFound ) {
        for(NSInteger i=1; i<=n; i++) {
            NSInteger index = (i-1)*_a + _b - 1;
            if( reverse ) index = n-1 - index;
            if( index == indexInParent ) {
                return YES;
            }
        }
    }
    return NO;
}

- (UIInterfaceOrientation) currentInterfaceOrientationForDevice {
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if( UIDeviceOrientationIsValidInterfaceOrientation(deviceOrientation) ) {
        switch( deviceOrientation ) {
            case UIDeviceOrientationLandscapeLeft : return UIInterfaceOrientationLandscapeRight;
            case UIDeviceOrientationLandscapeRight : return UIInterfaceOrientationLandscapeLeft;
            case UIDeviceOrientationPortraitUpsideDown : return UIInterfaceOrientationPortraitUpsideDown;
            default: return UIInterfaceOrientationPortrait;
        }
    } else if( [UIApplication sharedApplication].keyWindow.rootViewController )  { // Fallback to last interface orientation if face up/down
        return [UIApplication sharedApplication].keyWindow.rootViewController.interfaceOrientation;
    } else {
        return UIInterfaceOrientationPortrait;
    }
}

- (BOOL) matchesElement:(ISSUIElementDetails*)elementDetails {
    id uiElement = elementDetails.uiElement;
    switch( _pseudoClassType ) {
        case ISSPseudoClassTypeInterfaceOrientationLandscape: return UIInterfaceOrientationIsLandscape([self currentInterfaceOrientationForDevice]);
        case ISSPseudoClassTypeInterfaceOrientationLandscapeLeft: return [self currentInterfaceOrientationForDevice] == UIInterfaceOrientationLandscapeLeft;
        case ISSPseudoClassTypeInterfaceOrientationLandscapeRight: return [self currentInterfaceOrientationForDevice] == UIInterfaceOrientationLandscapeRight;
        case ISSPseudoClassTypeInterfaceOrientationPortrait: return UIInterfaceOrientationIsPortrait([self currentInterfaceOrientationForDevice]);
        case ISSPseudoClassTypeInterfaceOrientationPortraitUpright: return [self currentInterfaceOrientationForDevice] == UIInterfaceOrientationPortrait;
        case ISSPseudoClassTypeInterfaceOrientationPortraitUpsideDown: return [self currentInterfaceOrientationForDevice] == UIInterfaceOrientationPortraitUpsideDown;
        case ISSPseudoClassTypeStateEnabled: {
            return [uiElement respondsToSelector:@selector(isEnabled)] && [uiElement isEnabled];
        }
        case ISSPseudoClassTypeStateDisabled: {
            return [uiElement respondsToSelector:@selector(isEnabled)] && ![uiElement isEnabled];
        }
        case ISSPseudoClassTypeNthChild:
        case ISSPseudoClassTypeFirstChild: {
            if( elementDetails.parentView ) return [self matchesIndex:[elementDetails.parentView.subviews indexOfObject:uiElement] count:elementDetails.parentView.subviews.count reverse:NO];
            else return NO;
        }
        case ISSPseudoClassTypeNthLastChild:
        case ISSPseudoClassTypeLastChild: {
            if( elementDetails.parentView ) return [self matchesIndex:[elementDetails.parentView.subviews indexOfObject:uiElement] count:elementDetails.parentView.subviews.count reverse:YES];
            else return NO;
        }
        case ISSPseudoClassTypeOnlyChild: {
            return elementDetails.parentView.subviews.count == 1;
        }
        case ISSPseudoClassTypeNthOfType:
        case ISSPseudoClassTypeFirstOfType:
        case ISSPseudoClassTypeNthLastOfType:
        case ISSPseudoClassTypeLastOfType: {
            NSInteger position, count;
            [elementDetails typeQualifiedPositionInParent:&position count:&count];
            return [self matchesIndex:position count:count reverse:(_pseudoClassType == ISSPseudoClassTypeNthLastOfType || _pseudoClassType == ISSPseudoClassTypeLastOfType)];
        }
        case ISSPseudoClassTypeOnlyOfType: {
            NSInteger position, count;
            [elementDetails typeQualifiedPositionInParent:&position count:&count];
            return position == 0 && count == 1;
        }
        case ISSPseudoClassTypeEmpty: {
            return elementDetails.view.subviews.count == 0;
        }
    }
    return NO;
}

- (NSString*) displayDescription {
    NSString* bSign = _b < 0 ? @"-" : @"+";
    switch( _pseudoClassType ) {
        case ISSPseudoClassTypeInterfaceOrientationLandscape: return @"landscape";
        case ISSPseudoClassTypeInterfaceOrientationLandscapeLeft: return @"landscapeLeft";
        case ISSPseudoClassTypeInterfaceOrientationLandscapeRight: return @"landscapeRight";
        case ISSPseudoClassTypeInterfaceOrientationPortrait: return @"portrait";
        case ISSPseudoClassTypeInterfaceOrientationPortraitUpright: return @"portraitUpright";
        case ISSPseudoClassTypeInterfaceOrientationPortraitUpsideDown: return @"portraitUpsideDown";
        case ISSPseudoClassTypeStateEnabled: return @"enabled";
        case ISSPseudoClassTypeStateDisabled: return @"disabled";
        case ISSPseudoClassTypeNthChild: return [NSString stringWithFormat:@"nthchild(%ldn%@%ld)", (long)_a, bSign, (long)_b];
        case ISSPseudoClassTypeNthLastChild: return [NSString stringWithFormat:@"nthlastchild(%ldn%@%ld)", (long)_a, bSign, (long)_b];
        case ISSPseudoClassTypeOnlyChild: return @"onlychild";
        case ISSPseudoClassTypeFirstChild: return @"firstchild";
        case ISSPseudoClassTypeLastChild: return @"lastchild";
        case ISSPseudoClassTypeNthOfType: return [NSString stringWithFormat:@"nthoftype(%ldn%@%ld)", (long)_a, bSign, (long)_b];
        case ISSPseudoClassTypeNthLastOfType: return [NSString stringWithFormat:@"nthlastofyype(%ldn%@%ld)", (long)_a, bSign, (long)_b];
        case ISSPseudoClassTypeOnlyOfType: return @"onlyoftype";
        case ISSPseudoClassTypeFirstOfType: return @"firstoftype";
        case ISSPseudoClassTypeLastOfType: return @"lastoftype";
        case ISSPseudoClassTypeEmpty: return @"empty";
    }
    return @"";
}


#pragma mark - NSObject overrides

- (NSString*) description {
    return [NSString stringWithFormat:@"PseudoClass(%@)", self.displayDescription];
}

- (BOOL) isEqual:(id)object {
    if( object == self ) return YES;
    else if ( [object isKindOfClass:ISSPseudoClass.class] ) {
        ISSPseudoClass* other = (ISSPseudoClass*)object;
        return _pseudoClassType == other->_pseudoClassType && _a == other->_a && _b == other->_b;
    } else return NO;
}

- (NSUInteger) hash {
    return self.displayDescription.hash;
}

@end
