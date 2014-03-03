//
//  UIView+InterfaCSS.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "UIView+InterfaCSS.h"

#import "InterfaCSS.h"


@implementation UIView (InterfaCSS)

- (NSSet*) styleClasses {
    return [[InterfaCSS interfaCSS] styleClassesForUIObject:self];
}

- (void) setStyleClasses:(NSSet*)classes {
    [self setStyleClasses:classes animated:NO];
}

- (void) scheduleApplyStyling {
    [[InterfaCSS interfaCSS] scheduleApplyStyling:self animated:NO];
}

- (void) scheduleApplyStyling:(BOOL)animated {
    [[InterfaCSS interfaCSS] scheduleApplyStyling:self animated:animated];
}

- (void) setStyleClasses:(NSSet*)classes animated:(BOOL)animated {
    [[InterfaCSS interfaCSS] setStyleClasses:classes forUIObject:self];
    [self scheduleApplyStyling:animated];
}

- (NSString*) styleClass {
    return [self.styleClasses anyObject];
}

- (void) setStyleClass:(NSString*)styleClass {
    [self setStyleClasses:[NSSet setWithObject:styleClass] animated:NO];
}

- (void) setStyleClass:(NSString*)styleClass animated:(BOOL)animated {
    [self setStyleClasses:[NSSet setWithObject:styleClass]];
}

- (void) addStyleClass:(NSString*)styleClass {
    [self addStyleClass:styleClass animated:NO];
}

- (void) addStyleClass:(NSString*)styleClass animated:(BOOL)animated {
    [[InterfaCSS interfaCSS] addStyleClass:styleClass forUIObject:self];
    [self scheduleApplyStyling:animated];
}

- (void) removeStyleClass:(NSString*)styleClass {
    [self removeStyleClass:styleClass animated:NO];
}

- (void) removeStyleClass:(NSString*)styleClass animated:(BOOL)animated {
    [[InterfaCSS interfaCSS] removeStyleClass:styleClass forUIObject:self];
    [self scheduleApplyStyling:animated];
}

- (void) applyStyling:(BOOL)invalidateStyles {
    if( invalidateStyles ) [[InterfaCSS interfaCSS] clearCachedStylesForUIObject:self];
    [[InterfaCSS interfaCSS] applyStyling:self];
}

- (void) applyStyling {
    [self applyStyling:NO];
}

- (void) applyStylingWithAnimation:(BOOL)invalidateStyles {
    if( invalidateStyles ) [[InterfaCSS interfaCSS] clearCachedStylesForUIObject:self];
    [[InterfaCSS interfaCSS] applyStylingWithAnimation:self];
}

- (void) applyStylingWithAnimation {
    [self applyStylingWithAnimation:NO];
}

@end
