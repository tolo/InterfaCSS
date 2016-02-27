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
    return [[InterfaCSS interfaCSS] elementIdForUIElement:self];
}

- (void) setElementIdISS:(NSString*)elementIdISS {
    [[InterfaCSS interfaCSS] setElementId:elementIdISS forUIElement:self];
}

- (ISSLayout*) layoutISS {
    return [[InterfaCSS interfaCSS] detailsForUIElement:self].layout;
}

- (void) setLayoutISS:(ISSLayout*)layoutISS {
    [[InterfaCSS interfaCSS] detailsForUIElement:self].layout = layoutISS;
}


#pragma mark - Methods

- (void) scheduleApplyStylingISS {
    [[InterfaCSS interfaCSS] scheduleApplyStyling:self animated:NO];
}

- (void) scheduleApplyStylingIfNeededISS {
    [[InterfaCSS interfaCSS] scheduleApplyStylingIfNeeded:self animated:NO force:NO];
}

- (void) cancelScheduledApplyStylingISS {
    [[InterfaCSS interfaCSS] cancelScheduledApplyStyling:self];
}

- (void) scheduleApplyStylingISS:(BOOL)animated {
    [[InterfaCSS interfaCSS] scheduleApplyStyling:self animated:animated];
}

- (void) scheduleApplyStylingWithAnimationISS {
    [[InterfaCSS interfaCSS] scheduleApplyStyling:self animated:YES];
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

- (void) applyStylingISS:(BOOL)force includeSubViews:(BOOL)includeSubViews {
    [[InterfaCSS interfaCSS] applyStyling:self includeSubViews:includeSubViews force:force];
}

- (void) applyStylingISS:(BOOL)force {
    [self applyStylingISS:force includeSubViews:YES];
}

- (void) applyStylingISS {
    [self applyStylingISS:NO includeSubViews:YES];
}

- (void) applyStylingIfScheduledISS {
    [[InterfaCSS interfaCSS] applyStylingIfScheduled:self];
}

- (void) applyStylingOnceISS {
    [self enableStylingISS];
    [self applyStylingISS];
    [self disableStylingISS];
}

- (void) applyStylingWithAnimationISS {
    [[InterfaCSS interfaCSS] applyStylingWithAnimation:self];
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

- (void) clearCachedStylesISS:(BOOL)includeSubViews {
    [[InterfaCSS interfaCSS] clearCachedStylesForUIElement:self includeSubViews:includeSubViews];
}

- (void) disableStylingForPropertyISS:(NSString*)propertyName {
    [[InterfaCSS interfaCSS] setStylingEnabled:NO forProperty:propertyName inUIElement:self];
}

- (void) enableStylingForPropertyISS:(NSString*)propertyName {
    [[InterfaCSS interfaCSS] setStylingEnabled:YES forProperty:propertyName inUIElement:self];
}

- (BOOL) stylingEnabledForPropertyISS:(NSString*)propertyName {
    return [[InterfaCSS interfaCSS] isStylingEnabledForProperty:propertyName inUIElement:self];
}

- (id) subviewWithElementId:(NSString*)elementId {
    return [[InterfaCSS interfaCSS] subviewWithElementId:elementId inView:self];
}

@end
