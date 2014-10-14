//
//  InterfaCSS.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "InterfaCSS.h"

#import "ISSStyleSheetParser.h"
#import "ISSParcoaStyleSheetParser.h"
#import "ISSPropertyDeclaration.h"
#import "ISSViewPrototype.h"
#import "ISSUIElementDetails.h"
#import "ISSPropertyDeclarations.h"
#import "ISSSelectorChain.h"
#import "NSMutableArray+ISSAdditions.h"
#import "ISSPropertyRegistry.h"


static InterfaCSS* singleton = nil;

// Private extension of ISSUIElementDetails
@interface ISSUIElementDetailsInterfaCSS : ISSUIElementDetails
@property (nonatomic) BOOL beingStyled;
@end
@implementation ISSUIElementDetailsInterfaCSS
@end


// Private interface
@interface InterfaCSS ()

@property (nonatomic, strong) NSMutableArray* styleSheets;
@property (nonatomic, readonly) NSArray* effectiveStylesheets;

@property (nonatomic, strong) NSMutableDictionary* styleSheetsVariables;

@property (nonatomic, strong) NSMapTable* trackedElements; // Pointer address (NSValue) -> UI element (weak ref)
@property (nonatomic, strong) NSMutableDictionary* detailsForElements; // Pointer address (NSValue) -> ISSUIElementDetails

@property (nonatomic, strong) NSMapTable* cachedStyleDeclarationsForElements; // Canonical element styling identity (NSString) -> NSMutableArray

@property (nonatomic, strong) NSMutableDictionary* prototypes;

@property (nonatomic, weak) UIWindow* keyWindow;

@property (nonatomic, strong) NSTimer* timer;

@end


@implementation InterfaCSS {
    BOOL deviceIsRotating;
    BOOL cleanUpTrackedElementsScheduled;
}


#pragma mark - Creation & destruction

+ (void) initialize {
    if( !singleton ) {
        singleton = [[InterfaCSS alloc] initInternal];
    }
}

+ (InterfaCSS*) interfaCSS {
    return [self sharedInstance];
}

+ (InterfaCSS*) sharedInstance {
    return singleton;
}

+ (void) clearResetAndUnload {
    singleton.parser = nil;
    [singleton.styleSheets removeAllObjects];
    [singleton.styleSheetsVariables removeAllObjects];
    [singleton.detailsForElements removeAllObjects];
    [singleton.cachedStyleDeclarationsForElements removeAllObjects];
    [singleton.prototypes removeAllObjects];

    [singleton disableAutoRefreshTimer];
}

- (id) init {
    @throw([NSException exceptionWithName:NSInternalInconsistencyException reason:@"Hold on there professor, use +[InterfaCSS interfaCSS] instead!" userInfo:nil]);
}

- (id) initInternal {
    if( (self = [super init]) ) {
        _stylesheetAutoRefreshInterval = 5.0;
        _processRefreshableStylesheetsLast = YES;

        _propertyRegistry = [[ISSPropertyRegistry alloc] init];

        _styleSheets = [[NSMutableArray alloc] init];
        _styleSheetsVariables = [[NSMutableDictionary alloc] init];

        _trackedElements = [NSMapTable strongToWeakObjectsMapTable];
        _detailsForElements = [NSMutableDictionary dictionary];
        _cachedStyleDeclarationsForElements = [NSMapTable weakToStrongObjectsMapTable];
        _prototypes = [[NSMutableDictionary alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(memoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];

        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        
        [self performSelector:@selector(initViewHierarchy) withObject:nil afterDelay:0];
    }
    return self;
}

- (void) dealloc {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) memoryWarning:(NSNotification*)notification {
    [self clearAllCachedStyles];
    [self cleanUpTrackedElements];
}

- (void) cleanUpTrackedElements {
    cleanUpTrackedElementsScheduled = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];

    NSMutableSet* stillValid = [NSMutableSet set];

    for(NSString* key in self.trackedElements.keyEnumerator) {
        if( [self.trackedElements objectForKey:key] ) [stillValid addObject:key];
    }

    if( stillValid.count == self.detailsForElements.count ) return;

    for(NSString* key in self.detailsForElements.allKeys) {
        if( ![stillValid containsObject:key] ) {
            ISSLogTrace(@"Removing detailsForElements - %@", self.detailsForElements[key]);
            [self.detailsForElements removeObjectForKey:key];
            [self.trackedElements removeObjectForKey:key];
        }
    }
}

- (void) scheduleCleanUpTrackedElements {
    if( !cleanUpTrackedElementsScheduled ) {
        cleanUpTrackedElementsScheduled = YES;
        [self performSelector:@selector(cleanUpTrackedElements) withObject:nil afterDelay:1];
    }
}


#pragma mark - Device orientation

- (void) deviceOrientationChanged:(NSNotification*)notification {
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if( UIDeviceOrientationIsValidInterfaceOrientation(orientation) ) {
        ISSLogTrace(@"Triggering re-styling due to device orientation change");

        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetDeviceIsRotatingFlag) object:nil];
        deviceIsRotating = YES;
        [self performSelector:@selector(resetDeviceIsRotatingFlag) withObject:nil afterDelay:0.1];

        if( self.keyWindow ) [self scheduleApplyStyling:self.keyWindow animated:YES];
    }
}

- (void) resetDeviceIsRotatingFlag {
    deviceIsRotating = NO;
}


#pragma mark - Timer

- (void) enableAutoRefreshTimer {
    if( !_timer ) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:self.stylesheetAutoRefreshInterval target:self selector:@selector(autoRefreshTimerTick) userInfo:nil repeats:YES];
    }
}

- (void) disableAutoRefreshTimer {
    [_timer invalidate];
    _timer = nil;
}

- (void) autoRefreshTimerTick {
    for(ISSStyleSheet* styleSheet in self.styleSheets) {
        if( styleSheet.refreshable && styleSheet.active ) { // Attempt to get updated stylesheet
            [self updateRefreshableStyleSheet:styleSheet];
        }
    }
}


#pragma mark - Parsing Internals

- (id<ISSStyleSheetParser>) parser {
    if ( !_parser ) {
        _parser = [[ISSParcoaStyleSheetParser alloc] init];
    }
    return _parser;
}

- (ISSStyleSheet*) loadStyleSheetFromFileURL:(NSURL*)styleSheetFile {
    ISSStyleSheet* styleSheet = nil;

    for(ISSStyleSheet* existingStyleSheet in self.styleSheets) {
        if( [existingStyleSheet.styleSheetURL isEqual:styleSheetFile] ) {
            ISSLogDebug(@"Stylesheet %@ already loaded", styleSheetFile);
            return existingStyleSheet;
        }
    }
    
    NSError* error = nil;
    NSString* styleSheetData = [NSString stringWithContentsOfURL:styleSheetFile usedEncoding:nil error:&error];

    if( styleSheetData ) {
        NSTimeInterval t = [NSDate timeIntervalSinceReferenceDate];
        NSMutableArray* declarations = [self.parser parse:styleSheetData];
        ISSLogDebug(@"Loaded stylesheet '%@' in %g seconds", [styleSheetFile lastPathComponent], ([NSDate timeIntervalSinceReferenceDate] - t));

        if( declarations ) {
            styleSheet = [[ISSStyleSheet alloc] initWithStyleSheetURL:styleSheetFile declarations:declarations];
            [self.styleSheets addObject:styleSheet];

            [self refreshStyling];
        }
    } else {
        ISSLogWarning(@"Error loading stylesheet data from '%@' - %@", styleSheetFile, error);
    }

    return styleSheet;
}

- (void) updateRefreshableStyleSheet:(ISSStyleSheet*)styleSheet {
    [styleSheet refresh:^{
        [self refreshStyling];
    } parse:self.parser];
}


#pragma mark - Styling

- (BOOL) initViewHierarchy {
    self.keyWindow = [UIApplication sharedApplication].keyWindow;
    if( self.keyWindow ) {
        [self applyStyling:self.keyWindow];
        return YES;
    }
    return NO;
}

- (void) refreshStyling {
    [self clearAllCachedStyles];
    if( self.keyWindow ) [self applyStyling:self.keyWindow];
}

- (NSArray*) effectiveStylesForUIElement:(ISSUIElementDetails*)elementDetails force:(BOOL)force {
    // First - get cached declarations stored using weak reference on ISSUIElementDetails object
    NSMutableArray* cachedDeclarations = elementDetails.cachedDeclarations;

    // If not found - get cached declarations that matches element style identity (i.e. unique hierarchy/path of classes and style classes )
    // This makes it possible to reuse identical style information in sibling elements for instance.
    if( !cachedDeclarations ) {
        cachedDeclarations = [self.cachedStyleDeclarationsForElements objectForKey:elementDetails.elementStyleIdentity];
        elementDetails.cachedDeclarations = cachedDeclarations;
    }
    
    if ( !cachedDeclarations ) {
        ISSLogTrace(@"FULL stylesheet scan for '%@'", elementDetails.elementStyleIdentity);

        elementDetails.stylingApplied = NO; // Reset 'stylingApplied' flag if declaration cache has been clear, to make sure element is re-styled

        // Otherwise - build styles
        cachedDeclarations = [[NSMutableArray alloc] init];

        for (ISSStyleSheet* styleSheet in self.effectiveStylesheets) {
            // Find all matching (or potentially matching) style declarations
            NSArray* styleSheetDeclarations = [styleSheet declarationsMatchingElement:elementDetails ignoringPseudoClasses:YES];
            if ( styleSheetDeclarations ) {
                [cachedDeclarations addObjectsFromArray:styleSheetDeclarations];
            }
        }

        // Only add declarations to cache if styles are cacheable for element (i.e. added to the view hierarchy or using custom styling identity)
        if( elementDetails.stylesCacheable ) {
            [self.cachedStyleDeclarationsForElements setObject:cachedDeclarations forKey:elementDetails.elementStyleIdentity];
            elementDetails.cachedDeclarations = cachedDeclarations;
        } else {
            ISSLogTrace(@"Can NOT cache styles for '%@'", elementDetails.elementStyleIdentity);
        }
    } else {
        ISSLogTrace(@"Cached declarations exists for '%@'", elementDetails.elementStyleIdentity);
    }

    if( !force && elementDetails.stylingApplied ) {
        ISSLogTrace(@"Styles aleady applied for '%@'", elementDetails.elementStyleIdentity);
        return nil; // Current styling information has already been applied
    } else {
        ISSLogTrace(@"Processing style declarations for '%@'", elementDetails.elementStyleIdentity);

        // Process declarations to see which styles currently match
        BOOL hasPseudoClass = NO;
        NSMutableArray* viewStyles = [[NSMutableArray alloc] init];
        for (ISSPropertyDeclarations* declarations in cachedDeclarations) {
            // Add styles if declarations doesn't contain pseudo selector, or if matching against pseudo class selector is successful
            if ( !declarations.containsPseudoClassSelector || [declarations matchesElement:elementDetails ignoringPseudoClasses:NO] ) {
                [viewStyles iss_addAndReplaceUniqueObjectsInArray:declarations.properties];
            }

            hasPseudoClass = hasPseudoClass || declarations.containsPseudoClassSelector;
        }

        // Set 'stylingApplied' flag only if there are no pseudo classes in declarations, in which case declarations need to be evaluated every time
        if( !hasPseudoClass && elementDetails.stylesCacheable ) {
            elementDetails.stylingApplied = YES;
        } else {
            ISSLogTrace(@"Cannot mark element '%@' as styled", elementDetails.elementStyleIdentity);
        }

        return viewStyles;
    }
}

- (void) styleUIElement:(ISSUIElementDetails*)elementDetails force:(BOOL)force {
    NSArray* styles = [self effectiveStylesForUIElement:elementDetails force:force];

    if( styles ) { // If 'styles' is nil, current styling information has already been applied
        if ( elementDetails.willApplyStylingBlock ) {
            styles = elementDetails.willApplyStylingBlock(styles);
        }

        for (ISSPropertyDeclaration* propertyDeclaration in styles) {
            if( [elementDetails.disabledProperties containsObject:propertyDeclaration.property] ) {
                ISSLogTrace(@"Skipping setting of %@ - property disabled on %@", propertyDeclaration, elementDetails.uiElement);
            }
            else if ( ![propertyDeclaration applyPropertyValueOnTarget:elementDetails.uiElement] ) {
                ISSLogDebug(@"Unable to set value of %@ on %@", propertyDeclaration, elementDetails.uiElement);
            }
        }

        if ( elementDetails.didApplyStylingBlock ) {
            elementDetails.didApplyStylingBlock(styles);
        }
    }
}


#pragma mark - Styling

- (ISSUIElementDetails*) detailsForUIElement:(id)uiElement create:(BOOL)create {
    if( !uiElement ) return nil;

    NSValue* key = [NSValue valueWithPointer:(__bridge void*)uiElement];
    ISSUIElementDetails* details = self.detailsForElements[key];
    if( !details.uiElement ) details = nil; // UIElement has been dealloced and address reused - make sure we don't reuse this invalid ISSUIElementDetails object
    if( !details && create ) {
        details = [[ISSUIElementDetailsInterfaCSS alloc] initWithUIElement:uiElement];
        self.detailsForElements[key] = details;
        [self.trackedElements setObject:uiElement forKey:key];
    }

    // Clean up
    [self scheduleCleanUpTrackedElements];

    return details;
}

- (ISSUIElementDetails*) detailsForUIElement:(id)uiElement {
    return [self detailsForUIElement:uiElement create:YES];
}

- (void) clearCachedStylesForUIElement:(id)uiElement {
    ISSUIElementDetails* uiElementDetails = [self detailsForUIElement:uiElement create:NO];
    if( uiElementDetails ) {
        ISSLogTrace(@"Clearing cached styles for '%@'", uiElementDetails.elementStyleIdentity);

        [self.cachedStyleDeclarationsForElements removeObjectForKey:uiElementDetails.elementStyleIdentity];
        [uiElementDetails resetCachedData];
    }

    UIView* view = [uiElement isKindOfClass:[UIView class]] ? (UIView*)uiElement : nil;
    for(UIView* subView in view.subviews) {
        [self clearCachedStylesForUIElement:subView];
    }
}

- (void) clearAllCachedStyles {
    ISSLogTrace(@"Clearing all cached styles");
    [self.cachedStyleDeclarationsForElements removeAllObjects];
    for(ISSUIElementDetails* details in [self.detailsForElements objectEnumerator]) {
        [details resetCachedData];
    }
}

- (void) scheduleApplyStyling:(id)uiElement animated:(BOOL)animated {
    [self scheduleApplyStyling:uiElement animated:animated force:NO];
}

- (void) scheduleApplyStyling:(id)uiElement animated:(BOOL)animated force:(BOOL)force {
    if( !uiElement ) return;

    ISSUIElementDetails* uiElementDetails = [self detailsForUIElement:uiElement create:NO];
    if( uiElementDetails && uiElementDetails.stylingDisabled ) return;

    if( deviceIsRotating ) { // If device is rotating, we need to apply styles directly, to ensure they are performed within the animation used during the rotation
        [self applyStyling:uiElement includeSubViews:YES force:YES];
    } else if( animated && force ) {
        [[InterfaCSS interfaCSS] performSelector:@selector(applyStylingWithAnimationAndForce:) withObject:uiElement afterDelay:0];
    } else if( animated ) {
        [[InterfaCSS interfaCSS] performSelector:@selector(applyStylingWithAnimation:) withObject:uiElement afterDelay:0];
    } else if( force ) {
        [[InterfaCSS interfaCSS] performSelector:@selector(applyStylingWithForce:) withObject:uiElement afterDelay:0];
    } else {
        [[InterfaCSS interfaCSS] performSelector:@selector(applyStyling:) withObject:uiElement afterDelay:0];
    }
}

- (void) cancelScheduledApplyStyling:(id)uiElement {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(applyStyling:) object:uiElement];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(applyStylingWithAnimation:) object:uiElement];
}

- (void) applyStylingWithForce:(id)uiElement {
    [self applyStyling:uiElement includeSubViews:YES force:YES];
}

- (void) applyStyling:(id)uiElement {
    [self applyStyling:uiElement includeSubViews:YES];
}

- (void) applyStyling:(id)uiElement includeSubViews:(BOOL)includeSubViews {
    [self applyStyling:uiElement includeSubViews:includeSubViews force:NO];
}

// Main styling method
- (void) applyStyling:(id)uiElement includeSubViews:(BOOL)includeSubViews force:(BOOL)force {
    if( !uiElement ) return;

    ISSUIElementDetailsInterfaCSS* uiElementDetails = (ISSUIElementDetailsInterfaCSS*)[self detailsForUIElement:uiElement];

    if( !uiElementDetails.beingStyled ) { // Prevent recursive styling calls for uiElement during styling
        @try {
            uiElementDetails.beingStyled = YES;
            [self applyStylingInternal:uiElementDetails includeSubViews:includeSubViews force:force];
        }
        @finally {
            uiElementDetails.beingStyled = NO;
            // Cancel scheduled calls after styling has been applied, to avoid "loop"
            [self cancelScheduledApplyStyling:uiElement];
        }
    }
}

// Internal styling method - should only be called by -[applyStyling:includeSubViews:].
- (void) applyStylingInternal:(ISSUIElementDetails*)uiElementDetails includeSubViews:(BOOL)includeSubViews force:(BOOL)force {
    UIView* view = uiElementDetails.view;
    BOOL styleAppliedToView = NO;
    if( !self.keyWindow && includeSubViews ) {
        [self initViewHierarchy];
        styleAppliedToView = uiElementDetails.stylingApplied; // If styling was applied by initViewHierarchy, we don't need to do it again
    }
    if( !styleAppliedToView ) {
        ISSLogTrace(@"Applying style to %@", uiElementDetails.uiElement);

        // Reset cached styles if superview has changed (but not if using custom styling identity)
        if( view && view.superview != uiElementDetails.parentView && !uiElementDetails.usingCustomElementStyleIdentity ) {
            ISSLogTrace(@"Superview of %@ has changed - resetting cached styles", view);
            [self clearCachedStylesForUIElement:view];
            uiElementDetails.parentView = view.superview;
        }

        // If styling is disabled for element - abort styling of whole sub tre
        if( uiElementDetails.stylingDisabled ) {
            ISSLogTrace(@"Styling disabled for %@", uiElementDetails.view);
            return;
        }

        [self styleUIElement:uiElementDetails force:force];

        if( includeSubViews ) {
            NSArray* subviews = view.subviews ?: [[NSArray alloc] init];
            UIView* parentView = nil;
            // Special case: UIToolbar - add toolbar items to "subview" list
            if( [view isKindOfClass:UIToolbar.class] ) {
                UIToolbar* toolbar = (UIToolbar*)view;
                parentView = toolbar;
                if( toolbar.items ) subviews = [subviews arrayByAddingObjectsFromArray:toolbar.items];
            }
            // Special case: UINavigationBar - add nav bar items to "subview" list
            else if( [view isKindOfClass:UINavigationBar.class] ) {
                UINavigationBar* navigationBar = (UINavigationBar*)view;
                parentView = navigationBar;

                NSMutableArray* additionalSubViews = [NSMutableArray array];
                for(id item in navigationBar.items) {
                    if( [item isKindOfClass:UINavigationItem.class] ) {
                        UINavigationItem* navigationItem = (UINavigationItem*)item;
                        if( navigationItem.backBarButtonItem ) [additionalSubViews addObject:navigationItem.backBarButtonItem];
                        if( navigationItem.leftBarButtonItems.count ) [additionalSubViews addObjectsFromArray:navigationItem.leftBarButtonItems];
                        if( navigationItem.titleView ) [additionalSubViews addObject:navigationItem.titleView];
                        if( navigationItem.rightBarButtonItems.count ) [additionalSubViews addObjectsFromArray:navigationItem.rightBarButtonItems];
                    } else {
                        [additionalSubViews addObject:item];
                    }
                }
                subviews = [subviews arrayByAddingObjectsFromArray:additionalSubViews];
            }
            // Special case: UITabBar - add tab bar items to "subview" list
            else if( [view isKindOfClass:UITabBar.class] ) {
                UITabBar* tabBar = (UITabBar*)view;
                parentView = tabBar;
                if( tabBar.items ) subviews = [subviews arrayByAddingObjectsFromArray:tabBar.items];
            }

            // Process subviews
            for(id subView in subviews) {
                ISSUIElementDetails* subViewDetails = [self detailsForUIElement:subView];

                // If subview isn't view (i.e. UIToolbarItem for instance) - set parent view as super view in ViewProperties
                if( parentView && ![subView isKindOfClass:UIView.class] ) {
                    if( !subViewDetails.parentView ) subViewDetails.parentView = parentView;
                }

                [self applyStyling:subView includeSubViews:YES force:force];
            }
        }
    }
}

- (void) applyStylingWithAnimationAndForce:(id)uiElement {
    [self applyStylingWithAnimation:uiElement includeSubViews:YES force:YES];
}

- (void) applyStylingWithAnimation:(id)uiElement {
    [self applyStylingWithAnimation:uiElement includeSubViews:YES];
}

- (void) applyStylingWithAnimation:(id)uiElement includeSubViews:(BOOL)includeSubViews {
    [self applyStylingWithAnimation:uiElement includeSubViews:includeSubViews force:NO];
}

- (void) applyStylingWithAnimation:(id)uiElement includeSubViews:(BOOL)includeSubViews force:(BOOL)force {
    // Cancel scheduled styling calls for uiElement
    [self cancelScheduledApplyStyling:uiElement];

    [UIView animateWithDuration:0.33 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionLayoutSubviews animations:^() {
        [self applyStyling:uiElement includeSubViews:includeSubViews force:force];
    } completion:nil];
}


#pragma mark - Style classes

- (NSSet*) styleClassesForUIElement:(id)uiElement {
    return [self detailsForUIElement:uiElement].styleClasses;
}

- (void) setStyleClasses:(NSSet*)styleClasses forUIElement:(id)uiElement {
    ISSUIElementDetails* uiElementDetails = [self detailsForUIElement:uiElement];
    if( styleClasses.count ) {
        NSMutableSet* lcStyleClasses = [[NSMutableSet alloc] init];
        for(NSString* styleClass in styleClasses) [lcStyleClasses addObject:[styleClass lowercaseString]];
        uiElementDetails.styleClasses = lcStyleClasses;
    } else {
        uiElementDetails.styleClasses = nil;
    }

    [self clearCachedStylesForUIElement:uiElement];
}

- (BOOL) uiElement:(id)uiElement hasStyleClass:(NSString*)styleClass {
    return [[self styleClassesForUIElement:uiElement] containsObject:[styleClass lowercaseString]];
}

- (void) addStyleClass:(NSString*)styleClass forUIElement:(id)uiElement {
    styleClass = [styleClass lowercaseString];
    ISSUIElementDetails* uiElementDetails = [self detailsForUIElement:uiElement];
    
    NSSet* newClasses = [NSSet setWithObject:styleClass];
    NSSet* existingClasses = uiElementDetails.styleClasses;
    if( existingClasses ) newClasses = [newClasses setByAddingObjectsFromSet:existingClasses];
    uiElementDetails.styleClasses = newClasses;

    [self clearCachedStylesForUIElement:uiElement];
}

- (void) removeStyleClass:(NSString*)styleClass forUIElement:(id)uiElement {
    styleClass = [styleClass lowercaseString];
    ISSUIElementDetails* uiElementDetails = [self detailsForUIElement:uiElement];

    NSSet* existingClasses = uiElementDetails.styleClasses;
    if( existingClasses ) {
        NSPredicate* predicate = [NSPredicate predicateWithBlock:^(id o, NSDictionary *b) {
            return (BOOL)![styleClass isEqual:o];
        }];
        uiElementDetails.styleClasses = [existingClasses filteredSetUsingPredicate:predicate];
    }

    [self clearCachedStylesForUIElement:uiElement];
}


#pragma mark - Additional styling control

- (void) setWillApplyStylingBlock:(ISSWillApplyStylingNotificationBlock)willApplyStylingBlock forUIElement:(id)uiElement {
    [self detailsForUIElement:uiElement].willApplyStylingBlock = willApplyStylingBlock;
}

- (ISSWillApplyStylingNotificationBlock) willApplyStylingBlockForUIElement:(id)uiElement {
    return [self detailsForUIElement:uiElement].willApplyStylingBlock;
}

- (void) setDidApplyStylingBlock:(ISSDidApplyStylingNotificationBlock)didApplyStylingBlock forUIElement:(id)uiElement {
    [self detailsForUIElement:uiElement].didApplyStylingBlock = didApplyStylingBlock;
}

- (ISSDidApplyStylingNotificationBlock) didApplyStylingBlockForUIElement:(id)uiElement {
    return [self detailsForUIElement:uiElement].didApplyStylingBlock;
}

- (void) setCustomStylingIdentity:(NSString*)customStylingIdentity forUIElement:(id)uiElement {
    [self clearCachedStylesForUIElement:uiElement];
    [[self detailsForUIElement:uiElement] setCustomElementStyleIdentity:customStylingIdentity];
}

- (NSString*) customStylingIdentityForUIElement:(id)uiElement {
    return [self detailsForUIElement:uiElement].elementStyleIdentity;
}

- (void) setStylingEnabled:(BOOL)enabled forUIElement:(id)uiElement {
    ISSUIElementDetails* uiElementDetails = [self detailsForUIElement:uiElement];
    uiElementDetails.stylingDisabled = !enabled;
    if( enabled ) [self scheduleApplyStyling:uiElement animated:NO];
}

- (BOOL) isStylingEnabledForUIElement:(id)uiElement {
    return ![self detailsForUIElement:uiElement].stylingDisabled;
}

- (void) setStylingEnabled:(BOOL)enabled forProperty:(NSString*)propertyName inUIElement:(id)uiElement {
    ISSUIElementDetails* uiElementDetails = [self detailsForUIElement:uiElement];
    ISSPropertyDefinition* property = [self.propertyRegistry propertyDefinitionForProperty:propertyName inClass:[uiElement class]];
    if( enabled ) [uiElementDetails removeDisabledProperty:property];
    else [uiElementDetails addDisabledProperty:property];
}

- (BOOL) isStylingEnabledForProperty:(NSString*)propertyName inUIElement:(id)uiElement {
    ISSUIElementDetails* uiElementDetails = [self detailsForUIElement:uiElement];
    ISSPropertyDefinition* property = [self.propertyRegistry propertyDefinitionForProperty:propertyName inClass:[uiElement class]];
    return ![uiElementDetails hasDisabledProperty:property];
}


#pragma mark - Prototypes

- (void) registerPrototype:(ISSViewPrototype*)prototype {
    if( prototype.name ) self.prototypes[prototype.name] = prototype;
    else ISSLogWarning(@"Attempted to register prototype without name!");
}

- (UIView*) viewFromPrototypeWithName:(NSString*)prototypeName {
    return [self.prototypes[prototypeName] createViewObjectFromPrototype:nil];
}


#pragma mark - Stylesheets

- (ISSStyleSheet*) loadStyleSheetFromMainBundleFile:(NSString*)styleSheetFileName {
    NSURL* url = [[NSBundle mainBundle] URLForResource:styleSheetFileName withExtension:nil];
    if( url ) {
        return [self loadStyleSheetFromFileURL:url];
    } else {
        ISSLogWarning(@"Unable to load stylesheet '%@' - file not found in main bundle!", styleSheetFileName);
        return nil;
    }
}

- (ISSStyleSheet*) loadStyleSheetFromFile:(NSString*)styleSheetFilePath {
    if( [[NSFileManager defaultManager] fileExistsAtPath:styleSheetFilePath] ) {
        return [self loadStyleSheetFromFileURL:[NSURL fileURLWithPath:styleSheetFilePath]];
    } else {
        ISSLogWarning(@"Unable to load stylesheet '%@' - file not found!", styleSheetFilePath);
        return nil;
    }
}

- (ISSStyleSheet*) loadRefreshableStyleSheetFromURL:(NSURL*)styleSheetURL {
    ISSStyleSheet* styleSheet = [[ISSStyleSheet alloc] initWithStyleSheetURL:styleSheetURL declarations:nil refreshable:YES];
    [self.styleSheets addObject:styleSheet];
    [self updateRefreshableStyleSheet:styleSheet];
    [self enableAutoRefreshTimer];
    return styleSheet;
}

- (void) unloadStyleSheet:(ISSStyleSheet*)styleSheet refreshStyling:(BOOL)refreshStyling {
    [self.styleSheets removeObject:styleSheet];
    if( refreshStyling ) [self refreshStyling];
    else [self clearAllCachedStyles];
}

- (void) unloadAllStyleSheets:(BOOL)refreshStyling {
    [self.styleSheets removeAllObjects];
    if( refreshStyling ) [self refreshStyling];
    else [self clearAllCachedStyles];
}

- (NSArray*) effectiveStylesheets {
    NSMutableArray* effective = [NSMutableArray array];
    NSMutableArray* refreshable = [NSMutableArray array];

    for(ISSStyleSheet* styleSheet in self.styleSheets) {
        if( styleSheet.active ) {
            if( styleSheet.refreshable && self.processRefreshableStylesheetsLast ) {
                [refreshable addObject:styleSheet];
            } else {
                [effective addObject:styleSheet];
            }
        }
    }

    if( self.processRefreshableStylesheetsLast ) {
        [effective addObjectsFromArray:refreshable];
    }

    return effective;
}


#pragma mark - Variables

- (NSString*) valueOfStyleSheetVariableWithName:(NSString*)variableName {
    return self.styleSheetsVariables[variableName];
}

- (id) transformedValueOfStyleSheetVariableWithName:(NSString*)variableName asPropertyType:(ISSPropertyType)propertyType {
    NSString* value = self.styleSheetsVariables[variableName];
    if( value ) return [self.parser transformValue:value asPropertyType:propertyType];
    else return nil;
}

- (id) transformedValueOfStyleSheetVariableWithName:(NSString*)variableName forPropertyDefinition:(ISSPropertyDefinition*)propertyDefinition {
    NSString* value = self.styleSheetsVariables[variableName];
    if( value ) return [self.parser transformValue:value forPropertyDefinition:propertyDefinition];
    else return nil;
}

- (void) setValue:(NSString*)value forStyleSheetVariableWithName:(NSString*)variableName {
    self.styleSheetsVariables[variableName] = value;
}


#pragma mark - Debugging support

- (void) logMatchingStyleDeclarationsForUIElement:(id)uiElement {
    ISSUIElementDetails* elementDetails = [self detailsForUIElement:uiElement];
    NSString* objectIdentity = [NSString stringWithFormat:@"<%@: %p>", [uiElement class], (__bridge void*)uiElement];

    NSMutableSet* existingSelectorChains = [[NSMutableSet alloc] init];
    BOOL match = NO;
    for (ISSStyleSheet* styleSheet in self.effectiveStylesheets) {
        NSMutableArray* matchingDeclarations = [[styleSheet declarationsMatchingElement:elementDetails ignoringPseudoClasses:NO] mutableCopy];
        if( matchingDeclarations.count ) {
            [matchingDeclarations enumerateObjectsUsingBlock:^(id declarationObj, NSUInteger idx1, BOOL *stop1) {
                NSMutableArray* chainsCopy = [((ISSPropertyDeclarations*)declarationObj).selectorChains mutableCopy];
                [chainsCopy enumerateObjectsUsingBlock:^(id chainObj, NSUInteger idx2, BOOL *stop2) {
                    if( [existingSelectorChains containsObject:chainObj] ) chainsCopy[idx2] =  [NSString stringWithFormat:@"%@ (WARNING - DUPLICATE)", [chainObj displayDescription]];
                    else chainsCopy[idx2] = [chainObj displayDescription];
                    [existingSelectorChains addObject:chainObj];
                }];

                matchingDeclarations[idx1] = [NSString stringWithFormat:@"%@ {...}", [chainsCopy componentsJoinedByString:@", "]];
            }];
            
            NSLog(@"Declarations in '%@' matching %@: [\n\t%@\n]", styleSheet.styleSheetURL.lastPathComponent, objectIdentity, [matchingDeclarations componentsJoinedByString:@", \n\t"]);
            match = YES;
        }
    }
    if( !match ) NSLog(@"No declarations match %@", objectIdentity);
}

@end
