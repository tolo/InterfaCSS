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
#import "NSString+ISSStringAdditions.h"
#import "ISSUIElementDetails.h"


@implementation UIView (InterfaCSS)

#pragma mark - Properties

- (NSString*) styleClassISS {
    return [self.styleClassesISS anyObject];
}

- (void) setStyleClassISS:(NSString*)styleClass {
    NSArray* styles = [styleClass iss_splitOnSpaceOrComma];
    [self setStyleClassesISS:[NSSet setWithArray:styles] animated:NO];
}

- (NSSet*) styleClassesISS {
    return [[InterfaCSS interfaCSS] styleClassesForUIElement:self];
}

- (void) setStyleClassesISS:(NSSet*)classes {
    [self setStyleClassesISS:classes animated:NO];
}

- (ISSWillApplyStylingNotificationBlock) willApplyStylingBlockISS {
    return [[InterfaCSS interfaCSS] detailsForUIElement:self].willApplyStylingBlock;
}

- (void) setWillApplyStylingBlockISS:(ISSWillApplyStylingNotificationBlock)willApplyStylingBlock {
    [[InterfaCSS interfaCSS] detailsForUIElement:self].willApplyStylingBlock = willApplyStylingBlock;
}

- (ISSDidApplyStylingNotificationBlock) didApplyStylingBlockISS {
    return [[InterfaCSS interfaCSS] detailsForUIElement:self].didApplyStylingBlock;
}

- (void) setDidApplyStylingBlockISS:(ISSDidApplyStylingNotificationBlock)didApplyStylingBlock {
    [[InterfaCSS interfaCSS] detailsForUIElement:self].didApplyStylingBlock = didApplyStylingBlock;
}

- (void) setCustomStylingIdentityISS:(NSString*)customStylingIdentityISS {
    [[[InterfaCSS interfaCSS] detailsForUIElement:self] setCustomElementStyleIdentity:customStylingIdentityISS];
}

- (NSString*) customStylingIdentityISS {
    return [[InterfaCSS interfaCSS] detailsForUIElement:self].elementStyleIdentity;
}


#pragma mark - Methods

- (void) scheduleApplyStylingISS {
    [[InterfaCSS interfaCSS] scheduleApplyStyling:self animated:NO];
}

- (void) scheduleApplyStylingISS:(BOOL)animated {
    [[InterfaCSS interfaCSS] scheduleApplyStyling:self animated:animated];
}

- (void) setStyleClassesISS:(NSSet*)classes animated:(BOOL)animated {
    [[InterfaCSS interfaCSS] setStyleClasses:classes forUIElement:self];
    [self scheduleApplyStylingISS:animated];
}

- (void) setStyleClassISS:(NSString*)styleClass animated:(BOOL)animated {
    [self setStyleClassesISS:[NSSet setWithObject:styleClass] animated:animated];
}

- (BOOL) hasStyleClassISS:(NSString*)styleClass {
    return [[InterfaCSS interfaCSS] uiElement:self hasStyleClass:styleClass];
}

- (void) addStyleClassISS:(NSString*)styleClass {
    [self addStyleClassISS:styleClass animated:NO];
}

- (void) addStyleClassISS:(NSString*)styleClass animated:(BOOL)animated {
    [[InterfaCSS interfaCSS] addStyleClass:styleClass forUIElement:self];
    [self scheduleApplyStylingISS:animated];
}

- (void) removeStyleClassISS:(NSString*)styleClass {
    [self removeStyleClassISS:styleClass animated:NO];
}

- (void) removeStyleClassISS:(NSString*)styleClass animated:(BOOL)animated {
    [[InterfaCSS interfaCSS] removeStyleClass:styleClass forUIElement:self];
    [self scheduleApplyStylingISS:animated];
}

- (void) applyStylingISS:(BOOL)force {
    [[InterfaCSS interfaCSS] applyStyling:self includeSubViews:YES force:force];
}

- (void) applyStylingISS {
    [self applyStylingISS:NO];
}

- (void) applyStylingWithAnimationISS:(BOOL)invalidateStyles {
    if( invalidateStyles ) [[InterfaCSS interfaCSS] clearCachedStylesForUIElement:self];
    [[InterfaCSS interfaCSS] applyStylingWithAnimation:self];
}

- (void) applyStylingWithAnimationISS {
    [self applyStylingWithAnimationISS:NO];
}

- (void) disableStylingISS {
    [[InterfaCSS interfaCSS] setStylingEnabled:NO forUIElement:self];
}

- (void) enableStylingISS {
    [[InterfaCSS interfaCSS] setStylingEnabled:YES forUIElement:self];
}

- (void) clearCachedStylesISS {
    [[InterfaCSS interfaCSS] clearCachedStylesForUIElement:self];
}

@end
