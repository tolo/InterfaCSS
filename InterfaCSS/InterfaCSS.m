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
#import "ISSRuntimeIntrospectionUtils.h"
#import "ISSStylingContext.h"


typedef id (^ISSViewHierarchyVisitorBlock)(id viewObject, ISSUIElementDetails* elementDetails, BOOL* stop);


static InterfaCSS* singleton = nil;

// Private extension of ISSUIElementDetails
@interface ISSUIElementDetailsInterfaCSS : ISSUIElementDetails
@property (nonatomic) BOOL beingStyled;
@property (nonatomic) BOOL stylingScheduled;
@end
@implementation ISSUIElementDetailsInterfaCSS
@end


// Private interface
@interface InterfaCSS ()

@property (nonatomic, strong) NSMutableArray* styleSheets;
@property (nonatomic, readonly) NSArray* effectiveStylesheets;

@property (nonatomic, strong) NSMutableDictionary* styleSheetsVariables;

@property (nonatomic, strong) NSMapTable* cachedStyleDeclarationsForElements; // Weak canonical element styling identity (NSString) -> NSMutableArray

@property (nonatomic, strong) NSMutableDictionary* prototypes;

@property (nonatomic, strong) NSMapTable* initializedWindows;

@property (nonatomic, strong) NSTimer* timer;

@end


@implementation InterfaCSS {
    BOOL deviceIsRotating;
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

static void setupForInitialState(InterfaCSS* interfaCSS) {
    interfaCSS->_preventOverwriteOfAttributedTextAttributes = NO;
    interfaCSS->_useLenientSelectorParsing = NO;
    interfaCSS->_stylesheetAutoRefreshInterval = 5.0;
    interfaCSS->_processRefreshableStylesheetsLast = YES;
    interfaCSS->_allowAutomaticRegistrationOfCustomTypeSelectorClasses = YES;
    interfaCSS->_useSelectorSpecificity = NO;

    interfaCSS->_parser = nil;

    interfaCSS->_propertyRegistry = [[ISSPropertyRegistry alloc] init];

    interfaCSS->_styleSheets = [[NSMutableArray alloc] init];
    interfaCSS->_styleSheetsVariables = [[NSMutableDictionary alloc] init];

    interfaCSS->_cachedStyleDeclarationsForElements = [NSMapTable weakToStrongObjectsMapTable];
    interfaCSS->_prototypes = [[NSMutableDictionary alloc] init];

    interfaCSS->_initializedWindows = [NSMapTable weakToStrongObjectsMapTable];
}

+ (void) clearResetAndUnload {
    [singleton clearAllCachedStyles];
    
    [singleton disableAutoRefreshTimer];
    
    setupForInitialState(singleton);
}

- (id) init {
    @throw([NSException exceptionWithName:NSInternalInconsistencyException reason:@"Hold on there professor, use +[InterfaCSS interfaCSS] instead!" userInfo:nil]);
}

- (id) initInternal {
    if( (self = [super init]) ) {
        setupForInitialState(self);

        NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(memoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#if TARGET_OS_TV == 0
        [notificationCenter addObserver:self selector:@selector(deviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
#endif
        [notificationCenter addObserver:self selector:@selector(windowDidBecomeVisible:) name:UIWindowDidBecomeKeyNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(windowDidBecomeVisible:) name:UIWindowDidBecomeVisibleNotification object:nil];
    }
    return self;
}

- (void) dealloc {
#if TARGET_OS_TV == 0
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
#endif
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) memoryWarning:(NSNotification*)notification {
    [self clearAllCachedStyles];
}


#pragma mark - Properties

- (void) setStylesheetAutoRefreshInterval:(NSTimeInterval)stylesheetAutoRefreshInterval {
    _stylesheetAutoRefreshInterval = stylesheetAutoRefreshInterval;
    if( _timer ) {
        [self disableAutoRefreshTimer];
        [self enableAutoRefreshTimer];
    }
}


#pragma mark - Device orientation

#if TARGET_OS_TV == 0
- (void) deviceOrientationChanged:(NSNotification*)notification {
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if( UIDeviceOrientationIsValidInterfaceOrientation(orientation) ) {
        ISSLogTrace(@"Triggering re-styling due to device orientation change");

        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetDeviceIsRotatingFlag) object:nil];
        deviceIsRotating = YES;
        [self performSelector:@selector(resetDeviceIsRotatingFlag) withObject:nil afterDelay:0.1];

        for(UIWindow* window in self.initializedWindows.keyEnumerator) {
            [self scheduleApplyStyling:window animated:YES];
        }
    }
}
#endif

- (void) resetDeviceIsRotatingFlag {
    deviceIsRotating = NO;
}


#pragma mark - Window appearance notification

- (void) windowDidBecomeVisible:(NSNotification*)notification {
    [self initViewHierarchyForWindow:notification.object];
}


#pragma mark - Timer

- (void) enableAutoRefreshTimer {
    if( !_timer && self.stylesheetAutoRefreshInterval > 0 ) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:self.stylesheetAutoRefreshInterval target:self selector:@selector(autoRefreshTimerTick) userInfo:nil repeats:YES];
    }
}

- (void) disableAutoRefreshTimer {
    [_timer invalidate];
    _timer = nil;
}

- (void) autoRefreshTimerTick {
    [self reloadRefreshableStyleSheets:NO];
}


#pragma mark - Parsing Internals

- (id<ISSStyleSheetParser>) parser {
    if ( !_parser ) {
        _parser = [[ISSParcoaStyleSheetParser alloc] init];
    }
    return _parser;
}

- (ISSStyleSheet*) loadStyleSheetFromFileURL:(NSURL*)styleSheetFile withScope:(ISSStyleSheetScope*)scope {
    ISSStyleSheet* styleSheet = nil;

    for(ISSStyleSheet* existingStyleSheet in self.styleSheets) {
        if( [existingStyleSheet.styleSheetURL isEqual:styleSheetFile] ) {
            ISSLogDebug(@"Stylesheet %@ already loaded", styleSheetFile);
            if( scope ) existingStyleSheet.scope = scope;
            return existingStyleSheet;
        }
    }
    
    NSError* error = nil;
    NSString* styleSheetData = [NSString stringWithContentsOfURL:styleSheetFile usedEncoding:nil error:&error];

    if( styleSheetData ) {
        NSTimeInterval t = [NSDate timeIntervalSinceReferenceDate];
        NSMutableArray* declarations = [self.parser parse:styleSheetData];
        ISSLogDebug(@"Loaded stylesheet '%@' in %f seconds", [styleSheetFile lastPathComponent], ([NSDate timeIntervalSinceReferenceDate] - t));

        if( declarations ) {
            styleSheet = [[ISSStyleSheet alloc] initWithStyleSheetURL:styleSheetFile declarations:declarations refreshable:NO scope:scope];
            [self.styleSheets addObject:styleSheet];

            [self refreshStylingForStyleSheet:styleSheet];
        }
    } else {
        ISSLogWarning(@"Error loading stylesheet data from '%@' - %@", styleSheetFile, error);
    }

    return styleSheet;
}


#pragma mark - Styling - Style matching and application

- (NSArray*) effectiveStylesForUIElement:(ISSUIElementDetails*)elementDetails force:(BOOL)force {
    // First - get cached declarations stored using weak reference on ISSUIElementDetails object
    NSMutableArray* cachedDeclarations = elementDetails.cachedDeclarations;

    // If not found - get cached declarations that matches element style identity (i.e. unique hierarchy/path of classes and style classes)
    // This makes it possible to reuse identical style information in sibling elements for instance.
    if( !cachedDeclarations ) {
        cachedDeclarations = [self.cachedStyleDeclarationsForElements objectForKey:elementDetails.elementStyleIdentityPath];
        elementDetails.cachedDeclarations = cachedDeclarations;
    }
    
    if ( !cachedDeclarations ) {
        ISSLogTrace(@"FULL stylesheet scan for '%@'", elementDetails.elementStyleIdentityPath);

        elementDetails.stylingApplied = NO; // Reset 'stylingApplied' flag if declaration cache has been cleared, to make sure element is re-styled

        // Otherwise - build styles
        cachedDeclarations = [[NSMutableArray alloc] init];
        
        // Perform full stylesheet scan to get matching style classes, but ignore pseudo classes at this stage
        ISSStylingContext* stylingContext = [ISSStylingContext contextIgnoringPseudoClasses];
        for (ISSStyleSheet* styleSheet in self.effectiveStylesheets) {
            // Find all matching (or potentially matching, i.e. pseudo class) style declarations
            NSArray* styleSheetDeclarations = [styleSheet declarationsMatchingElement:elementDetails stylingContext:stylingContext];
            if ( styleSheetDeclarations ) {
                [cachedDeclarations addObjectsFromArray:styleSheetDeclarations];
            }
        }
        
        if( stylingContext.containsPartiallyMatchedDeclarations ) ISSLogTrace(@"Found %d matching declarations, and at least one partially matching declaration, for '%@'.", cachedDeclarations.count, elementDetails.elementStyleIdentityPath);
        else ISSLogTrace(@"Found %d matching declarations for '%@'", cachedDeclarations.count, elementDetails.elementStyleIdentityPath);
        
        // If selector specificity is enabled...
        if( self.useSelectorSpecificity ) {
            // ...sort declarations on specificity
            [cachedDeclarations sortWithOptions:NSSortStable usingComparator:^NSComparisonResult(ISSPropertyDeclarations* ruleset1, ISSPropertyDeclarations* ruleset2) {
                if ( ruleset1.specificity > ruleset2.specificity ) return NSOrderedDescending;
                if ( ruleset1.specificity < ruleset2.specificity ) return NSOrderedAscending;
                return NSOrderedSame;
            }];
        }
        
        // If there are no style declarations that only partially matches the element - consider the styles fully resolved for the element
        elementDetails.stylesFullyResolved = !stylingContext.containsPartiallyMatchedDeclarations;
        
        // Only add declarations to cache if styles are cacheable for element (i.e. either added to window, or part of a view hierachy that has an root element with an element Id), or,
        // if there were no styles that would match if the element was placed under a different parent (i.e. partial matches)
        if( elementDetails.stylesCacheable || elementDetails.stylesFullyResolved ) {
            [self.cachedStyleDeclarationsForElements setObject:cachedDeclarations forKey:elementDetails.elementStyleIdentityPath];
            elementDetails.cachedDeclarations = cachedDeclarations;
        } else {
            ISSLogTrace(@"Can NOT cache styles for '%@'", elementDetails.elementStyleIdentityPath);
        }
    } else {
        ISSLogTrace(@"Cached declarations exists for '%@'", elementDetails.elementStyleIdentityPath);
    }

    if( !force && elementDetails.stylingAppliedAndStatic ) { // Current styling information has already been applied, and declarations contain no pseudo classes
        ISSLogTrace(@"Styles aleady applied for '%@'", elementDetails.elementStyleIdentityPath);
        return nil;
    } else { // Styling information has not been applied, or declarations contains pseudo classes (in which case we need to re-evaluate the styles every time styling is initiated), or is forced
        ISSLogTrace(@"Processing style declarations for '%@'", elementDetails.elementStyleIdentityPath);
        
        // Process declarations to see which styles currently match
        BOOL hasPseudoClassOrDynamicProperty = NO;
        ISSStylingContext* stylingContext = [[ISSStylingContext alloc] init];
        NSMutableArray* viewStyles = [[NSMutableArray alloc] init];
        for (ISSPropertyDeclarations* declarations in cachedDeclarations) {
            // Add styles if declarations doesn't contain pseudo selector, or if matching against pseudo class selector is successful
            if ( !declarations.containsPseudoClassSelector || [declarations matchesElement:elementDetails stylingContext:stylingContext] ) {
                [viewStyles iss_addAndReplaceUniqueObjectsInArray:declarations.properties];
            }

            hasPseudoClassOrDynamicProperty = hasPseudoClassOrDynamicProperty || declarations.containsPseudoClassSelectorOrDynamicProperties;
        }
        elementDetails.stylesContainPseudoClassesOrDynamicProperties = hasPseudoClassOrDynamicProperty; // Record in elementDetails if declarations contain pseudo classes or dynamic properties

        // Set 'stylingApplied' flag to indicate that styles have been fully applied, but only if element is part of a defined view
        // hierarchy (i.e. either added to window, or part of a view hierachy that has an root element with an element Id)
        if( elementDetails.stylesCacheable || elementDetails.stylesFullyResolved ) {
            elementDetails.stylingApplied = YES;
        } else {
            ISSLogTrace(@"Cannot mark element '%@' as styled", elementDetails.elementStyleIdentityPath);
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
            } else {
                [propertyDeclaration applyPropertyValueOnTarget:elementDetails];
            }
        }

        if ( elementDetails.didApplyStylingBlock ) {
            elementDetails.didApplyStylingBlock(styles);
        }
    }
}


#pragma mark - Styling - Elememt details

- (ISSUIElementDetailsInterfaCSS*) detailsForUIElement:(id)uiElement create:(BOOL)create {
    if( !uiElement ) return nil;

    ISSUIElementDetailsInterfaCSS* details = (ISSUIElementDetailsInterfaCSS*)[uiElement elementDetailsISS];
    if( !details && create ) {
        details = [[ISSUIElementDetailsInterfaCSS alloc] initWithUIElement:uiElement];
        [uiElement setElementDetailsISS:details];
    }

    return details;
}

- (ISSUIElementDetails*) detailsForUIElement:(id)uiElement {
    return [self detailsForUIElement:uiElement create:YES];
}


#pragma mark - Styling - Caching

- (void) clearCachedStylesForUIElement:(id)uiElement {
    [self clearCachedStylesForUIElement:uiElement includeSubViews:YES];
}

- (void) clearCachedStylesForUIElement:(id)uiElement includeSubViews:(BOOL)includeSubViews {
    ISSUIElementDetails* uiElementDetails = [self detailsForUIElement:uiElement create:NO];
    [self clearCachedInformationForUIElementDetails:uiElementDetails includeSubViews:includeSubViews clearCachedStylesOnlyIfNeeded:NO];
}

- (void) clearCachedStylesIfNeededForUIElement:(id)uiElement includeSubViews:(BOOL)includeSubViews {
    ISSUIElementDetails* uiElementDetails = [self detailsForUIElement:uiElement create:NO];
    [self clearCachedInformationForUIElementDetails:uiElementDetails includeSubViews:includeSubViews clearCachedStylesOnlyIfNeeded:YES];
}

- (void) clearCachedStylesForUIElementDetails:(ISSUIElementDetails*)uiElementDetails {
    [self clearCachedInformationForUIElementDetails:uiElementDetails includeSubViews:YES clearCachedStylesOnlyIfNeeded:NO];
}

- (void) clearCachedInformationForUIElementDetails:(ISSUIElementDetails*)uiElementDetails includeSubViews:(BOOL)includeSubViews clearCachedStylesOnlyIfNeeded:(BOOL)clearCachedStylesOnlyIfNeeded {
    if( !uiElementDetails ) return;

    // If styles information for element is fully resolved, and if clearCachedStylesOnlyIfNeeded is YES - skip reset of cached styles, and...
    if( clearCachedStylesOnlyIfNeeded && !uiElementDetails.stylesFullyResolved ) {
        ISSLogTrace(@"Partially clearing cached information for '%@'", uiElementDetails);
        [uiElementDetails resetCachedViewHierarchyRelatedData]; // ...only reset information directly related to the position of the element in the view hierarchy
    } else {
        ISSLogTrace(@"Clearing cached styles for '%@'", uiElementDetails);
        [self.cachedStyleDeclarationsForElements removeObjectForKey:uiElementDetails.elementStyleIdentityPath];
        [uiElementDetails resetCachedData];
    }

    if( includeSubViews ) {
        NSArray* subViews = uiElementDetails.childElementsForElement;
        for (UIView* subView in subViews) {
            ISSUIElementDetails* subViewDetails = [self detailsForUIElement:subView create:NO];
            [self clearCachedInformationForUIElementDetails:subViewDetails includeSubViews:includeSubViews clearCachedStylesOnlyIfNeeded:clearCachedStylesOnlyIfNeeded];
        }
    }
}

- (void) clearAllCachedStyles {
    if( self.cachedStyleDeclarationsForElements.count ) {
        ISSLogTrace(@"Clearing all cached styles");
        [self.cachedStyleDeclarationsForElements removeAllObjects];

        [ISSUIElementDetails resetAllCachedData];
    }
}


#pragma mark - Styling - High level style application methods

- (void) initViewHierarchyForView:(UIView*)view {
    UIWindow* window = view.window;
    if( window ) [self initViewHierarchyForWindow:window];
}

- (void) initViewHierarchyForWindow:(UIWindow*)window {
    if( window && ![self.initializedWindows objectForKey:window] ) {
        [self.initializedWindows setObject:@(YES) forKey:window];
        [self scheduleApplyStyling:window animated:NO]; // Delay styling a bit, since deviceOrientationChanged will probably be called directly after this
    }
}

- (BOOL) elementHasScheduledStyling:(id)element {
    while( element ) {
        ISSUIElementDetailsInterfaCSS* details = (ISSUIElementDetailsInterfaCSS*)[self detailsForUIElement:element];
        if( details.stylingScheduled ) return YES;
        else element = details.parentElement;
    }
    return NO;
}

- (void) scheduleApplyStyling:(id)uiElement animated:(BOOL)animated {
    [self scheduleApplyStyling:uiElement animated:animated force:NO];
}

- (void) scheduleApplyStylingIfNeeded:(id)uiElement animated:(BOOL)animated force:(BOOL)force {
    ISSUIElementDetailsInterfaCSS* details = (ISSUIElementDetailsInterfaCSS*)[self detailsForUIElement:uiElement];
    
    if( ![self elementHasScheduledStyling:details.parentElement] ) {
        [self scheduleApplyStyling:uiElement animated:animated force:force];
    }
}

- (void) scheduleApplyStyling:(id)uiElement animated:(BOOL)animated force:(BOOL)force {
    if( !uiElement ) return;
    
    ISSUIElementDetailsInterfaCSS* uiElementDetails = (ISSUIElementDetailsInterfaCSS*)[self detailsForUIElement:uiElement]; // Create details if not found, to ensure stylingScheduled is set correctly
    if( uiElementDetails.stylingAppliedAndDisabled || uiElementDetails.stylingScheduled ) return;
    
    if( deviceIsRotating ) { // If device is rotating, we need to apply styles directly, to ensure they are performed within the animation used during the rotation
        [self applyStyling:uiElement includeSubViews:YES];
    } else {
        uiElementDetails.stylingScheduled = YES; // Flag reset in [applyStyling:includeSubViews:force:]

        if ( animated && force ) {
            [[InterfaCSS interfaCSS] performSelector:@selector(applyStylingWithAnimationAndForce:) withObject:uiElement afterDelay:0];
        } else if ( animated ) {
            [[InterfaCSS interfaCSS] performSelector:@selector(applyStylingWithAnimation:) withObject:uiElement afterDelay:0];
        } else if ( force ) {
            [[InterfaCSS interfaCSS] performSelector:@selector(applyStylingWithForce:) withObject:uiElement afterDelay:0];
        } else {
            [[InterfaCSS interfaCSS] performSelector:@selector(applyStyling:) withObject:uiElement afterDelay:0];
        }
    }
}

- (void) cancelScheduledApplyStyling:(id)uiElement {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(applyStyling:) object:uiElement];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(applyStylingWithForce:) object:uiElement];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(applyStylingWithAnimation:) object:uiElement];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(applyStylingWithAnimationAndForce:) object:uiElement];
}

- (void) applyStylingWithForce:(id)uiElement {
    [self applyStyling:uiElement includeSubViews:YES force:YES];
}

- (void) applyStylingIfScheduled:(id)uiElement {
    if( !uiElement ) return;
    
    ISSUIElementDetailsInterfaCSS* uiElementDetails = (ISSUIElementDetailsInterfaCSS*)[self detailsForUIElement:uiElement];
    if( [self elementHasScheduledStyling:uiElementDetails.parentElement] ) {
        return; // Parent has scheduled styling
    }
    
    if( uiElementDetails.stylingScheduled ) {
        [self applyStylingWithDetails:uiElementDetails includeSubViews:YES force:NO];
    }
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
    [self applyStylingWithDetails:uiElementDetails includeSubViews:includeSubViews force:force];
}

// Main styling method (element details version)
- (void) applyStylingWithDetails:(ISSUIElementDetailsInterfaCSS*)uiElementDetails includeSubViews:(BOOL)includeSubViews force:(BOOL)force {
    if( !uiElementDetails ) return;
    
    // If styling is disabled for element (but has been displayed once) - abort styling of whole sub tre
    if( uiElementDetails.stylingAppliedAndDisabled ) {
        ISSLogTrace(@"Styling disabled for %@", uiElementDetails.view);
        return;
    }

    if( !uiElementDetails.beingStyled ) { // Prevent recursive styling calls for uiElement during styling
        @try {
            uiElementDetails.beingStyled = YES;
            [self applyStylingInternal:uiElementDetails includeSubViews:includeSubViews force:force];
        }
        @finally {
            uiElementDetails.beingStyled = NO;
            // Cancel scheduled calls after styling has been applied, to avoid "loop"
            if( uiElementDetails.stylingScheduled ) {
                [self cancelScheduledApplyStyling:uiElementDetails.uiElement];
                uiElementDetails.stylingScheduled = NO;
            }
        }
    }
}

// Internal styling method ("inner") - should only be called by -[doApplyStylingInternal:includeSubViews:force:].
- (void) applyStylingInternal:(ISSUIElementDetails*)uiElementDetails includeSubViews:(BOOL)includeSubViews force:(BOOL)force {
    ISSLogTrace(@"Applying style to %@", uiElementDetails.uiElement);

    // Reset cached styles if superview has changed (but not if using custom styling identity)
    UIView* view = uiElementDetails.view;
    if( view && view.superview != uiElementDetails.parentView ) {
        ISSLogTrace(@"Superview of %@ has changed - resetting cached view hierarchy related information", view);
        // Clear cached styles - but only if needed (i.e. not already fully resolved)
        [self clearCachedInformationForUIElementDetails:uiElementDetails includeSubViews:YES clearCachedStylesOnlyIfNeeded:YES];
        uiElementDetails.parentElement = nil; // Reset parent element to make sure it's re-evaluated
    }

    [self styleUIElement:uiElementDetails force:force];

    if( includeSubViews ) {
        NSArray* subViews = uiElementDetails.childElementsForElement;

        // Process subviews
        for(id subView in subViews) {
            ISSUIElementDetails* subViewDetails = [self detailsForUIElement:subView];

            // Make sure parent element reference is correctly set
            if( !subViewDetails.parentElement ) subViewDetails.parentElement = uiElementDetails.uiElement;

            [self applyStylingWithDetails:(ISSUIElementDetailsInterfaCSS*)subViewDetails includeSubViews:YES force:force];
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

    [self clearCachedStylesForUIElementDetails:uiElementDetails];
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

    [self clearCachedStylesForUIElementDetails:uiElementDetails];
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

    [self clearCachedStylesForUIElementDetails:uiElementDetails];
}


#pragma mark - Element ID

- (void) setElementId:(NSString*)elementId forUIElement:(id)uiElement {
    ISSUIElementDetails* uiElementDetails = [self detailsForUIElement:uiElement];
    [self clearCachedStylesForUIElementDetails:uiElementDetails];
    uiElementDetails.elementId = elementId;
}

- (NSString*) elementIdForUIElement:(id)uiElement {
    return [self detailsForUIElement:uiElement].elementId;
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
    ISSUIElementDetails* uiElementDetails = [self detailsForUIElement:uiElement];
    [self clearCachedStylesForUIElementDetails:uiElementDetails];
    uiElementDetails.customElementStyleIdentity = customStylingIdentity;
}

- (NSString*) customStylingIdentityForUIElement:(id)uiElement {
    return [self detailsForUIElement:uiElement].customElementStyleIdentity;
}

- (void) setStylingEnabled:(BOOL)enabled forUIElement:(id)uiElement {
    ISSUIElementDetails* uiElementDetails = [self detailsForUIElement:uiElement];
    uiElementDetails.stylingDisabled = !enabled;
    if( enabled ) [self scheduleApplyStyling:uiElement animated:NO];
}

- (BOOL) isStylingEnabledForUIElement:(id)uiElement {
    return ![self detailsForUIElement:uiElement].stylingDisabled;
}

- (BOOL) isStylingAppliedForUIElement:(id)uiElement {
    return ![self detailsForUIElement:uiElement].stylingApplied;
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

- (id) visitViewHierarchyFromView:(id)view visitorBlock:(ISSViewHierarchyVisitorBlock)visitorBlock {
    BOOL stop = NO;
    return [self visitViewHierarchyFromView:view visitorBlock:visitorBlock stop:&stop];
}

- (id) visitViewHierarchyFromView:(id)view visitorBlock:(ISSViewHierarchyVisitorBlock)visitorBlock stop:(BOOL*)stop {
    ISSUIElementDetails* details = [self detailsForUIElement:view create:NO];
    id result = visitorBlock(view, details, stop);
    if( *stop ) return result;

    // Drill down
    for(UIView* subview in details.childElementsForElement) {
        result = [self visitViewHierarchyFromView:subview visitorBlock:visitorBlock stop:stop];
        if( *stop ) return result;
    }
    return nil;
}

- (id) visitReversedViewHierarchyFromView:(id)view visitorBlock:(ISSViewHierarchyVisitorBlock)visitorBlock {
    BOOL stop = NO;
    return [self visitReversedViewHierarchyFromView:view visitorBlock:visitorBlock stop:&stop];
}

- (id) visitReversedViewHierarchyFromView:(id)view visitorBlock:(ISSViewHierarchyVisitorBlock)visitorBlock stop:(BOOL*)stop {
    if( view == nil ) return nil;
    
    ISSUIElementDetails* details = [self detailsForUIElement:view create:NO];

    id result = visitorBlock(view, details, stop);
    if( *stop ) return result;

    // Move up
    return [self visitReversedViewHierarchyFromView:details.parentElement visitorBlock:visitorBlock stop:stop];
}

- (id) subviewWithElementId:(NSString*)elementId inView:(id)view {
    return [self visitViewHierarchyFromView:view visitorBlock:^id(id viewObject, ISSUIElementDetails* elementDetails, BOOL* stop) {
        if( viewObject != view && [elementDetails.elementId isEqualToString:elementId] ) {
            *stop = YES;
            return viewObject;
        }
        return nil;
    }];
}

- (id) superviewWithElementId:(NSString*)elementId inView:(id)view {
    return [self visitReversedViewHierarchyFromView:view visitorBlock:^id(id viewObject, ISSUIElementDetails* elementDetails, BOOL* stop) {
        if( viewObject != view && [elementDetails.elementId isEqualToString:elementId] ) {
            *stop = YES;
            return viewObject;
        }
        return nil;
    }];
}

- (void) autoPopulatePropertiesInViewHierarchyFromView:(UIView*)view inOwner:(id)owner {
    [self visitViewHierarchyFromView:view visitorBlock:^id(id viewObject, ISSUIElementDetails* elementDetails, BOOL* stop) {
        if( elementDetails.elementId && [ISSRuntimeIntrospectionUtils doesClass:[owner class] havePropertyWithName:elementDetails.elementId] ) {
            // If element has elementId and if owner has matching property - set it using KVC
            [owner setValue:viewObject forKey:elementDetails.elementId];
        }
        return nil;
    }];
}


#pragma mark - Prototypes

- (void) registerPrototype:(ISSViewPrototype*)prototype {
    [self registerPrototype:prototype prototypeStore:self.prototypes];
}

- (void) registerPrototype:(ISSViewPrototype*)prototype inElement:(id)registeredInElement {
    ISSUIElementDetails* uiElementDetails = [self detailsForUIElement:registeredInElement];
    [self registerPrototype:prototype prototypeStore:uiElementDetails.prototypes];
}

- (void) registerPrototype:(ISSViewPrototype*)prototype prototypeStore:(NSMutableDictionary*)prototypeStore {
    if( prototypeStore[prototype.name] ) {
        ISSLogWarning(@"Attempting to register a prototype with a name that already exists - previous prototype will be overwritten!");
    }

    if( prototype.name ) {
        prototypeStore[prototype.name] = prototype;
    } else {
        ISSLogWarning(@"Attempted to register prototype without name!");
    }
}

- (UIView*) viewFromPrototypeWithName:(NSString*)prototypeName {
    return [self viewFromPrototypeWithName:prototypeName registeredInElement:nil prototypeParent:nil];
}

- (UIView*) viewFromPrototypeWithName:(NSString*)prototypeName prototypeParent:(id)prototypeParent {
    return [self viewFromPrototypeWithName:prototypeName registeredInElement:prototypeParent prototypeParent:prototypeParent];
}

- (UIView*) viewFromPrototypeWithName:(NSString*)prototypeName registeredInElement:(id)registeredInElement prototypeParent:(id)prototypeParent {
    ISSViewPrototype* prototype = nil;
    if( registeredInElement ) {
        ISSUIElementDetails* uiElementDetails = [self detailsForUIElement:registeredInElement];
        prototype = uiElementDetails.prototypes[prototypeName];
    }
    if( !prototype ) prototype = self.prototypes[prototypeName];

    if( prototype ) {
        return [prototype createViewObjectFromPrototypeWithParent:prototypeParent];
    } else {
        ISSLogWarning(@"Prototype with name '%@' not found!", prototypeName);
        return nil;
    }
}


#pragma mark - Stylesheets

- (ISSUIElementDetails*) firstChildElementMatchingScope:(ISSStyleSheetScope*)scope inElement:(ISSUIElementDetails*)elementDetails {
    if( [scope elementInScope:elementDetails] ) return elementDetails;
    
    NSArray* subViews = elementDetails.childElementsForElement;
    for (UIView* subView in subViews) {
        ISSUIElementDetails* v = [self firstChildElementMatchingScope:scope inElement:[self detailsForUIElement:subView]];
        if( v ) return v;
    }
    return nil;
}

- (ISSUIElementDetails*) firstElementMatchingScope:(ISSStyleSheetScope*)scope {
    for(UIWindow* window in self.initializedWindows.keyEnumerator) {
        ISSUIElementDetails* v = [self firstChildElementMatchingScope:scope inElement:[self detailsForUIElement:window]];
        if( v ) return v;
    }
    return nil;
}

- (ISSStyleSheet*) loadStyleSheetFromMainBundleFile:(NSString*)styleSheetFileName {
    return [self loadStyleSheetFromMainBundleFile:styleSheetFileName withScope:nil];
}

- (ISSStyleSheet*) loadStyleSheetFromMainBundleFile:(NSString*)styleSheetFileName withScope:(ISSStyleSheetScope*)scope {
    NSURL* url = [[NSBundle mainBundle] URLForResource:styleSheetFileName withExtension:nil];
    if( url ) {
        return [self loadStyleSheetFromFileURL:url withScope:scope];
    } else {
        ISSLogWarning(@"Unable to load stylesheet '%@' - file not found in main bundle!", styleSheetFileName);
        return nil;
    }
}

- (ISSStyleSheet*) loadStyleSheetFromFile:(NSString*)styleSheetFilePath {
    return [self loadStyleSheetFromFile:styleSheetFilePath withScope:nil];
}

- (ISSStyleSheet*) loadStyleSheetFromFile:(NSString*)styleSheetFilePath withScope:(ISSStyleSheetScope*)scope {
    if( [[NSFileManager defaultManager] fileExistsAtPath:styleSheetFilePath] ) {
        return [self loadStyleSheetFromFileURL:[NSURL fileURLWithPath:styleSheetFilePath] withScope:scope];
    } else {
        ISSLogWarning(@"Unable to load stylesheet '%@' - file not found!", styleSheetFilePath);
        return nil;
    }
}

- (ISSStyleSheet*) loadRefreshableStyleSheetFromURL:(NSURL*)styleSheetURL {
    return [self loadRefreshableStyleSheetFromURL:styleSheetURL withScope:nil];
}

- (ISSStyleSheet*) loadRefreshableStyleSheetFromURL:(NSURL*)styleSheetURL withScope:(ISSStyleSheetScope*)scope {
    ISSStyleSheet* styleSheet = [[ISSStyleSheet alloc] initWithStyleSheetURL:styleSheetURL declarations:nil refreshable:YES scope:scope];
    [self.styleSheets addObject:styleSheet];
    [self reloadRefreshableStyleSheet:styleSheet force:NO];
    
    BOOL usingFileMonitoring = NO;
    if( styleSheetURL.isFileURL ) { // If local file URL - attempt to use file monitoring instead of polling
        __weak InterfaCSS* weakSelf = self;
        [styleSheet startMonitoringLocalFileChanges:^(ISSRefreshableResource* refreshed) {
            [weakSelf reloadRefreshableStyleSheet:styleSheet force:YES];
        }];
        usingFileMonitoring = styleSheet.usingLocalFileChangeMonitoring;
    }
    
    if( !usingFileMonitoring ) {
        [self enableAutoRefreshTimer];
    }
    
    return styleSheet;
}

- (ISSStyleSheet*) loadRefreshableStyleSheetFromLocalFile:(NSString*)styleSheetFilePath {
    return [self loadRefreshableStyleSheetFromURL:[NSURL fileURLWithPath:styleSheetFilePath]];
}

- (ISSStyleSheet*) loadRefreshableStyleSheetFromLocalFile:(NSString*)styleSheetFilePath withScope:(ISSStyleSheetScope*)scope {
    return [self loadRefreshableStyleSheetFromURL:[NSURL fileURLWithPath:styleSheetFilePath] withScope:scope];
}

- (void) reloadRefreshableStyleSheets:(BOOL)force {
    for(ISSStyleSheet* styleSheet in self.styleSheets) {
        if( styleSheet.refreshable && styleSheet.active && !styleSheet.usingLocalFileChangeMonitoring ) { // Attempt to get updated stylesheet
            [self reloadRefreshableStyleSheet:styleSheet force:force];
        }
    }
}

- (void) reloadRefreshableStyleSheet:(ISSStyleSheet*)styleSheet force:(BOOL)force {
    [styleSheet refreshStylesheetWithCompletionHandler:^{
        [self refreshStylingForStyleSheet:styleSheet];
    } force:force];
}

- (void) unloadStyleSheet:(ISSStyleSheet*)styleSheet refreshStyling:(BOOL)refreshStyling {
    [self.styleSheets removeObject:styleSheet];
    if( refreshStyling ) [self refreshStylingForStyleSheet:styleSheet];
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

- (void) refreshStyling {
    [self clearAllCachedStyles];
    for(UIWindow* window in self.initializedWindows.keyEnumerator) {
        [self applyStyling:window];
    }
}

- (void) refreshStylingForStyleSheet:(ISSStyleSheet*)styleSheet {
    if( styleSheet.scope ) [self refreshStylingForScope:styleSheet.scope];
    else [self refreshStyling];
}

- (void) refreshStylingForScope:(ISSStyleSheetScope*)scope {
    ISSUIElementDetails* firstElementMatchingScope = [self firstElementMatchingScope:scope];
    if( firstElementMatchingScope ) {
        [self clearCachedStylesForUIElement:firstElementMatchingScope];
        [self applyStylingWithDetails:(ISSUIElementDetailsInterfaCSS*)firstElementMatchingScope includeSubViews:YES force:NO];
    }
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
    ISSStylingContext* stylingContext = [[ISSStylingContext alloc] init];
    for (ISSStyleSheet* styleSheet in self.effectiveStylesheets) {
        NSMutableArray* matchingDeclarations = [[styleSheet declarationsMatchingElement:elementDetails stylingContext:stylingContext] mutableCopy];
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
