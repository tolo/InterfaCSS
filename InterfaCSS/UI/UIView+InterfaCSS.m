//
//  UIView+InterfaCSS.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "UIView+InterfaCSS.h"

#import "NSString+ISSStringAdditions.h"
#import "ISSPropertyRegistry.h"
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
    return [[InterfaCSS interfaCSS] willApplyStylingBlockForUIElement:self];
}

- (void) setWillApplyStylingBlockISS:(ISSWillApplyStylingNotificationBlock)willApplyStylingBlock {
    [[InterfaCSS interfaCSS] setWillApplyStylingBlock:willApplyStylingBlock forUIElement:self];
}

- (ISSDidApplyStylingNotificationBlock) didApplyStylingBlockISS {
    return [[InterfaCSS interfaCSS] didApplyStylingBlockForUIElement:self];
}

- (void) setDidApplyStylingBlockISS:(ISSDidApplyStylingNotificationBlock)didApplyStylingBlock {
    [[InterfaCSS interfaCSS] setDidApplyStylingBlock:didApplyStylingBlock forUIElement:self];
}

- (void) setCustomStylingIdentityISS:(NSString*)customStylingIdentity {
    [[InterfaCSS interfaCSS] setCustomStylingIdentity:customStylingIdentity forUIElement:self];
}

- (NSString*) customStylingIdentityISS {
    return [[InterfaCSS interfaCSS] customStylingIdentityForUIElement:self];
}

- (NSString*) elementIdISS {
    return [[InterfaCSS interfaCSS] detailsForUIElement:self].elementId;
}

- (void) setElementIdISS:(NSString*)elementIdISS {
    [[InterfaCSS interfaCSS] detailsForUIElement:self].elementId = elementIdISS;
}


#pragma mark - Methods

- (void) scheduleApplyStylingISS {
    [[InterfaCSS interfaCSS] scheduleApplyStyling:self animated:NO];
}

- (void) cancelScheduledApplyStylingISS {
    [[InterfaCSS interfaCSS] cancelScheduledApplyStyling:self];
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

- (BOOL) addStyleClassISS:(NSString*)styleClass {
    return [self addStyleClassISS:styleClass animated:NO scheduleStyling:YES];
}

- (BOOL) addStyleClassISS:(NSString*)styleClass scheduleStyling:(BOOL)scheduleStyling {
    return [self addStyleClassISS:styleClass animated:NO scheduleStyling:scheduleStyling];
}

- (BOOL) addStyleClassISS:(NSString*)styleClass animated:(BOOL)animated {
    return [self addStyleClassISS:styleClass animated:animated scheduleStyling:YES];
}

- (BOOL) addStyleClassISS:(NSString*)styleClass animated:(BOOL)animated scheduleStyling:(BOOL)scheduleStyling {
    if( ![self hasStyleClassISS:styleClass] ) {
        [[InterfaCSS interfaCSS] addStyleClass:styleClass forUIElement:self];
        if( scheduleStyling ) [self scheduleApplyStylingISS:animated];
        return YES;
    }
    return NO;
}

- (BOOL) removeStyleClassISS:(NSString*)styleClass {
    return [self removeStyleClassISS:styleClass animated:NO scheduleStyling:YES];
}

- (BOOL) removeStyleClassISS:(NSString*)styleClass scheduleStyling:(BOOL)scheduleStyling {
    return [self removeStyleClassISS:styleClass animated:NO scheduleStyling:scheduleStyling];
}

- (BOOL) removeStyleClassISS:(NSString*)styleClass animated:(BOOL)animated {
    return [self removeStyleClassISS:styleClass animated:animated scheduleStyling:YES];
}

- (BOOL) removeStyleClassISS:(NSString*)styleClass animated:(BOOL)animated scheduleStyling:(BOOL)scheduleStyling {
    if( [self hasStyleClassISS:styleClass] ) {
        [[InterfaCSS interfaCSS] removeStyleClass:styleClass forUIElement:self];
        if( scheduleStyling ) [self scheduleApplyStylingISS:animated];
        return YES;
    }
    return NO;
}

- (void) applyStylingISS:(BOOL)force {
    [[InterfaCSS interfaCSS] applyStyling:self includeSubViews:YES force:force];
}

- (void) applyStylingISS {
    [self applyStylingISS:NO];
}

- (void) applyStylingOnceISS {
    [self enableStylingISS];
    [self applyStylingISS];
    [self disableStylingISS];
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

- (BOOL) stylingEnabledISS {
    return [[InterfaCSS interfaCSS] isStylingEnabledForUIElement:self];
}

- (BOOL) stylingAppliedISS {
    return [[InterfaCSS interfaCSS] isStylingAppliedForUIElement:self];
}

- (void) clearCachedStylesISS {
    [[InterfaCSS interfaCSS] clearCachedStylesForUIElement:self];
}

- (void) disableStylingForPropertyISS:(NSString*)propertyName {
    [[InterfaCSS interfaCSS] setStylingEnabled:NO forProperty:propertyName inUIElement:self];
}

- (void) enableStylingForPropertyISS:(NSString*)propertyName {
    [[InterfaCSS interfaCSS] setStylingEnabled:YES forProperty:propertyName inUIElement:self];
}

- (id) subviewWithElementId:(NSString*)elementId {
    return [[InterfaCSS interfaCSS] subviewWithElementId:elementId inView:self];
}

@end
