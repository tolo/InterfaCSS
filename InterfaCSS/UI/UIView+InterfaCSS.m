//
//  UIView+InterfaCSS.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "UIView+InterfaCSS.h"

#import "NSString+ISSStringAdditions.h"
#import "ISSPropertyRegistry.h"
#import "ISSUIElementDetails.h"
#import "ISSRuntimeIntrospectionUtils.h"

#define ISS [InterfaCSS sharedInstance]


@implementation UIView (InterfaCSS)

#if ENABLE_INTERFACSS_VIEW_SWIZZLING == 1
#pragma mark - Klaatu Verata Nikto

static void (*iss_originalWillMoveToWindow)(id self, SEL _cmd, UIWindow* newWindow);

static void iss_willMoveToWindowIntercepted(id self, SEL _cmd, UIWindow* newWindow) {
    iss_originalWillMoveToWindow(self, _cmd, newWindow);
    if( newWindow ) {
        [self scheduleApplyStylingIfNeededISS]; // Only schedule styling if a parent hasn't already scheduled it
    }
}


static void (*iss_originalDidMoveToWindow)(id self, SEL _cmd);

static void iss_didMoveToWindowIntercepted(id self, SEL _cmd) {
    iss_originalDidMoveToWindow(self, _cmd);
    if( ((UIView*)self).window ) {
        [self applyStylingIfScheduledISS]; // Apply styling if scheduled, and if a parent hasn't scheduled styling
    }
}

+ (void) load {
    if( ![self isSubclassOfClass:ISSRootView.class] ) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [ISSRuntimeIntrospectionUtils klaatuVerataNikto:self selector:@selector(willMoveToWindow:) replacement:(IMP)iss_willMoveToWindowIntercepted originalPointer:(IMP*)&iss_originalWillMoveToWindow];
            [ISSRuntimeIntrospectionUtils klaatuVerataNikto:self selector:@selector(didMoveToWindow) replacement:(IMP)iss_didMoveToWindowIntercepted originalPointer:(IMP*)&iss_originalDidMoveToWindow];
        });
    }
}
#endif


#pragma mark - Properties

- (NSString*) styleClassISS {
    return [self.styleClassesISS anyObject];
}

- (void) setStyleClassISS:(NSString*)styleClass {
    NSArray* styles = [styleClass iss_splitOnSpaceOrComma];
    [self setStyleClassesISS:[NSSet setWithArray:styles] animated:NO];
}

- (NSSet*) styleClassesISS {
    return [ISS styleClassesForUIElement:self];
}

- (void) setStyleClassesISS:(NSSet*)classes {
    [self setStyleClassesISS:classes animated:NO];
}

- (ISSWillApplyStylingNotificationBlock) willApplyStylingBlockISS {
    return [ISS willApplyStylingBlockForUIElement:self];
}

- (void) setWillApplyStylingBlockISS:(ISSWillApplyStylingNotificationBlock)willApplyStylingBlock {
    [ISS setWillApplyStylingBlock:willApplyStylingBlock forUIElement:self];
}

- (ISSDidApplyStylingNotificationBlock) didApplyStylingBlockISS {
    return [ISS didApplyStylingBlockForUIElement:self];
}

- (void) setDidApplyStylingBlockISS:(ISSDidApplyStylingNotificationBlock)didApplyStylingBlock {
    [ISS setDidApplyStylingBlock:didApplyStylingBlock forUIElement:self];
}

- (void) setCustomStylingIdentityISS:(NSString*)customStylingIdentity {
    [ISS setCustomStylingIdentity:customStylingIdentity forUIElement:self];
}

- (NSString*) customStylingIdentityISS {
    return [ISS customStylingIdentityForUIElement:self];
}

- (NSString*) elementIdISS {
    return [ISS elementIdForUIElement:self];
}

- (void) setElementIdISS:(NSString*)elementIdISS {
    [ISS setElementId:elementIdISS forUIElement:self];
}

- (ISSLayout*) layoutISS {
    return [ISS detailsForUIElement:self].layout;
}

- (void) setLayoutISS:(ISSLayout*)layoutISS {
    [ISS detailsForUIElement:self].layout = layoutISS;
}


#pragma mark - Methods

- (void) scheduleApplyStylingISS {
    [ISS scheduleApplyStyling:self animated:NO];
}

- (void) scheduleApplyStylingIfNeededISS {
    [ISS scheduleApplyStylingIfNeeded:self animated:NO force:NO];
}

- (void) cancelScheduledApplyStylingISS {
    [ISS cancelScheduledApplyStyling:self];
}

- (void) scheduleApplyStylingISS:(BOOL)animated {
    [ISS scheduleApplyStyling:self animated:animated];
}

- (void) scheduleApplyStylingWithAnimationISS {
    [ISS scheduleApplyStyling:self animated:YES];
}

- (void) setStyleClassesISS:(NSSet*)classes animated:(BOOL)animated {
    [ISS setStyleClasses:classes forUIElement:self];
    if ( !ISS.useManualStyling ) [ISS scheduleApplyStyling:self animated:animated];
}

- (void) setStyleClassISS:(NSString*)styleClass animated:(BOOL)animated {
    [self setStyleClassesISS:[NSSet setWithObject:styleClass] animated:animated];
}

- (BOOL) hasStyleClassISS:(NSString*)styleClass {
    return [ISS uiElement:self hasStyleClass:styleClass];
}

- (BOOL) addStyleClassISS:(NSString*)styleClass {
    return [self addStyleClassISS:styleClass animated:NO scheduleStyling:!ISS.useManualStyling];
}

- (BOOL) addStyleClassISS:(NSString*)styleClass scheduleStyling:(BOOL)scheduleStyling {
    return [self addStyleClassISS:styleClass animated:NO scheduleStyling:scheduleStyling];
}

- (BOOL) addStyleClassISS:(NSString*)styleClass animated:(BOOL)animated {
    return [self addStyleClassISS:styleClass animated:animated scheduleStyling:!ISS.useManualStyling];
}

- (BOOL) addStyleClassISS:(NSString*)styleClass animated:(BOOL)animated scheduleStyling:(BOOL)scheduleStyling {
    if( ![self hasStyleClassISS:styleClass] ) {
        [ISS addStyleClass:styleClass forUIElement:self];
        if( scheduleStyling ) [ISS scheduleApplyStyling:self animated:animated];
        return YES;
    }
    return NO;
}

- (BOOL) removeStyleClassISS:(NSString*)styleClass {
    return [self removeStyleClassISS:styleClass animated:NO scheduleStyling:!ISS.useManualStyling];
}

- (BOOL) removeStyleClassISS:(NSString*)styleClass scheduleStyling:(BOOL)scheduleStyling {
    return [self removeStyleClassISS:styleClass animated:NO scheduleStyling:scheduleStyling];
}

- (BOOL) removeStyleClassISS:(NSString*)styleClass animated:(BOOL)animated {
    return [self removeStyleClassISS:styleClass animated:animated scheduleStyling:!ISS.useManualStyling];
}

- (BOOL) removeStyleClassISS:(NSString*)styleClass animated:(BOOL)animated scheduleStyling:(BOOL)scheduleStyling {
    if( [self hasStyleClassISS:styleClass] ) {
        [ISS removeStyleClass:styleClass forUIElement:self];
        if( scheduleStyling ) [ISS scheduleApplyStyling:self animated:animated];
        return YES;
    }
    return NO;
}

- (void) applyStylingISS:(BOOL)force includeSubViews:(BOOL)includeSubViews {
    [ISS applyStyling:self includeSubViews:includeSubViews force:force];
}

- (void) applyStylingISS:(BOOL)force {
    [self applyStylingISS:force includeSubViews:YES];
}

- (void) applyStylingISS {
    [self applyStylingISS:NO includeSubViews:YES];
}

- (void) applyStylingIfScheduledISS {
    [ISS applyStylingIfScheduled:self];
}

- (void) applyStylingOnceISS {
    [self enableStylingISS];
    [self applyStylingISS];
    [self disableStylingISS];
}

- (void) applyStylingWithAnimationISS {
    [ISS applyStylingWithAnimation:self];
}

- (void) disableStylingISS {
    [ISS setStylingEnabled:NO forUIElement:self];
}

- (void) enableStylingISS {
    [ISS setStylingEnabled:YES forUIElement:self];
}

- (BOOL) stylingEnabledISS {
    return [ISS isStylingEnabledForUIElement:self];
}

- (BOOL) stylingAppliedISS {
    return [ISS isStylingAppliedForUIElement:self];
}

- (void) clearCachedStylesISS {
    [ISS clearCachedStylesForUIElement:self];
}

- (void) clearCachedStylesISS:(BOOL)includeSubViews {
    [ISS clearCachedStylesForUIElement:self includeSubViews:includeSubViews];
}

- (void) disableStylingForPropertyISS:(NSString*)propertyName {
    [ISS setStylingEnabled:NO forProperty:propertyName inUIElement:self];
}

- (void) enableStylingForPropertyISS:(NSString*)propertyName {
    [ISS setStylingEnabled:YES forProperty:propertyName inUIElement:self];
}

- (BOOL) stylingEnabledForPropertyISS:(NSString*)propertyName {
    return [ISS isStylingEnabledForProperty:propertyName inUIElement:self];
}

- (id) subviewWithElementId:(NSString*)elementId {
    return [ISS subviewWithElementId:elementId inView:self];
}

@end
